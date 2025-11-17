Docker Engine, Storage & Networking
Docker Engine Architecture
Components
Docker Daemon (dockerd) - Background service
Docker Client (docker) - CLI interface
containerd - Container runtime
runc - Low-level container runtime
Architecture Diagram
Docker Client → Docker Daemon → containerd → runc → Container
Docker Storage
Storage Drivers
# Check storage driver
docker info | grep "Storage Driver"

# Available drivers:
# - overlay2 (recommended)
# - aufs
# - devicemapper
# - btrfs
# - zfs
Volume Types
Named Volumes
# Create volume
docker volume create mydata

# List volumes
docker volume ls

# Inspect volume
docker volume inspect mydata

# Remove volume
docker volume rm mydata

# Use volume
docker run -v mydata:/data nginx
Bind Mounts
# Mount host directory
docker run -v /host/path:/container/path nginx

# Read-only mount
docker run -v /host/path:/container/path:ro nginx

# Current directory
docker run -v $(pwd):/app node
tmpfs Mounts
# Temporary filesystem in memory
docker run --tmpfs /tmp nginx

# With size limit
docker run --tmpfs /tmp:size=100m nginx
Volume Management
# Create volume with driver
docker volume create --driver local myvolume

# Create with options
docker volume create \
  --driver local \
  --opt type=nfs \
  --opt o=addr=192.168.1.1,rw \
  --opt device=:/path/to/dir \
  nfs-volume

# Backup volume
docker run --rm \
  -v mydata:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/backup.tar.gz /data

# Restore volume
docker run --rm \
  -v mydata:/data \
  -v $(pwd):/backup \
  ubuntu tar xzf /backup/backup.tar.gz -C /
Volume Plugins
# Install volume plugin
docker plugin install vieux/sshfs

# Create volume with plugin
docker volume create \
  --driver vieux/sshfs \
  -o sshcmd=user@host:/path \
  sshvolume
Docker Networking
Network Types
Bridge Network (Default)
# Create bridge network
docker network create mybridge

# Run container on bridge
docker run -d --network mybridge nginx

# Inspect network
docker network inspect mybridge
Host Network
# Use host network
docker run -d --network host nginx

# Container uses host's network stack
# No port mapping needed
None Network
# No network
docker run -d --network none nginx

# Container has no network access
Overlay Network
# For Docker Swarm
docker network create -d overlay myoverlay

# Multi-host networking
Network Commands
# List networks
docker network ls

# Create network
docker network create mynetwork

# Remove network
docker network rm mynetwork

# Connect container to network
docker network connect mynetwork container_name

# Disconnect container
docker network disconnect mynetwork container_name

# Inspect network
docker network inspect mynetwork

# Prune unused networks
docker network prune
Custom Bridge Network
# Create custom bridge
docker network create \
  --driver bridge \
  --subnet 172.20.0.0/16 \
  --gateway 172.20.0.1 \
  mybridge

# Run containers
docker run -d --name web --network mybridge nginx
docker run -d --name db --network mybridge postgres

# Containers can communicate by name
docker exec web ping db
Network with Docker Compose
version: '3.8'

services:
  web:
    image: nginx
    networks:
      - frontend
      - backend
  
  app:
    image: myapp
    networks:
      - backend
  
  db:
    image: postgres
    networks:
      - backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true
Port Publishing
# Publish single port
docker run -p 8080:80 nginx

# Publish to specific interface
docker run -p 127.0.0.1:8080:80 nginx

# Publish all exposed ports
docker run -P nginx

# Multiple ports
docker run -p 8080:80 -p 8443:443 nginx

# UDP port
docker run -p 53:53/udp dns-server
DNS Resolution
# Containers on same network resolve by name
docker network create mynet
docker run -d --name web --network mynet nginx
docker run -d --name app --network mynet myapp

# From app container
docker exec app ping web
docker exec app curl http://web
Network Aliases
# Add network alias
docker run -d \
  --name web \
  --network mynet \
  --network-alias webserver \
  nginx

# Access by alias
docker exec app curl http://webserver
Advanced Networking
MacVLAN Network
# Create macvlan network
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macvlan-net

# Container gets IP on physical network
docker run -d --network macvlan-net nginx
IPvLAN Network
# Create ipvlan network
docker network create -d ipvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  ipvlan-net
Network Troubleshooting
# Check container network
docker exec container_name ip addr

# Check routing
docker exec container_name ip route

# Test connectivity
docker exec container_name ping google.com

# Check DNS
docker exec container_name nslookup google.com

# Network statistics
docker stats container_name
Storage Best Practices
Use named volumes for persistent data
Bind mounts for development
tmpfs for sensitive temporary data
Regular backups of volumes
Clean up unused volumes
Use volume drivers for advanced storage
Networking Best Practices
Custom networks for isolation
Use service names for DNS
Limit exposed ports
Use internal networks for databases
Network segmentation
Monitor network traffic
Docker Storage Locations
# Linux
/var/lib/docker/volumes/
/var/lib/docker/overlay2/

# macOS
~/Library/Containers/com.docker.docker/Data/

# Windows
C:\ProgramData\Docker\
Performance Tuning
Storage
# Use overlay2 driver
# Configure in /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}
Network
# Increase MTU
docker network create \
  --opt com.docker.network.driver.mtu=9000 \
  mynetwork
Monitoring
# Container stats
docker stats

# Network stats
docker network inspect mynetwork

# Volume usage
docker system df -v

# Real-time events
docker events