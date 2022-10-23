# syntax=docker/dockerfile:1

ARG GO_VERSION="1.19"
ARG GORELEASER_XX_VERSION="1.2.5"

ARG TEST_ALPINE_VARIANT=3.16
ARG TEST_DEBIAN_VARIANT=bullseye

FROM --platform=$BUILDPLATFORM crazymax/goreleaser-xx:${GORELEASER_XX_VERSION} AS goreleaser-xx
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS base
ENV CGO_ENABLED=0
COPY --from=goreleaser-xx / /
RUN apk add --no-cache git
WORKDIR /src

FROM base AS vendored
RUN --mount=type=bind,source=.,target=/src,rw \
  --mount=type=cache,target=/go/pkg/mod \
  go mod tidy && go mod download

FROM vendored AS build
ARG TARGETPLATFORM
RUN --mount=type=bind,target=/src,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goreleaser-xx --debug \
    --name "yasu" \
    --dist "/out" \
    --flags="-trimpath" \
    --ldflags="-s -w -X 'main.Version={{.Version}}'" \
    --files="CHANGELOG.md" \
    --files="LICENSE" \
    --files="README.md"

FROM scratch AS artifacts
COPY --from=build /out/*.tar.gz /
COPY --from=build /out/*.zip /

FROM scratch AS binary
COPY --from=build /usr/local/bin/yasu /

FROM alpine:${TEST_ALPINE_VARIANT} AS test-alpine
COPY --from=build /usr/local/bin/yasu /usr/local/bin/yasu
RUN cut -d: -f1 /etc/group | xargs -n1 addgroup nobody
RUN chgrp nobody /usr/local/bin/yasu && chmod +s /usr/local/bin/yasu
USER nobody
ENV HOME /omg/really/yasu/nowhere
# now we should be nobody, ALL groups, and have a bogus useless HOME value
WORKDIR /src
RUN --mount=type=bind,target=/src \
  ./hack/test.sh

FROM debian:${TEST_DEBIAN_VARIANT}-slim AS test-debian
COPY --from=build /usr/local/bin/yasu /usr/local/bin/yasu
RUN cut -d: -f1 /etc/group | xargs -n1 -I'{}' usermod -aG '{}' nobody
# emulate Alpine's "games" user (which is part of the "users" group)
RUN usermod -aG users games
RUN chgrp nogroup /usr/local/bin/yasu && chmod +s /usr/local/bin/yasu
USER nobody
ENV HOME /omg/really/yasu/nowhere
# now we should be nobody, ALL groups, and have a bogus useless HOME value
WORKDIR /src
RUN --mount=type=bind,target=/src \
  ./hack/test.sh

FROM scratch
COPY --from=build /usr/local/bin/yasu /usr/local/bin/yasu
