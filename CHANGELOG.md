# Changelog

## 1.14.1 (2021/03/06)

* Switch to `goreleaser-xx` (#2)
* Add `arm/v5` platform

## 1.14.0 (2021/03/04)

* Rename project `yasu`. Asked by `gosu` maintainer to avoid confusion. See [tianon/gosu#82 (comment)](https://github.com/tianon/gosu/pull/82#issuecomment-790874961)

## 1.13.2 (2021/03/03)

* Bump github.com/opencontainers/runc from 1.0.0-rc92 to 1.0.0-rc93 (#1)
* Fix module name

## 1.13.1 (2021/03/02)

* Missing platform for Docker image

## 1.13.0 (2021/03/02)

* **Fork [tianon/gosu](https://github.com/tianon/gosu/issues/69)**
* Use [buildx bake](https://github.com/docker/buildx) and [goreleaser](https://goreleaser.com/)
* More platforms support
  * `arm/v7`
  * `mips/hardfloat`
  * `mips/softfloat`
  * `mipsle/hardfloat`
  * `mipsle/softfloat`
  * `mips64/hardfloat`
  * `mips64/softfloat`
  * `mips64le/hardfloat`
  * `mips64le/softfloat`
* Add vendor and lint validation bake targets
* Switch to GitHub Actions
* Add dependabot
* Mutualize tests and handle them through bake and GHA
* Publish Docker image (from scratch with only gosu binary)

## 1.12 (2018/10/16)

* built on Go 1.13.10, `runc` 1.0.0-rc10, Alpine 3.11
* added `mips64le` support ([tianon/gosu#69](https://github.com/tianon/gosu/issues/69))
* dropped `ppc64` support (not to be confused with ppc64le)

## 1.11 (2018/10/16)

* built on Go 1.11.1, `runc` 1.0.0-rc5, Alpine 3.8
* added explicit `--version` and `--help` flags ([tianon/gosu#44](https://github.com/tianon/gosu/issues/44))

## 1.10 (2016/05/11)

* built on Go 1.7 ([tianon/gosu#25](https://github.com/tianon/gosu/issues/25))
* official `s390x` release binary ([tianon/gosu#28](https://github.com/tianon/gosu/issues/28))
* slightly simpler usage output

## 1.9 (2016/05/11)

* fix cross-compilation of official binaries ([tianon/gosu#19](https://github.com/tianon/gosu/issues/19))

## 1.8 (2016/04/19)

* build against Go 1.6
* add `-s` and `-w` to `-ldflags` so that release binaries are even smaller (~2.6M down to ~1.8M)
* add simple integration test suite

## 1.7 (2015/11/08)

* update to use `github.com/opencontainers/runc/libcontainer` instead of `github.com/docker/libcontainer`
* add `arm64`, `ppc64`, and `ppc64le` to cross-compiled official binaries

## 1.6 (2015/10/06)

* revert `fchown(2)` all open file descriptors; turns out that's NOT OK (see discussion [tianon/gosu#8](https://github.com/tianon/gosu/issues/8) for details)

## 1.5 (2015/04/20)

* build against Go 1.5
* `fchown(2)` all open file descriptors before switching users so that they can be used appropriately by the user we're switching to

## 1.4 (2015/04/20)

* update `libcontainer` dependency to [docker-archive/libcontainer@`b322073`](https://github.com/docker-archive/libcontainer/commit/b322073f27b0e9e60b2ab07eff7f4e96a24cb3f9)

## 1.3 (2015/03/24)

* `golang:1.4`
* always set `HOME` ([tianon/gosu#3](https://github.com/tianon/gosu/issues/3))

## 1.2 (2014/11/19)

* now built from golang
* cross compiled for multiple arches
* first GPG signed release

## 1.1 (2014/07/14)

* add `LockOSThread` and explicit `GOMAXPROCS` to ensure even more explicitly that we're running in the same thread for the duration
* add better version output (including compilation info)
* build against Go 1.3 (via [tianon/golang](https://registry.hub.docker.com/u/tianon/golang/) and the new `Dockerfile`+`build.sh`)

## 1.0 (2014/06/02)

* add `VERSION` constant (and put it in the usage output)
