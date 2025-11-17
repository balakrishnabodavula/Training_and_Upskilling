
What is Container Orchestration?
Container orchestration automates the deployment, management, scaling, and networking of containers across clusters of hosts.

Why Orchestration?
Scaling: Automatically scale containers up/down
Load Balancing: Distribute traffic across containers
Self-Healing: Restart failed containers
Rolling Updates: Zero-downtime deployments
Service Discovery: Automatic DNS and networking
Resource Management: Optimize resource usage
Docker Swarm
Initialize Swarm
# Initialize swarm (manager node)
docker swarm init

# With specific IP
docker swarm init --advertise-addr 192.168.1.100

# Get join token for workers
docker swarm join-token worker

# Get join token for managers
docker swarm join-token manager
Join Swarm
# Join as worker
docker swarm join \
  --token SWMTKN-1-xxx \
  192.168.1.100:2377

# Join as manager
docker swarm join \
  --token SWMTKN-1-xxx \
  --advertise-addr 192.168.1.101 \
  192.168.1.100:2377
Swarm Management
# List nodes
docker node ls

# Inspect node
docker node inspect node-id

# Promote worker to manager
docker node promote node-id

# Demote manager to worker
docker node demote node-id

# Remove node
docker node rm node-id

# Leave swarm
docker swarm leave

# Leave swarm (force on manager)
docker swarm leave --force
Services
# Create service
docker service create --name web nginx

# Create with replicas
docker service create \
  --name web \
  --replicas 3 \
  nginx

# Create with port mapping
docker service create \
  --name web \
  --replicas 3 \
  -p 8080:80 \
  nginx

# List services
docker service ls

# Inspect service
docker service inspect web

# View service logs
docker service logs web

# Scale service
docker service scale web=5

# Update service
docker service update --image nginx:alpine web

# Remove service
docker service rm web
Service Constraints
# Run on specific node
docker service create \
  --name web \
  --constraint 'node.hostname==node1' \
  nginx

# Run on nodes with label
docker service create \
  --name web \
  --constraint 'node.labels.type==frontend' \
  nginx

# Multiple constraints
docker service create \
  --name web \
  --constraint 'node.role==worker' \
  --constraint 'node.labels.region==us-east' \
  nginx
Service Networks
# Create overlay network
docker network create --driver overlay myoverlay

# Create service on network
docker service create \
  --name web \
  --network myoverlay \
  nginx

# Attach service to network
docker service update --network-add myoverlay web
Service Volumes
# Create service with volume
docker service create \
  --name web \
  --mount type=volume,source=webdata,target=/data \
  nginx

# Bind mount
docker service create \
  --name web \
  --mount type=bind,source=/host/path,target=/container/path \
  nginx
Rolling Updates
# Update with rolling update
docker service update \
  --image nginx:alpine \
  --update-parallelism 2 \
  --update-delay 10s \
  web

# Rollback
docker service rollback web
Stack Deployment
# docker-stack.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    networks:
      - webnet

  visualizer:
    image: dockersamples/visualizer
    ports:
      - "8081:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    deploy:
      placement:
        constraints:
          - node.role==manager
    networks:
      - webnet

networks:
  webnet:
    driver: overlay
# Deploy stack
docker stack deploy -c docker-stack.yml mystack

# List stacks
docker stack ls

# List stack services
docker stack services mystack

# List stack tasks
docker stack ps mystack

# Remove stack
docker stack rm mystack