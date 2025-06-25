# Use official Go image as base
FROM golang:1.24.3-alpine AS builder

# Install protobuf compiler and git
RUN apk add --no-cache protobuf protobuf-dev git

# Install protoc-gen-go
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest

# Set working directory
WORKDIR /app

# Copy go mod files first for better caching
COPY backend/server/go.mod backend/server/go.sum ./

# Download dependencies
RUN go mod download

# Copy shared protobuf files
COPY backend/shared/ ./shared/

# Copy server source code
COPY backend/server/ ./

# Generate protobuf files
RUN protoc --go_out=./pkg/packets --go_opt=paths=source_relative ./shared/packets.proto

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/main.go

# Use minimal alpine image for runtime
FROM alpine:latest

# Install ca-certificates for HTTPS requests (if needed)
RUN apk --no-cache add ca-certificates

# Create non-root user
RUN addgroup -g 1001 appgroup && adduser -D -u 1001 -G appgroup appuser

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/main .

# Change ownership to non-root user
RUN chown appuser:appgroup ./main

# Switch to non-root user
USER appuser

# Expose port 5000
EXPOSE 5000

# Run the application on port 5000
CMD ["./main", "-port=5000"]
