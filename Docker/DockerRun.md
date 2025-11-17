
Basic Docker Run
# Simple run
docker run nginx

# Run in detached mode
docker run -d nginx

# Run with custom name
docker run -d --name webserver nginx

# Run and remove after exit
docker run --rm nginx
Port Mapping
# Map container port to host port
docker run -d -p 8080:80 nginx

# Map to random host port
docker run -d -P nginx

# Multiple port mappings
docker run -d -p 8080:80 -p 8443:443 nginx

# Bind to specific interface
docker run -d -p 127.0.0.1:8080:80 nginx
Environment Variables
# Single environment variable
docker run -d -e MYSQL_ROOT_PASSWORD=secret mysql

# Multiple environment variables
docker run -d \
  -e MYSQL_ROOT_PASSWORD=secret \
  -e MYSQL_DATABASE=mydb \
  -e MYSQL_USER=user \
  -e MYSQL_PASSWORD=password \
  mysql

# From file
docker run -d --env-file ./env.list mysql
Volume Mounting
# Bind mount (host directory to container)
docker run -d -v /host/path:/container/path nginx

# Named volume
docker run -d -v mydata:/var/lib/mysql mysql

# Read-only mount
docker run -d -v /host/path:/container/path:ro nginx

# Anonymous volume
docker run -d -v /container/path nginx
Network Options
# Default bridge network
docker run -d nginx

# Host network
docker run -d --network host nginx

# Custom network
docker network create mynetwork
docker run -d --network mynetwork nginx

# No network
docker run -d --network none nginx
Resource Limits
# Limit memory
docker run -d --memory="512m" nginx

# Limit CPU
docker run -d --cpus="1.5" nginx

# CPU shares
docker run -d --cpu-shares=512 nginx

# Combined limits
docker run -d \
  --memory="1g" \
  --cpus="2" \
  --memory-swap="2g" \
  nginx
Interactive Mode
# Interactive terminal
docker run -it ubuntu /bin/bash

# Interactive with custom command
docker run -it ubuntu ls -la

# Attach to running container
docker attach <container-id>

# Detach without stopping (Ctrl+P, Ctrl+Q)
Working Directory
# Set working directory
docker run -w /app nginx ls

# With volume mount
docker run -v $(pwd):/app -w /app node:14 npm install
User and Permissions
# Run as specific user
docker run -u 1000:1000 nginx

# Run as root
docker run -u root nginx

# With user name
docker run -u myuser nginx
Restart Policies
# No restart (default)
docker run -d --restart=no nginx

# Always restart
docker run -d --restart=always nginx

# Restart on failure
docker run -d --restart=on-failure nginx

# Restart with max attempts
docker run -d --restart=on-failure:5 nginx

# Unless stopped
docker run -d --restart=unless-stopped nginx
Practical Examples
Example 1: Web Server with Volume
# Create HTML file
echo "<h1>Hello Docker</h1>" > index.html

# Run nginx with volume
docker run -d \
  --name myweb \
  -p 8080:80 \
  -v $(pwd):/usr/share/nginx/html:ro \
  nginx

# Test
curl http://localhost:8080
Example 2: Database with Persistent Storage
# Create volume
docker volume create pgdata

# Run PostgreSQL
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=mydb \
  -v pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:14

# Connect
docker exec -it postgres psql -U postgres -d mydb
Example 3: Development Environment
# Run Node.js app
docker run -d \
  --name nodeapp \
  -p 3000:3000 \
  -v $(pwd):/app \
  -w /app \
  -e NODE_ENV=development \
  node:16 \
  npm start
Example 4: Redis with Custom Config
# Run Redis
docker run -d \
  --name redis \
  -p 6379:6379 \
  -v $(pwd)/redis.conf:/usr/local/etc/redis/redis.conf \
  redis redis-server /usr/local/etc/redis/redis.conf
Command Options Reference
Option	Description
-d	Detached mode
-p	Port mapping
-v	Volume mount
-e	Environment variable
--name	Container name
--rm	Remove after exit
-it	Interactive terminal
--network	Network mode
--restart	Restart policy
--memory	Memory limit
--cpus	CPU limit