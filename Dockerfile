FROM golang:1.21-alpine AS builder

WORKDIR /app

# Копіюємо тільки необхідні файли для Go-модуля спершу (щоб скоротити кешування)
COPY go.mod go.sum ./
RUN go mod download

# Потім копіюємо весь код
COPY . .

# Будуємо бінарник
RUN go build -o kbot

# Підготовка мінімального образу
FROM debian:bullseye-slim
WORKDIR /app
COPY --from=builder /app/kbot .
CMD ["./kbot"]