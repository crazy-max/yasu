# syntax=docker/dockerfile:1

ARG GO_VERSION="1.21"
ARG ALPINE_VERSION="3.18"
ARG XX_VERSION="1.3.0"

ARG TEST_ALPINE_VARIANT="3.16"
ARG TEST_DEBIAN_VARIANT="bullseye"

FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS base
COPY --from=xx / /
ENV CGO_ENABLED=0
RUN apk add --no-cache file git
WORKDIR /src

FROM base AS version
ARG GIT_REF
RUN --mount=target=. <<EOT
  set -e
  case "$GIT_REF" in
    refs/tags/v*) version="${GIT_REF#refs/tags/}" ;;
    *) version=$(git describe --match 'v[0-9]*' --dirty='.m' --always --tags) ;;
  esac
  echo "$version" | tee /tmp/.version
EOT

FROM base AS vendored
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
  go mod download

FROM vendored AS build
ARG TARGETPLATFORM
RUN --mount=type=bind,target=. \
    --mount=type=bind,from=version,source=/tmp/.version,target=/tmp/.version \
    --mount=type=cache,target=/root/.cache \
    --mount=type=cache,target=/go/pkg/mod <<EOT
  set -ex
  xx-go build -trimpath -ldflags "-s -w -X main.version=$(cat /tmp/.version)" -o /usr/bin/yasu .
  xx-verify --static /usr/bin/yasu
EOT

FROM scratch AS binary
COPY --link --from=build /usr/bin/yasu /
# enable scanning for this stage
ARG BUILDKIT_SBOM_SCAN_STAGE=true

FROM scratch AS artifacts
FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS releaser
RUN apk add --no-cache bash coreutils
WORKDIR /out
RUN --mount=from=artifacts,source=.,target=/artifacts <<EOT
  set -e
  cp /artifacts/**/* /out/ 2>/dev/null || cp /artifacts/* /out/
  sha256sum -b yasu_* > ./checksums.txt
  sha256sum -c --strict checksums.txt
EOT

FROM scratch AS release
COPY --link --from=releaser /out /

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS build-artifact
RUN apk add --no-cache bash tar
WORKDIR /work
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
RUN --mount=type=bind,target=/src \
    --mount=type=bind,from=binary,target=/build \
    --mount=type=bind,from=version,source=/tmp/.version,target=/tmp/.version <<EOT
  set -ex
  mkdir /out
  version=$(cat /tmp/.version)
  cp /build/* /src/CHANGELOG.md /src/LICENSE /src/README.md .
  tar -czvf "/out/yasu_${version#v}_${TARGETOS}_${TARGETARCH}${TARGETVARIANT}.tar.gz" .
EOT

FROM scratch AS artifact
COPY --link --from=build-artifact /out /

FROM alpine:${TEST_ALPINE_VARIANT} AS test-alpine
COPY --from=build /usr/bin/yasu /usr/local/bin/yasu
RUN cut -d: -f1 /etc/group | xargs -n1 addgroup nobody
RUN chgrp nobody /usr/local/bin/yasu && chmod +s /usr/local/bin/yasu
ENV GOSU_PLEASE_LET_ME_BE_COMPLETELY_INSECURE_I_GET_TO_KEEP_ALL_THE_PIECES="I've seen things you people wouldn't believe. Attack ships on fire off the shoulder of Orion. I watched C-beams glitter in the dark near the Tannhäuser Gate. All those moments will be lost in time, like tears in rain. Time to die."
USER nobody
ENV HOME /omg/really/yasu/nowhere
# now we should be nobody, ALL groups, and have a bogus useless HOME value
WORKDIR /src
RUN --mount=type=bind,target=/src \
  ./hack/test.sh

FROM debian:${TEST_DEBIAN_VARIANT}-slim AS test-debian
COPY --from=build /usr/bin/yasu /usr/local/bin/yasu
RUN cut -d: -f1 /etc/group | xargs -n1 -I'{}' usermod -aG '{}' nobody
# emulate Alpine's "games" user (which is part of the "users" group)
RUN usermod -aG users games
RUN chgrp nogroup /usr/local/bin/yasu && chmod +s /usr/local/bin/yasu
ENV GOSU_PLEASE_LET_ME_BE_COMPLETELY_INSECURE_I_GET_TO_KEEP_ALL_THE_PIECES="I've seen things you people wouldn't believe. Attack ships on fire off the shoulder of Orion. I watched C-beams glitter in the dark near the Tannhäuser Gate. All those moments will be lost in time, like tears in rain. Time to die."
USER nobody
ENV HOME /omg/really/yasu/nowhere
# now we should be nobody, ALL groups, and have a bogus useless HOME value
WORKDIR /src
RUN --mount=type=bind,target=/src \
  ./hack/test.sh

FROM scratch
COPY --link --from=build /usr/bin/yasu /usr/local/bin/yasu
