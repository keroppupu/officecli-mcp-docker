FROM node:22-bookworm-slim

# Install required dependencies (libicu72 is required for .NET runtime)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    libicu72 \
    && rm -rf /var/lib/apt/lists/*

# Install supergateway globally
RUN npm install -g supergateway

# Download and install OfficeCLI binary based on system architecture (x64 / arm64)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        OFFICECLI_ARCH="x64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        OFFICECLI_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -fsSL "https://github.com/iOfficeAI/OfficeCLI/releases/latest/download/officecli-linux-${OFFICECLI_ARCH}" -o /usr/local/bin/officecli && \
    chmod +x /usr/local/bin/officecli

# Working directory for document processing
WORKDIR /data

# Expose SSE server port
EXPOSE 8010

ENV PORT=8010
ENV HOST=0.0.0.0

# Run supergateway to bridge stdio to SSE
CMD ["sh", "-c", "supergateway --stdio 'officecli mcp' --host ${HOST} --port ${PORT} --outputTransport sse"]
