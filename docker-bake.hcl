// Go version
variable "GO_VERSION" {
  default = "1.16"
}

target "_common" {
  args = {
    GO_VERSION = GO_VERSION
    BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
  }
}

// Special target: https://github.com/docker/metadata-action#bake-definition
target "docker-metadata-action" {
  tags = ["yasu:local"]
}

group "default" {
  targets = ["image-local"]
}

target "binary" {
  inherits = ["_common"]
  target = "binary"
  output = ["./bin"]
}

target "artifact" {
  inherits = ["_common"]
  target = "artifacts"
  output = ["./dist"]
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

target "test-alpine" {
  inherits = ["_common"]
  target = "test-alpine"
  output = ["type=cacheonly"]
}

target "test-debian" {
  inherits = ["_common"]
  target = "test-debian"
  output = ["type=cacheonly"]
}
