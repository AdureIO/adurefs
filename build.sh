#!/usr/bin/env bash
set -e

NAMESPACE="adureio"
PLUGIN_NAME="adurefs"
TAG="latest"

FULL_PLUGIN_NAME="${NAMESPACE}/${PLUGIN_NAME}:${TAG}"
BUILD_DIR="./plugin_build"

echo "=== Cleaning previous build structures ==="
docker plugin disable "$FULL_PLUGIN_NAME" 2>/dev/null || true
docker plugin rm "$FULL_PLUGIN_NAME" 2>/dev/null || true
rm -rf "$BUILD_DIR"

echo "=== Building temporary container rootfs (Forcing amd64) ==="
# Use buildx for robust cross-compilation on Apple Silicon (M1/M2/M3)
docker buildx build --platform linux/amd64 --load -t adurefs-rootfs -f Dockerfile .

echo "=== Exporting container filesystem ==="
mkdir -p "$BUILD_DIR/rootfs"
TMP_CONTAINER=$(docker create --platform linux/amd64 adurefs-rootfs)
docker export "$TMP_CONTAINER" | tar -x -C "$BUILD_DIR/rootfs"
docker rm "$TMP_CONTAINER"
docker rmi adurefs-rootfs

echo "=== Injecting runtime configurations ==="
cp config.json "$BUILD_DIR/"

echo "=== Generating Managed Docker Plugin ==="
docker plugin create "$FULL_PLUGIN_NAME" "$BUILD_DIR"

echo "=== Cleaning build directory artifacts ==="
rm -rf "$BUILD_DIR"
docker plugin push $FULL_PLUGIN_NAME

echo "=== Success! ==="
echo "The plugin is now compiled and registered locally as '$FULL_PLUGIN_NAME'."
echo "To configure and run it:"
echo "  docker plugin set $FULL_PLUGIN_NAME volumes.source=/mnt/gluster/swarm/volumes"
echo "  docker plugin enable $FULL_PLUGIN_NAME"
echo ""