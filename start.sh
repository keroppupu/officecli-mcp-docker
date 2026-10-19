#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="officecli-mcp-rhel-x86:ver0.2"
TAR_FILE="${DIR}/officecli-mcp-rhel-x86.tar.gz"
CONTAINER_NAME="officecli-mcp-sse"
PORT="${PORT:-8010}"
DATA_DIR="${DIR}/data"

# Select container runtime: docker or podman
if command -v docker >/dev/null 2>&1; then
    RUNTIME="docker"
elif command -v podman >/dev/null 2>&1; then
    RUNTIME="podman"
else
    echo "Error: Neither docker nor podman was found on this system." >&2
    exit 1
fi

echo "=== Using container runtime: ${RUNTIME} ==="

# Force reload if requested via argument or if image does not exist
if [ "$1" = "--reload" ] || [ "$1" = "-r" ] || ! ${RUNTIME} image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
    if [ -f "${TAR_FILE}" ]; then
        echo "=== Loading image from ${TAR_FILE} ==="
        ${RUNTIME} load < "${TAR_FILE}"
    fi
fi

# Fallback check if ver0.2 or latest is available
if ! ${RUNTIME} image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
    if ${RUNTIME} image inspect "officecli-mcp-rhel-x86:latest" >/dev/null 2>&1; then
        IMAGE_NAME="officecli-mcp-rhel-x86:latest"
    else
        echo "Error: Image '${IMAGE_NAME}' not found and '${TAR_FILE}' does not exist." >&2
        exit 1
    fi
fi

# Ensure data directory exists
mkdir -p "${DATA_DIR}"

# Stop and remove existing container if running
if ${RUNTIME} ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "=== Stopping and removing existing container: ${CONTAINER_NAME} ==="
    ${RUNTIME} rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
fi

# Start the container
echo "=== Starting container ${CONTAINER_NAME} using image ${IMAGE_NAME} on port ${PORT} ==="
${RUNTIME} run -d \
    --name "${CONTAINER_NAME}" \
    -p "${PORT}:8010" \
    -v "${DATA_DIR}:/data" \
    --restart unless-stopped \
    "${IMAGE_NAME}"

echo "=== Waiting for service to be ready... ==="
sleep 2

# Check health endpoint if curl is available
if command -v curl >/dev/null 2>&1; then
    HEALTH=$(curl -s "http://localhost:${PORT}/healthz" 2>/dev/null || echo "failed")
    if [ "${HEALTH}" = "ok" ]; then
        echo "=== Service is healthy! (http://localhost:${PORT}/healthz -> ok) ==="
    else
        echo "=== Service started (health check status: ${HEALTH}) ==="
    fi
fi

echo ""
echo "=== OfficeCLI MCP Server is running! ==="
echo "  - SSE Endpoint   : http://<HOST_IP>:${PORT}/sse"
echo "  - Health Check   : http://<HOST_IP>:${PORT}/healthz"
echo "  - Data Directory : ${DATA_DIR}"
echo ""
echo "To view logs: ${RUNTIME} logs -f ${CONTAINER_NAME}"
echo "To stop     : ${RUNTIME} stop ${CONTAINER_NAME}"
