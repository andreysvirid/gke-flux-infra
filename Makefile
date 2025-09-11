BINARY=kbot1

build:
	go build -o $(BINARY) ./main.go

run:
	./$(BINARY)

clean:
	rm -f $(BINARY)

test:
	go test ./...