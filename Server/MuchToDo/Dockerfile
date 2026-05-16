# =========================
# BUILD STAGE
# =========================
# Explicitly lock down the minor version for deterministic builds
FROM golang:1.25.1-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

# Added structural optimization flags (-ldflags="-w -s") to strip debug info and shrink binary size
RUN CGO_ENABLED=0 GOOS=linux go build \
  -ldflags="-w -s" \
  -o server ./cmd/api

# =========================
# RUNTIME STAGE
# =========================
# FIXED: Locked alpine to a stable version (3.20) for consistent vulnerability scans
FROM alpine:3.20

RUN apk --no-cache add ca-certificates

# FIXED: Create a non-root system user and group (Meets Phase 6 Least-Privilege requirement)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# FIXED: Swapped working directory from /root/ to the user's home space
WORKDIR /home/appuser

# Copy the compiled binary over from the builder stage
COPY --from=builder /app/server .

# FIXED: Securely pass folder and file execution ownership to your restricted user
RUN chown -R appuser:appgroup /home/appuser

# FIXED: Force container execution engine to run as the non-root user
USER appuser

EXPOSE 8080

CMD ["./server"]
