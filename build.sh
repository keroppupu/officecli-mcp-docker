#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="officecli-mcp-rhel-x86"
TAG="latest"
OUTPUT_TAR="${DIR}/${IMAGE_NAME}.tar.gz"

echo "=== Building x86_64 Image for RHEL compatibility ==="
docker build --platform linux/amd64 -t "${IMAGE_NAME}:${TAG}" "${DIR}"

echo "=== Exporting offline image to ${OUTPUT_TAR} ==="
docker save "${IMAGE_NAME}:${TAG}" | gzip > "${OUTPUT_TAR}"

echo "=== Done! File saved at: ${OUTPUT_TAR} ==="
ls -lh "${OUTPUT_TAR}"
