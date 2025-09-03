# Stage 1: Build
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Копіюємо Go-модуль з папки kbot
COPY kbot/go.mod kbot/go.sum ./

# Завантажуємо залежності
RUN go mod tidy

# Копіюємо весь код з папки kbot
COPY kbot/ .

# Запускаємо тести
RUN go test ./...

# Build
RUN go build -o kbot .

# Stage 2: Final image
FROM debian:bullseye-slim
WORKDIR /app

# Копіюємо готовий бінарник з етапу збірки
COPY --from=builder /app/kbot .

CMD ["./kbot"]