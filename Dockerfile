# ===== Stage 0: Run tests =====
FROM golang:1.21-alpine AS tester
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# Запускаємо тести
RUN go test ./...

# ===== Stage 1: Build binary =====
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o kbot ./cmd/main.go

# ===== Stage 2: Final image =====
FROM debian:bullseye-slim
WORKDIR /app
COPY --from=builder /app/kbot .
CMD ["./kbot"]
