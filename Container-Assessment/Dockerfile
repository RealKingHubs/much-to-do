ARG GO_VERSION=1.25

FROM golang:${GO_VERSION}-alpine AS builder

WORKDIR /src

RUN apk add --no-cache ca-certificates tzdata

COPY Server/MuchToDo/go.mod Server/MuchToDo/go.sum ./
RUN go mod download && go mod verify

COPY Server/MuchToDo/cmd ./cmd
COPY Server/MuchToDo/internal ./internal
COPY Server/MuchToDo/docs ./docs

ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" -o /out/muchtodo ./cmd/api

FROM alpine:3.22

RUN apk add --no-cache ca-certificates tzdata wget && \
    addgroup -S app && \
    adduser -S -G app app && \
    mkdir -p /app && \
    chown app:app /app

WORKDIR /app

COPY --from=builder --chown=app:app /out/muchtodo /app/muchtodo
COPY --chown=app:app docker-entrypoint.sh /app/docker-entrypoint.sh

RUN sed -i 's/\r$//' /app/docker-entrypoint.sh && \
    chmod 755 /app/docker-entrypoint.sh

USER app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]
