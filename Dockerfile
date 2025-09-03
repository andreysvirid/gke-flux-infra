# Stage 1: Build
FROM golang:1.21-alpine AS builder

# Робоча директорія
WORKDIR /app

# Копіюємо go.mod та go.sum
COPY kbot/go.mod kbot/go.sum ./
RUN go mod tidy

# Копіюємо весь код
COPY kbot/ ./

# Запускаємо тести
RUN go test ./...

# Build
RUN go build -o kbot

# Stage 2: Final image
FROM debian:bullseye-slim
WORKDIR /app
COPY --from=builder /app/kbot .
CMD ["./kbot"]
