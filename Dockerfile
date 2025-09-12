# -------- Stage 1: Build --------
FROM golang:1.22 AS builder
WORKDIR /app

# Скопіювати файли залежностей і завантажити їх
COPY go.mod go.sum ./
RUN go mod download

# Скопіювати решту коду
COPY . .

# Статична збірка бінарника
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o kbot .

# -------- Stage 2: Runtime --------
FROM alpine:3.20
WORKDIR /app

# Скопіювати тільки бінарник
COPY --from=builder /app/kbot .

# Додати сертифікати для HTTPS-запитів (Telegram API)
RUN apk add --no-cache ca-certificates

# Запуск
CMD ["./kbot"]