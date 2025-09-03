BINARY=kbot

build:
	go build -o $(BINARY) ./cmd/main.go

run:
	./$(BINARY)

clean:
	rm -f $(BINARY)

test:
	go test ./...