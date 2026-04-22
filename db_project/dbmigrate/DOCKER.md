# Docker Quick Start Guide

## Prerequisites

Install Docker and Docker Compose on Rocky Linux:

### Automated Installation (Recommended)

```bash
# Run the installation script
sudo ./install-docker-rocky.sh
```

### Manual Installation

```bash
# Install Docker
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (optional, to run without sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

📘 **For detailed installation instructions**, see [INSTALL-DOCKER.md](INSTALL-DOCKER.md)

### Open Firewall Ports (Rocky Linux)

After installing Docker, open the required ports:

```bash
sudo ./open-ports.sh
```

Or manually:
```bash
# Open frontend port
sudo firewall-cmd --permanent --add-port=3000/tcp

# Open backend API port
sudo firewall-cmd --permanent --add-port=5000/tcp

# Reload firewall
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-all
```

## Running the Application

### 1. Start All Services

```bash
cd log-app
docker compose up -d
```

This will:
- Pull MariaDB, Node.js, and Apache HTTP Server images
- Build the backend and frontend containers
- Create a network for inter-container communication
- Start all three services

### 2. Check Status

```bash
# View running containers
docker compose ps

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f mariadb
```

### 3. Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **API Health Check**: http://localhost:5000/api/health

### 4. Stop Services

```bash
# Stop containers (preserves data)
docker compose stop

# Stop and remove containers (preserves data volumes)
docker compose down

# Stop and remove everything including database data
docker compose down -v
```

## Useful Docker Commands

### Managing the Stack

```bash
# Rebuild containers after code changes
docker compose build

# Rebuild without cache
docker compose build --no-cache

# Restart a specific service
docker compose restart backend

# View resource usage
docker compose stats
```

### Debugging

```bash
# Execute commands in a running container
docker compose exec backend sh
docker compose exec mariadb mysql -u logapp -plogapp123 logdb

# View container details
docker compose inspect backend

# Check network connectivity
docker compose exec backend ping mariadb
```

### Database Management

```bash
# Connect to MariaDB
docker compose exec mariadb mysql -u logapp -plogapp123 logdb

# Backup database
docker compose exec mariadb mysqldump -u logapp -plogapp123 logdb > backup.sql

# Restore database
docker compose exec -T mariadb mysql -u logapp -plogapp123 logdb < backup.sql

# View logs table
docker compose exec mariadb mysql -u logapp -plogapp123 logdb -e "SELECT * FROM logs ORDER BY timestamp DESC LIMIT 10;"
```

## Configuration

### Changing Ports

Edit `docker-compose.yml`:

```yaml
services:
  frontend:
    ports:
      - "3001:80"  # Change 3000 to 3001
  backend:
    ports:
      - "5001:5000"  # Change 5000 to 5001
```

### Changing Database Credentials

Edit `docker-compose.yml`:

```yaml
services:
  mariadb:
    environment:
      MYSQL_PASSWORD: your_new_password
  backend:
    environment:
      DB_PASSWORD: your_new_password
```

Then rebuild:
```bash
docker compose down -v
docker compose up -d
```

## Production Deployment

### Using Docker Compose in Production

1. Create a production compose file:

```bash
cp docker-compose.yml docker-compose.prod.yml
```

2. Edit `docker-compose.prod.yml`:
   - Change default passwords
   - Add resource limits
   - Configure proper logging
   - Set up volume backups
   - Use external networks if needed

3. Deploy:

```bash
docker compose -f docker-compose.prod.yml up -d
```

### Security Recommendations

1. **Change default passwords** in docker-compose.yml
2. **Use secrets** for sensitive data:
   ```bash
   echo "mysecretpassword" | docker secret create db_password -
   ```
3. **Limit container resources** (add to services):
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '1'
         memory: 512M
   ```
4. **Run containers as non-root user**
5. **Keep images updated**: `docker compose pull && docker compose up -d`

## Troubleshooting

### Container won't start

```bash
# Check logs
docker compose logs backend

# Check if port is in use
sudo ss -tulpn | grep :5000

# Remove all containers and start fresh
docker compose down -v
docker compose up -d
```

### Database connection errors

```bash
# Wait for database to fully start (check health)
docker compose ps

# Test database connectivity
docker compose exec backend ping mariadb
docker compose exec backend nc -zv mariadb 3306
```

### Out of disk space

```bash
# Clean up unused images and volumes
docker system prune -a --volumes

# Check disk usage
docker system df
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MariaDB Docker Hub](https://hub.docker.com/_/mariadb)
