#!/usr/bin/env bash
#
# Build ws-scrcpy-web for linux/arm64.
#
# Usage:
#   ./build-arm64.sh [image-tag]
#
# Examples:
#   ./build-arm64.sh
#   ./build-arm64.sh ws-scrcpy-web:arm64-latest
#
# Requires: colima (or Docker Desktop) with buildx + QEMU emulation.
# On an x86_64 host, QEMU emulates arm64 and the build is slow (~15-25 min).
# On an arm64 host (Apple Silicon), this builds natively and is much faster.

set -euo pipefail

TAG="${1:-ws-scrcpy-web:arm64-local}"
CONTEXT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Building ws-scrcpy-web for linux/arm64 ==="
echo "  Tag:     $TAG"
echo "  Context: $CONTEXT_DIR"
echo "  Host:    $(uname -m)"

# Ensure buildx builder exists
if ! docker buildx inspect multiarch >/dev/null 2>&1; then
    echo "=== Creating buildx builder 'multiarch' ==="
    docker buildx create --name multiarch --driver docker-container --use
    docker buildx inspect --bootstrap
else
    docker buildx use multiarch
fi

# Build for arm64. --load puts the image into the local docker engine.
# On x86_64 this uses QEMU; on arm64 it is native.
echo "=== Starting build (this may take a while on x86_64/QEMU) ==="
docker buildx build \
    --platform linux/arm64 \
    --tag "$TAG" \
    --load \
    --file "$CONTEXT_DIR/Dockerfile" \
    "$CONTEXT_DIR"

echo ""
echo "=== Build complete ==="
echo "  Image: $TAG"
echo "  Verify: docker inspect $TAG --format '{{.Architecture}}'"
echo "  Run:    docker run --rm -p 8000:8000 -v ws-data:/data $TAG"
