# Stage 1: Build
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Встановлюємо залежності для збірки (make, git і т.д.)
RUN apk add --no-cache git build-base

# Копіюємо модуль та завантажуємо залежності
COPY go.mod go.sum ./
RUN go mod download

# Копіюємо код
COPY . .

# Статична збірка бінарника
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o kbot main.go

# Stage 2: Final image
FROM alpine:3.18

WORKDIR /app

# Копіюємо бінарник
COPY --from=builder /app/kbot .

# Встановлюємо сертифікати для TLS
RUN apk add --no-cache ca-certificates

# TELEGRAM_TOKEN можна задавати під час запуску
ENV TELEGRAM_TOKEN=""

# Запуск бота
ENTRYPOINT ["./kbot"]