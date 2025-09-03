# Stage 1: Build
FROM golang:1.22-alpine AS builder

# Робоча директорія
WORKDIR /app

# Копіюємо go.mod і go.sum з підпапки kbot
COPY kbot/go.mod kbot/go.sum ./kbot/

# Переходимо у папку kbot
WORKDIR /app/kbot

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

# Копіюємо зібраний бінарник з попереднього stage
COPY --from=builder /app/kbot/kbot .

# Вказуємо команду за замовчуванням
CMD ["./kbot"]