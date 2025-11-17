
What is Docker Compose?
Docker Compose is a tool for defining and running multi-container Docker applications using a YAML file.

Installation
# Linux
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker-compose --version
Basic docker-compose.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
  
  db:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: secret
Docker Compose Commands
# Start services
docker-compose up

# Start in detached mode
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs

# Follow logs
docker-compose logs -f

# List services
docker-compose ps

# Execute command in service
docker-compose exec web sh

# Build images
docker-compose build

# Pull images
docker-compose pull

# Restart services
docker-compose restart
Service Configuration
Image
services:
  web:
    image: nginx:alpine
Build
services:
  app:
    build: .
    # or
    build:
      context: ./app
      dockerfile: Dockerfile.dev
Ports
services:
  web:
    ports:
      - "8080:80"
      - "8443:443"
Environment Variables
services:
  db:
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
    # or from file
    env_file:
      - .env
Volumes
services:
  web:
    volumes:
      - ./html:/usr/share/nginx/html
      - logs:/var/log/nginx
      
volumes:
  logs:
Networks
services:
  web:
    networks:
      - frontend
      - backend

networks:
  frontend:
  backend:
Depends On
services:
  web:
    depends_on:
      - db
  db:
    image: postgres
Restart Policy
services:
  web:
    restart: always
    # Options: no, always, on-failure, unless-stopped
Complete Examples
Example 1: WordPress with MySQL
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: secret
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - db
    restart: always

  db:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: rootsecret
    volumes:
      - db_data:/var/lib/mysql
    restart: always

volumes:
  wordpress_data:
  db_data:
Example 2: MEAN Stack
version: '3.8'

services:
  mongo:
    image: mongo:5
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: secret
    volumes:
      - mongo_data:/data/db

  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      MONGO_URL: mongodb://admin:secret@mongo:27017
    depends_on:
      - mongo

  frontend:
    build: ./frontend
    ports:
      - "4200:80"
    depends_on:
      - backend

volumes:
  mongo_data:
Example 3: Microservices
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - api
      - web

  api:
    build: ./api
    environment:
      DATABASE_URL: postgresql://user:pass@db:5432/mydb
      REDIS_URL: redis://redis:6379
    depends_on:
      - db
      - redis

  web:
    build: ./web
    environment:
      API_URL: http://api:3000

  db:
    image: postgres:14
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    volumes:
      - db_data:/var/lib/postgresql/data

  redis:
    image: redis:alpine
    volumes:
      - redis_data:/data

volumes:
  db_data:
  redis_data:

networks:
  default:
    driver: bridge
Example 4: Development Environment
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      NODE_ENV: development
      DATABASE_URL: postgresql://dev:dev@db:5432/devdb
    command: npm run dev
    depends_on:
      - db

  db:
    image: postgres:14-alpine
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: devdb
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data

  adminer:
    image: adminer
    ports:
      - "8080:8080"
    depends_on:
      - db

volumes:
  db_data:
Advanced Features
Health Checks
services:
  web:
    image: nginx
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
Resource Limits
services:
  app:
    image: myapp
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
Profiles
services:
  app:
    image: myapp
    profiles:
      - production
  
  debug:
    image: myapp-debug
    profiles:
      - debug
# Run with profile
docker-compose --profile production up
Override Files
docker-compose.override.yml
version: '3.8'

services:
  web:
    ports:
      - "8080:80"
    volumes:
      - ./dev:/app
# Automatically merged
docker-compose up

# Specify override file
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up