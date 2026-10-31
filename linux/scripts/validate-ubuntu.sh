#!/usr/bin/env bash
# Ubuntu userspace build check. This is not an Ubuntu desktop/reader validation.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
engine=${CONTAINER_ENGINE:-podman}
"$engine" run --rm --security-opt label=disable -v "$root:/workspace:ro" docker.io/library/swift:6.2-noble bash -lc '
  set -euo pipefail
  apt-get update -qq
  apt-get install -y -qq libadwaita-1-dev libsecret-1-dev libpcsclite-dev libssl-dev pkg-config cmake libcurl4-openssl-dev curl ca-certificates
  mkdir /work && cp -a /workspace/linux /workspace/swift /workspace/spec /work/
  rm -rf /work/linux/.build /work/swift/MoldSignKit/.build
  cd /work/linux
  swift build
'
