FROM golang:1.21-alpine AS builder
WORKDIR /app

# Копіюємо тільки файли Go-модуля спершу
COPY go.mod go.sum ./
RUN go mod download

# Копіюємо решту коду
COPY . .
RUN go build -o kbot

FROM debian:bullseye-slim
WORKDIR /app
COPY --from=builder /app/kbot .
CMD ["./kbot"]