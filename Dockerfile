# приклад для Go-проєкту
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o kbot

FROM debian:bullseye-slim
COPY --from=builder /app/kbot /usr/local/bin/kbot
ENTRYPOINT ["kbot"]
