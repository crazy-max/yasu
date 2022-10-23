variable "GO_VERSION" {
  default = "1.19"
}

variable "DESTDIR" {
  default = "./bin"
}

# GITHUB_REF is the actual ref that triggers the workflow and used as version
# when tag is pushed! https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
variable "GITHUB_REF" {
  default = ""
}

target "_common" {
  args = {
    GO_VERSION = GO_VERSION
  }
}

# Special target: https://github.com/docker/metadata-action#bake-definition
target "docker-metadata-action" {
  tags = ["yasu:local"]
}

group "default" {
  targets = ["image-local"]
}

target "binary" {
  inherits = ["_common"]
  target = "binary"
  output = ["${DESTDIR}/build"]
}

target "artifact" {
  inherits = ["_common"]
  target = "artifact"
  output = ["${DESTDIR}/artifact"]
}

target "artifact-all" {
  inherits = ["artifact"]
  platforms = [
    "linux/386",
    "linux/amd64",
    "linux/arm/v5",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64",
    "linux/mips/hardfloat",
    "linux/mips/softfloat",
    "linux/mipsle/hardfloat",
    "linux/mipsle/softfloat",
    "linux/mips64/hardfloat",
    "linux/mips64/softfloat",
    "linux/mips64le/hardfloat",
    "linux/mips64le/softfloat",
    "linux/ppc64le",
    "linux/riscv64",
    "linux/s390x"
  ]
}

target "release" {
  target = "release"
  output = ["${DESTDIR}/release"]
  contexts = {
    artifacts = "${DESTDIR}/artifact"
  }
}

target "image" {
  inherits = ["_common", "docker-metadata-action"]
}

target "image-local" {
  inherits = ["image"]
  output = ["type=docker"]
}

target "image-all" {
  inherits = ["image"]
  platforms = [
    "linux/386",
    "linux/amd64",
    "linux/arm/v5",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64",
    "linux/mips64le",
    "linux/ppc64le",
    "linux/riscv64",
    "linux/s390x"
  ]
}

target "vendor" {
  inherits = ["_common"]
  dockerfile = "./hack/vendor.Dockerfile"
  target = "update"
  output = ["."]
}

group "validate" {
  targets = ["lint", "vendor-validate"]
}

target "lint" {
  inherits = ["_common"]
  dockerfile = "./hack/lint.Dockerfile"
  target = "lint"
  output = ["type=cacheonly"]
}

target "vendor-validate" {
  inherits = ["_common"]
  dockerfile = "./hack/vendor.Dockerfile"
  target = "validate"
  output = ["type=cacheonly"]
}

group "test" {
  targets = ["test-alpine", "test-debian"]
}

variable "TEST_ALPINE_VARIANT" {
  default = "3.16"
}
target "test-alpine" {
  inherits = ["_common"]
  target = "test-alpine"
  output = ["type=cacheonly"]
  args = {
    TEST_ALPINE_VARIANT = TEST_ALPINE_VARIANT
  }
}

variable "TEST_DEBIAN_VARIANT" {
  default = "bullseye"
}
target "test-debian" {
  inherits = ["_common"]
  target = "test-debian"
  output = ["type=cacheonly"]
  args = {
    TEST_DEBIAN_VARIANT = TEST_DEBIAN_VARIANT
  }
}
