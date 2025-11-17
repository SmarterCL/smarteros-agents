# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache git make

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy protobuf generated code and source
COPY gen/ ./gen/
COPY cmd/ ./cmd/
COPY specs/ ./specs/

# Build binary
RUN cd cmd/smarteros-mcp-server && \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /smarteros-mcp-server .

# Runtime stage
FROM alpine:3.19

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy binary from builder
COPY --from=builder /smarteros-mcp-server /app/smarteros-mcp-server

# Environment variables
ENV LLM_PROVIDER=openai \
    VAULT_ADDR=http://vault.smarterbot.cl:8200 \
    REDPANDA_BROKERS=kafka.smarterbot.cl:19092 \
    SUPABASE_URL=https://api.smarterbot.cl \
    SENTRY_DSN=""

# Expose stdio for MCP protocol (not a network port)
# The server communicates via stdin/stdout

# Health check (checks if binary exists and is executable)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD [ -x /app/smarteros-mcp-server ] || exit 1

# Run as non-root user
RUN addgroup -g 1000 smarteros && \
    adduser -D -u 1000 -G smarteros smarteros && \
    chown -R smarteros:smarteros /app

USER smarteros

ENTRYPOINT ["/app/smarteros-mcp-server"]
