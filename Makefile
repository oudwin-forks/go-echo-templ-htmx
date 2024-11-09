dev:
	go run ./cmd/main.go

build:
	go build -ldflags="-s -w" -o ./bin/main ./cmd/main.go
