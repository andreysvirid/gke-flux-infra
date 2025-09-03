# Stage 1: Build
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Копіюємо модуль та завантажуємо залежності
COPY go.mod go.sum ./
RUN go mod tidy

# Копіюємо весь код
COPY . .

# Запускаємо тести
RUN go test ./...

# Build
RUN go build -o kbot .

# Stage 2: Final image
FROM debian:bullseye-slim
WORKDIR /app

# Копіюємо готовий бінарник
COPY --from=builder /app/kbot .

CMD ["./kbot"]