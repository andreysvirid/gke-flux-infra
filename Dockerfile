FROM golang:1.21-alpine AS builder
WORKDIR /app

# Копіюємо тільки файли Go-модуля спершу
COPY --from=builder /app/kbot .
CMD ["./kbot"]

# ---- Build stage ----
FROM golang:1.21-alpine AS builder
WORKDIR /app

# Копіюємо файли Go-модуля з піддиректорії kbot
COPY kbot/go.mod kbot/go.sum ./
RUN go mod download

# Копіюємо весь код з піддиректорії kbot
COPY kbot/. ./
RUN go build -o kbot

# ---- Final stage ----
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY --from=builder /app/kbot .
CMD ["./kbot"]