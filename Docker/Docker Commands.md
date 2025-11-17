Docker Commands
Basic Commands
Container Management
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Run a container
docker run <image>

# Run container in detached mode
docker run -d <image>

# Run with custom name
docker run --name mycontainer <image>

# Stop a container
docker stop <container-id>

# Start a stopped container
docker start <container-id>

# Restart a container
docker restart <container-id>

# Remove a container
docker rm <container-id>

# Remove all stopped containers
docker container prune
Image Management
# List images
docker images

# Pull an image
docker pull <image>:<tag>

# Remove an image
docker rmi <image-id>

# Remove unused images
docker image prune

# Build an image
docker build -t <name>:<tag> .

# Tag an image
docker tag <image-id> <new-name>:<tag>
System Commands
# Show Docker version
docker --version

# Show system information
docker info

# Show disk usage
docker system df

# Clean up unused resources
docker system prune

# Clean up everything
docker system prune -a
Logs and Inspection
# View container logs
docker logs <container-id>

# Follow logs in real-time
docker logs -f <container-id>

# Show last N lines
docker logs --tail 100 <container-id>

# Inspect container details
docker inspect <container-id>

# Show container processes
docker top <container-id>

# Show container stats
docker stats <container-id>
Execute Commands in Container
# Execute command in running container
docker exec <container-id> <command>

# Interactive shell
docker exec -it <container-id> /bin/bash

# Run as specific user
docker exec -u root -it <container-id> /bin/bash
Container Lifecycle
# Create → Start → Run → Stop → Remove

# Create container without starting
docker create <image>

# Start created container
docker start <container-id>

# Pause container
docker pause <container-id>

# Unpause container
docker unpause <container-id>

# Kill container (force stop)
docker kill <container-id>

# Remove running container (force)
docker rm -f <container-id>
Practical Examples
Example 1: Run Nginx
# Run nginx web server
docker run -d -p 8080:80 --name mynginx nginx

# Check if running
docker ps

# View logs
docker logs mynginx

# Stop and remove
docker stop mynginx
docker rm mynginx
Example 2: Interactive Ubuntu
# Run Ubuntu interactively
docker run -it ubuntu /bin/bash

# Inside container
apt-get update
apt-get install curl
curl --version
exit
Example 3: Run MySQL
# Run MySQL with environment variables
docker run -d \
  --name mysql-db \
  -e MYSQL_ROOT_PASSWORD=mypassword \
  -e MYSQL_DATABASE=mydb \
  -p 3306:3306 \
  mysql:8.0

# Check logs
docker logs mysql-db

# Connect to MySQL
docker exec -it mysql-db mysql -uroot -pmypassword
Useful Command Combinations
# Stop all running containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Remove dangling images
docker rmi $(docker images -f "dangling=true" -q)

# Get container IP address
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container-id>