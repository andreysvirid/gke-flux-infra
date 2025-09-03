# Stage 1: Build
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Копіюємо go.mod та go.sum з папки kbot
COPY kbot/go.mod kbot/go.sum ./

# Завантажуємо залежності
RUN go mod tidy

# Копіюємо весь код з папки kbot
COPY kbot/ ./

# Запускаємо тести
RUN go test ./...

# Build бінарника
RUN go build -o kbot .

# Stage 2: Final image
FROM debian:bullseye-slim

WORKDIR /app

# Копіюємо бінарник з builder
COPY --from=builder /app/kbot .

# Встановлюємо команду запуску
CMD ["./kbot"]
