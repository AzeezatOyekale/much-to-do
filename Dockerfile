# Stage 1: Build Go binary

FROM golang:1.25-alpine AS builder

# Install git (required for some Go modules)
RUN apk add --no-cache git

# Set working directory
WORKDIR /app

# Copy Go module files first (for caching)
COPY Server/MuchToDo/go.mod Server/MuchToDo/go.sum ./

# Download dependencies
RUN go mod download

# Copy the full application source
COPY Server/MuchToDo ./

# Build the API binary (THIS IS THE KEY LINE)
RUN go build -o muchtodo ./cmd/api

# Stage 2: Runtime image

FROM alpine:3.19

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy compiled binary from builder
COPY --from=builder /app/muchtodo .

# Switch to non-root user
USER appuser

# Expose application port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Run the application
CMD ["./muchtodo"]
