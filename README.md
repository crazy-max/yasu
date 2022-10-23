[![GitHub release](https://img.shields.io/github/release/crazy-max/yasu.svg?style=flat-square)](https://github.com/crazy-max/yasu/releases/latest)
[![Total downloads](https://img.shields.io/github/downloads/crazy-max/yasu/total.svg?style=flat-square)](https://github.com/crazy-max/yasu/releases/latest)
[![Build Status](https://img.shields.io/github/workflow/status/crazy-max/yasu/build?label=build&logo=github&style=flat-square)](https://github.com/crazy-max/yasu/actions?query=workflow%3Abuild)
[![Docker Stars](https://img.shields.io/docker/stars/crazymax/yasu.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/crazymax/yasu/)
[![Docker Pulls](https://img.shields.io/docker/pulls/crazymax/yasu.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/crazymax/yasu/)
[![Go Report Card](https://goreportcard.com/badge/github.com/crazy-max/yasu)](https://goreportcard.com/report/github.com/crazy-max/yasu)

___

* [Yet Another?](#yet-another)
* [About](#about)
  * [Warning](#warning)
* [Usage](#usage)
  * [From binary](#from-binary)
  * [From Dockerfile](#from-dockerfile)
* [Build](#build)
* [Why?](#why)
* [Alternatives](#alternatives)
  * [`su-exec`](#su-exec)
  * [`chroot`](#chroot)
  * [`setpriv`](#setpriv)
  * [Others](#others)
* [Contributing](#contributing)
* [License](#license)

## Yet Another?

This repository is a fork of [tianon/gosu](https://github.com/tianon/gosu) and renamed to avoid confusion as asked by
the main maintainer. See [tianon/gosu#82 (comment)](https://github.com/tianon/gosu/pull/82#issuecomment-790874961).

`yasu` because it's _Yet Another Switch User_. The main purpose of this fork is to handle a functional
multi-platform scratch Docker image to ease the [integration in a Dockerfile](#from-dockerfile). Everything is
dockerized and handled by [buildx bake](#build) for an agnostic usage of this repo. Finally, GitHub Actions has been
added to avoid tampered artifacts and more transparency around [releases](https://github.com/crazy-max/yasu/releases).

More info: [tianon/gosu#82](https://github.com/tianon/gosu/pull/82)

## About

This is a simple tool grown out of the simple fact that `su` and `sudo` have very strange and often annoying TTY and
signal-forwarding behavior. They're also somewhat complex to setup and use (especially in the case of `sudo`), which
allows for a great deal of expressivity, but falls flat if all you need is "run this specific application as this
specific user and get out of the pipeline".

The core of how `yasu` works is stolen directly from how Docker/libcontainer itself starts an application inside a
container (and in fact, is using the `/etc/passwd` processing code directly from libcontainer's codebase).

```shell
$ yasu
Usage: ./yasu user-spec command [args]
   eg: ./yasu tianon bash
       ./yasu nobody:root bash -c 'whoami && id'
       ./yasu 1000:1 id

./yasu version: 1.1 (go1.3.1 on linux/amd64; gc)
```

Once the user/group is processed, we switch to that user, then we `exec` the specified process and `yasu` itself is no
longer resident or involved in the process lifecycle at all.  This avoids all the issues of signal passing and TTY,
and punts them to the process invoking `yasu` and the process being invoked by `yasu`, where they belong.

### Warning

The core use case for `yasu` is to step _down_ from `root` to a non-privileged user during container startup
(specifically in the `ENTRYPOINT`, usually).

Uses of `yasu` beyond that could very well suffer from vulnerabilities such as CVE-2016-2779 (from which the Docker
use case naturally shields us); see [`tianon/gosu#37`](https://github.com/tianon/gosu/issues/37) for some discussion
around this point.

## Usage

### From binary

`yasu` binaries are available on [releases page](https://github.com/crazy-max/yasu/releases/latest).

Choose the archive matching the destination platform:

```shell
wget -qO- https://github.com/crazy-max/yasu/releases/download/v1.13.0/yasu_1.13.0_linux_x86_64.tar.gz | tar -zxvf - yasu
yasu --version
yasu nobody true
```

### From Dockerfile

| Registry                                                                                         | Image                           |
|--------------------------------------------------------------------------------------------------|---------------------------------|
| [Docker Hub](https://hub.docker.com/r/crazymax/yasu/)                                            | `crazymax/yasu`                 |
| [GitHub Container Registry](https://github.com/users/crazy-max/packages/container/package/yasu)  | `ghcr.io/crazy-max/yasu`        |

Following platforms for this image are available:

```
$ docker run --rm mplatform/mquery crazymax/yasu:latest
Image: crazymax/yasu:latest
 * Manifest List: Yes
 * Supported platforms:
   - linux/386
   - linux/amd64
   - linux/arm/v5
   - linux/arm/v6
   - linux/arm/v7
   - linux/arm64
   - linux/mips64le
   - linux/ppc64le
   - linux/riscv64
   - linux/s390x
```

Here is how to use `yasu` inside your Dockerfile:

```Dockerfile
FROM crazymax/yasu:latest AS yasu
FROM alpine
COPY --from=yasu / /
RUN yasu --version
RUN yasu nobody true
```

## Build

```shell
git clone https://github.com/crazy-max/yasu.git yasu
cd yasu

# validate (lint, vendors)
docker buildx bake validate

# test (test-alpine and test-debian bake targets)
docker buildx bake test

# build docker image and output to docker with yasu:local tag (default)
docker buildx bake

# build multi-platform image
docker buildx bake image-all

# build artifacts and output to ./bin/artifact
docker buildx bake artifact-all
```

## Why?

```shell
$ docker run -it --rm ubuntu:trusty su -c 'exec ps aux'
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0  46636  2688 ?        Ss+  02:22   0:00 su -c exec ps a
root         6  0.0  0.0  15576  2220 ?        Rs   02:22   0:00 ps aux
$ docker run -it --rm ubuntu:trusty sudo ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  3.0  0.0  46020  3144 ?        Ss+  02:22   0:00 sudo ps aux
root         7  0.0  0.0  15576  2172 ?        R+   02:22   0:00 ps aux
$ docker run -it --rm -v $PWD/yasu-amd64:/usr/local/bin/yasu:ro ubuntu:trusty yasu root ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   7140   768 ?        Rs+  02:22   0:00 ps aux
```

Additionally, due to the fact that `yasu` is using Docker's own code for processing these `user:group`, it has
exact 1:1 parity with Docker's own `--user` flag.

If you're curious about the edge cases that `yasu` handles, see [`hack/test.sh`](hack/test.sh) for the "test suite".

(Note that `sudo` has different goals from this project, and it is *not* intended to be a `sudo` replacement;
for example, see [this Stack Overflow answer](https://stackoverflow.com/a/48105623) for a short explanation of
why `sudo` does `fork`+`exec` instead of just `exec`.)

## Alternatives

### `su-exec`

As mentioned in `INSTALL.md`, [`su-exec`](https://github.com/ncopa/su-exec) is a very minimal re-write of `yasu` in C,
making for a much smaller binary, and is available in the `main` Alpine package repository.

### `chroot`

With the `--userspec` flag, `chroot` can provide similar benefits/behavior:

```shell
$ docker run -it --rm ubuntu:trusty chroot --userspec=nobody / ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
nobody       1  5.0  0.0   7136   756 ?        Rs+  17:04   0:00 ps aux
```

### `setpriv`

Available in newer `util-linux` (`>= 2.32.1-0.2`, in Debian; https://manpages.debian.org/buster/util-linux/setpriv.1.en.html):

```shell
$ docker run -it --rm buildpack-deps:buster-scm setpriv --reuid=nobody --regid=nogroup --init-groups ps faux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
nobody       1  5.0  0.0   9592  1252 pts/0    RNs+ 23:21   0:00 ps faux
```

### Others

I'm not terribly familiar with them, but a few other alternatives I'm aware of include:

* `chpst` (part of `runit`)

## Contributing

Want to contribute? Awesome! The most basic way to show your support is to star the project, or to raise issues. If
you want to open a pull request, please read the [contributing guidelines](.github/CONTRIBUTING.md).

You can also support this project by [**becoming a sponsor on GitHub**](https://github.com/sponsors/crazy-max) or by
making a [Paypal donation](https://www.paypal.me/crazyws) to ensure this journey continues indefinitely!

Thanks again for your support, it is much appreciated! :pray:

## License

GPL-3.0. See `LICENSE` for more details.
