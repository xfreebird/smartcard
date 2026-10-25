#!/usr/bin/env bash
# Build + test MoldSignKit with the Linux implementations (OpenSSL crypto/RSA/TLS, POSIX sockets) on macOS.
# Catches most Linux-port bugs without a Linux machine; the real Linux build still needs CI (LNX-07, R-09).
#   needs: brew install openssl@3
#   usage: scripts/test-portable-macos.sh [extra swift test args]   (MSIGN_NETWORK_TESTS=1 for live PKI)
set -euo pipefail
OPENSSL="$(brew --prefix openssl@3)"
cd "$(dirname "$0")/../swift/MoldSignKit"
flags=(--build-path .build-portable
       -Xswiftc -DMOLDSIGN_PORTABLE -Xcc -DMOLDSIGN_OPENSSL
       -Xcc "-I$OPENSSL/include" -Xlinker "-L$OPENSSL/lib" -Xlinker -lssl -Xlinker -lcrypto)
swift build "${flags[@]}"
swift test "${flags[@]}" "$@"
