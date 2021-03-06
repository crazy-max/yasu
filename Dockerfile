# syntax=docker/dockerfile:1.2
ARG GO_VERSION=1.14

FROM --platform=$BUILDPLATFORM crazymax/goreleaser-xx:latest AS goreleaser-xx
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS base
COPY --from=goreleaser-xx / /
RUN apk add --no-cache ca-certificates curl file gcc git linux-headers musl-dev tar
WORKDIR /src

FROM base AS gomod
RUN --mount=type=bind,target=.,rw \
  --mount=type=cache,target=/go/pkg/mod \
  go mod tidy && go mod download

FROM gomod AS build
ARG TARGETPLATFORM
ARG GIT_REF
RUN --mount=type=bind,target=/src,rw \
  --mount=type=cache,target=/root/.cache/go-build \
  --mount=target=/go/pkg/mod,type=cache \
  goreleaser-xx --debug \
    --name "yasu" \
    --dist "/out" \
    --files "CHANGELOG,README.md,LICENSE"

FROM scratch AS artifacts
COPY --from=build /out/*.tar.gz /
COPY --from=build /out/*.zip /

FROM alpine AS test-alpine
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
