variable "VERSION" {
  default = "1.0"
}

variable "GIT_SHA" {
  default = "local"
}

variable "REGISTRY" {
  default = "localhost:5000"
}

target "_common" {
  platforms = ["linux/amd64", "linux/arm64"]
  labels = {
    "org.opencontainers.image.version"  = "${VERSION}"
    "org.opencontainers.image.revision" = "${GIT_SHA}"
    "org.opencontainers.image.source"   = "https://github.com/shopsas/shop"
  }
  cache-from = ["type=registry,ref=${REGISTRY}/cache:bake"]
  cache-to   = ["type=registry,ref=${REGISTRY}/cache:bake,mode=max"]
}

group "default" {
  targets = ["api", "worker"]
}

target "api" {
  inherits   = ["_common"]
  context    = "../tp01-optimisation-image/starter/shopapi"
  dockerfile = "Dockerfile"
  args = {
    APP_VERSION = "${VERSION}"
    GIT_SHA     = "${GIT_SHA}"
  }
  tags       = ["${REGISTRY}/shopapi:${VERSION}"]
  cache-from = ["type=registry,ref=${REGISTRY}/cache:api"]
  cache-to   = ["type=registry,ref=${REGISTRY}/cache:api,mode=max"]
}

target "worker" {
  inherits   = ["_common"]
  context    = "starter/shop-worker"
  dockerfile = "Dockerfile"
  secret     = ["id=pipconf,src=starter/shop-worker/pip.conf"]
  tags       = ["${REGISTRY}/shop-worker:${VERSION}"]
  cache-from = ["type=registry,ref=${REGISTRY}/cache:worker"]
  cache-to   = ["type=registry,ref=${REGISTRY}/cache:worker,mode=max"]
}

target "worker-test" {
  inherits   = ["worker"]
  target     = "test"
  output     = ["type=cacheonly"]
  tags       = []
  cache-from = []
  cache-to   = []
}
