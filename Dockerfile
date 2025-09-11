# Build stage
#FROM golang:1.21-alpine AS builder
FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o kbot main.go

# Final stage
FROM alpine:3.18

WORKDIR /app
COPY --from=builder /app/kbot .

ENTRYPOINT ["./kbot"]

# TELEGRAM_TOKEN можна задавати під час запуску
ENV TELEGRAM_TOKEN=""