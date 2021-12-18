# syntax=docker/dockerfile:1.3
ARG GO_VERSION

FROM --platform=$BUILDPLATFORM crazymax/goreleaser-xx:latest AS goreleaser-xx
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS base
RUN apk add --no-cache git
COPY --from=goreleaser-xx / /
WORKDIR /src

FROM base AS build
ARG TARGETPLATFORM
ARG GIT_REF
RUN --mount=type=bind,target=/src,rw \
  --mount=type=cache,target=/root/.cache/go-build \
  --mount=target=/go/pkg/mod,type=cache \
  goreleaser-xx --debug \
    --name "yasu" \
    --dist "/out" \
    --hooks="go mod tidy" \
    --hooks="go mod download" \
    --ldflags="-s -w -X 'main.Version={{.Version}}'" \
    --files="CHANGELOG.md" \
    --files="LICENSE" \
    --files="README.md"

FROM scratch AS artifacts
COPY --from=build /out/*.tar.gz /
COPY --from=build /out/*.zip /

FROM alpine:3.15 AS test-alpine
COPY --from=build /usr/local/bin/yasu /usr/local/bin/yasu
RUN cut -d: -f1 /etc/group | xargs -n1 addgroup nobody
RUN chgrp nobody /usr/local/bin/yasu && chmod +s /usr/local/bin/yasu
USER nobody
ENV HOME /omg/really/yasu/nowhere
# now we should be nobody, ALL groups, and have a bogus useless HOME value
WORKDIR /src
RUN --mount=type=bind,target=/src \
  ./hack/test.sh

FROM debian:buster-slim AS test-debian
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
