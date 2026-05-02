# ======== Build Stage ========
# Define the Go version as an argument for flexibility
ARG GO_VERSION=1.25

# Use a lightweight Alpine-based Go image for building the binary
FROM golang:${GO_VERSION}-alpine AS builder

# Set the working directory inside the container
WORKDIR /src

# Install basic certificates and timezone data needed for the build
RUN apk add --no-cache ca-certificates tzdata

# Copy dependency files first to leverage Docker caching
COPY Server/MuchToDo/go.mod Server/MuchToDo/go.sum ./
RUN go mod download && go mod verify

# Copy the application source code
COPY Server/MuchToDo/cmd ./cmd
COPY Server/MuchToDo/internal ./internal
COPY Server/MuchToDo/docs ./docs

# Set build arguments for cross-compilation (defaults to linux/amd64)
ARG TARGETOS=linux
ARG TARGETARCH=amd64

# Build the Go binary:
# CGO_ENABLED=0 creates a static binary (easier to run in minimal images)
# -trimpath and ldflags "-s -w" reduce the binary size by removing debug info
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" -o /out/muchtodo ./cmd/api

# ======== Final Run Stage ========
# Use a fresh, tiny Alpine image to keep the final production image small
FROM alpine:3.22

# Install runtime dependencies and create a non-root user for security
RUN apk add --no-cache ca-certificates tzdata wget && \
    addgroup -S app && \
    adduser -S -G app app && \
    mkdir -p /app && \
    chown app:app /app

WORKDIR /app

# Copy only the compiled binary from the builder stage
COPY --from=builder --chown=app:app /out/muchtodo /app/muchtodo

# Copy the entrypoint script and ensure it has correct permissions/line endings
COPY --chown=app:app docker-entrypoint.sh /app/docker-entrypoint.sh
RUN sed -i 's/\r$//' /app/docker-entrypoint.sh && \
    chmod 755 /app/docker-entrypoint.sh

    
# Switch to the non-root user for better security
USER app

# Document that the app listens on port 8080
EXPOSE 8080

# Define a health check to ensure the service is actually running
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8080/health || exit 1

# Set the script that runs when the container starts
ENTRYPOINT ["/app/docker-entrypoint.sh"]
