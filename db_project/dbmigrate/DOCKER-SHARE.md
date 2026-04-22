# Docker Image Build and Share Guide

This guide shows how to build Docker images and share them with others locally (without Docker Hub).

## Method 1: Share Docker Images as TAR Files

### Step 1: Build the Images

```bash
cd log-app

# Build all images
docker compose build

# Or build individually
docker compose build frontend
docker compose build backend
```

### Step 2: Save Images to TAR Files

```bash
# Save frontend image
docker save -o logapp-frontend.tar log-app-frontend:latest

# Save backend image
docker save -o logapp-backend.tar log-app-backend:latest

# Save MariaDB image (if needed)
docker pull mariadb:11.0
docker save -o mariadb-11.tar mariadb:11.0

# Save all images in one file
docker save -o logapp-all.tar log-app-frontend:latest log-app-backend:latest mariadb:11.0
```

### Step 3: Transfer Files to Other Machine

```bash
# Option A: USB Drive
cp *.tar /path/to/usb/drive/

# Option B: SCP (network transfer)
scp logapp-all.tar user@192.168.1.100:/home/user/

# Option C: Shared folder
cp *.tar /path/to/shared/folder/
```

### Step 4: Load Images on Target Machine

```bash
# Load individual images
docker load -i logapp-frontend.tar
docker load -i logapp-backend.tar
docker load -i mariadb-11.tar

# Or load the combined file
docker load -i logapp-all.tar

# Verify images are loaded
docker images | grep logapp
docker images | grep mariadb
```

### Step 5: Start Application on Target Machine

```bash
# Copy the entire log-app folder to the target machine
# Then run:
cd log-app
./setup-env.sh
docker compose up -d
```

---

## Method 2: Build on Target Machine Directly

### Step 1: Transfer Source Code

```bash
# Compress the entire project
cd /path/to/net2300
tar -czf log-app.tar.gz log-app/

# Transfer to target machine
scp log-app.tar.gz user@192.168.1.100:/home/user/

# On target machine, extract
tar -xzf log-app.tar.gz
cd log-app
```

### Step 2: Build on Target Machine

```bash
# Setup environment
./setup-env.sh

# Build and start
docker compose up -d --build
```

---

## Method 3: Local Docker Registry

### Step 1: Start a Local Registry

```bash
# On a machine accessible to your network (e.g., 192.168.1.10)
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Test registry
curl http://192.168.1.10:5000/v2/_catalog
```

### Step 2: Tag and Push Images

```bash
# Build images
cd log-app
docker compose build

# Tag images with registry address
docker tag log-app-frontend:latest 192.168.1.10:5000/logapp-frontend:latest
docker tag log-app-backend:latest 192.168.1.10:5000/logapp-backend:latest

# Push to local registry
docker push 192.168.1.10:5000/logapp-frontend:latest
docker push 192.168.1.10:5000/logapp-backend:latest
```

### Step 3: Pull on Target Machines

```bash
# On any machine in the network
docker pull 192.168.1.10:5000/logapp-frontend:latest
docker pull 192.168.1.10:5000/logapp-backend:latest

# Run with docker compose (modify docker-compose.yml)
# Change image names to: 192.168.1.10:5000/logapp-frontend:latest
```

---

## Quick Commands Reference

### Build Commands
```bash
# Build all services
docker compose build

# Build with no cache (fresh build)
docker compose build --no-cache

# Build specific service
docker compose build frontend
docker compose build backend
```

### Image Management
```bash
# List all images
docker images

# Remove unused images
docker image prune

# Remove specific image
docker rmi log-app-frontend:latest

# Check image size
docker images log-app-frontend
```

### Save/Load Commands
```bash
# Save
docker save -o filename.tar image:tag

# Load
docker load -i filename.tar

# Save multiple images
docker save -o images.tar image1:tag1 image2:tag2

# Compress while saving
docker save image:tag | gzip > image.tar.gz

# Load compressed
gunzip -c image.tar.gz | docker load
```

---

## Example: Complete Workflow

### On Source Machine (Building Machine)

```bash
# 1. Navigate to project
cd /path/to/net2300/log-app

# 2. Build images
docker compose build

# 3. Save images to compressed file
docker save log-app-frontend:latest log-app-backend:latest mariadb:11.0 | gzip > logapp-images.tar.gz

# 4. Check file size
ls -lh logapp-images.tar.gz

# 5. Copy entire project and images
cd ..
tar -czf logapp-complete.tar.gz log-app/ log-app/logapp-images.tar.gz
```

### On Target Machine (Rocky Linux)

```bash
# 1. Receive and extract
tar -xzf logapp-complete.tar.gz
cd log-app

# 2. Load Docker images
gunzip -c logapp-images.tar.gz | docker load

# 3. Verify images
docker images

# 4. Setup environment
./setup-env.sh

# 5. Start application
docker compose up -d

# 6. Check status
docker compose ps
docker compose logs -f
```

---

## File Size Estimates

- Frontend image: ~200-300 MB
- Backend image: ~150-200 MB  
- MariaDB image: ~400-500 MB
- Total compressed: ~400-600 MB (with gzip)

---

## Troubleshooting

### Issue: "no such image" error
```bash
# List available images
docker images

# Check image names in docker-compose.yml
grep "image:" docker-compose.yml
```

### Issue: Images too large to transfer
```bash
# Save images separately
docker save -o frontend.tar log-app-frontend:latest
docker save -o backend.tar log-app-backend:latest

# Compress each
gzip frontend.tar
gzip backend.tar
```

### Issue: Cannot access local registry
```bash
# Check if registry is running
docker ps | grep registry

# Test connectivity
curl http://REGISTRY_IP:5000/v2/_catalog

# For insecure registry, add to /etc/docker/daemon.json:
{
  "insecure-registries": ["192.168.1.10:5000"]
}
# Then: sudo systemctl restart docker
```

---

## Security Notes

- **TAR files are not encrypted** - anyone with access can load them
- **Local registry** - Use HTTPS in production environments
- **Credentials** - Don't include passwords in images; use environment variables
- **Network transfer** - Use SCP or encrypted channels for sensitive data

---

## Next Steps

After images are loaded on target machine:
1. Run `./setup-env.sh` to configure IP address
2. Run `sudo ./open-ports.sh` to configure firewall
3. Run `docker compose up -d` to start services
4. Access frontend at `http://SERVER_IP:3000`
