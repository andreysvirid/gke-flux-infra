# Stage 1: Build
#FROM golang:1.22.2-alpine AS builder
FROM golang:1.22-alpine AS builder

# Робоча директорія
WORKDIR /app

# Копіюємо go.mod та go.sum
COPY go.mod go.sum ./
#RUN go mod download
RUN go mod tidy

# Копіюємо весь код
COPY . .

# Запускаємо тести
RUN go test ./...

# Build
RUN go build -o kbot kbot/main.go

# Stage 2: Final image
FROM debian:bullseye-slim
WORKDIR /app
COPY --from=builder /app/kbot .
CMD ["./kbot"]
