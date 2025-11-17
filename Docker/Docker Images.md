Docker Images
Understanding Docker Images
Docker images are read-only templates used to create containers. They consist of layers stacked on top of each other.

Image Layers
# View image layers
docker history <image>

# Inspect image
docker inspect <image>
Dockerfile Basics
Simple Dockerfile
# Base image
FROM ubuntu:22.04

# Maintainer
LABEL maintainer="your-email@example.com"

# Run commands
RUN apt-get update && apt-get install -y nginx

# Expose port
EXPOSE 80

# Start command
CMD ["nginx", "-g", "daemon off;"]
Dockerfile Instructions
FROM
# Specify base image
FROM ubuntu:22.04
FROM node:16-alpine
FROM python:3.9-slim
RUN
# Execute commands during build
RUN apt-get update
RUN apt-get install -y curl
RUN npm install
RUN pip install -r requirements.txt

# Multiple commands in one layer
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*
COPY and ADD
# Copy files from host to image
COPY app.py /app/
COPY . /app/

# ADD can extract archives
ADD archive.tar.gz /app/
WORKDIR
# Set working directory
WORKDIR /app
RUN npm install
COPY . .
ENV
# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV DATABASE_URL=postgresql://localhost/mydb
EXPOSE
# Document which ports the container listens on
EXPOSE 80
EXPOSE 443
EXPOSE 3000
CMD and ENTRYPOINT
# CMD - default command (can be overridden)
CMD ["python", "app.py"]
CMD ["npm", "start"]

# ENTRYPOINT - always executed
ENTRYPOINT ["python"]
CMD ["app.py"]

# Shell form
CMD python app.py
USER
# Run as non-root user
RUN useradd -m myuser
USER myuser
VOLUME
# Create mount point
VOLUME /data
VOLUME ["/var/log", "/var/db"]
ARG
# Build-time variables
ARG VERSION=1.0
RUN echo "Building version ${VERSION}"
Building Images
# Build from Dockerfile
docker build -t myapp:1.0 .

# Build with custom Dockerfile
docker build -f Dockerfile.dev -t myapp:dev .

# Build with build args
docker build --build-arg VERSION=2.0 -t myapp:2.0 .

# Build without cache
docker build --no-cache -t myapp:1.0 .

# Build and tag multiple times
docker build -t myapp:1.0 -t myapp:latest .
Practical Examples
Example 1: Python Flask App
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
# Build
docker build -t flask-app:1.0 .

# Run
docker run -d -p 5000:5000 flask-app:1.0
Example 2: Node.js App
FROM node:16-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

USER node

CMD ["node", "server.js"]
Example 3: Multi-stage Build
# Build stage
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
Example 4: Go Application
# Build stage
FROM golang:1.19 AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o main .

# Runtime stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
Image Tagging
# Tag image
docker tag myapp:1.0 myapp:latest
docker tag myapp:1.0 username/myapp:1.0

# Multiple tags
docker build -t myapp:1.0 -t myapp:latest -t myapp:stable .
Image Management
# List images
docker images

# Remove image
docker rmi myapp:1.0

# Remove unused images
docker image prune

# Remove all images
docker rmi $(docker images -q)

# Save image to tar
docker save myapp:1.0 > myapp.tar

# Load image from tar
docker load < myapp.tar

# Export container as image
docker export <container-id> > container.tar
docker import container.tar myapp:1.0
Best Practices
1. Use Official Base Images
FROM node:16-alpine
FROM python:3.9-slim
FROM nginx:alpine
2. Minimize Layers
# Bad - multiple layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git

# Good - single layer
RUN apt-get update && \
    apt-get install -y curl git && \
    rm -rf /var/lib/apt/lists/*
3. Use .dockerignore
node_modules
.git
.env
*.log
4. Multi-stage Builds
# Reduces final image size
FROM builder AS build
# ... build steps

FROM runtime
COPY --from=build /app/binary .
5. Run as Non-root
RUN useradd -m appuser
USER appuser
6. Use Specific Tags
# Bad
FROM node

# Good
FROM node:16.14.2-alpine
Image Inspection
# View image details
docker inspect myapp:1.0

# View image history
docker history myapp:1.0

# View image layers
docker image inspect myapp:1.0 --format='{{.RootFS.Layers}}'