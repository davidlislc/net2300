#!/bin/bash

################################################################################
# Docker Image Export Script
# 
# This script will:
# - Build all Docker images
# - Save images to TAR files
# - Create a compressed archive for easy sharing
#
# Usage: ./export-images.sh
################################################################################

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Docker Image Export Script${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Step 1: Build images
echo -e "${GREEN}Step 1: Building Docker images...${NC}"
docker compose build
echo -e "${GREEN}✓ Images built successfully${NC}"
echo ""

# Step 2: Create export directory
EXPORT_DIR="docker-images-export"
rm -rf $EXPORT_DIR
mkdir -p $EXPORT_DIR

echo -e "${GREEN}Step 2: Saving images to TAR files...${NC}"

# Get image names from docker-compose
FRONTEND_IMAGE=$(docker compose config | grep -A 5 "frontend:" | grep "image:" | awk '{print $2}')
BACKEND_IMAGE=$(docker compose config | grep -A 5 "backend:" | grep "image:" | awk '{print $2}')

# If images are built (not using image: directly), get the project name
if [ -z "$FRONTEND_IMAGE" ]; then
    PROJECT_NAME=$(basename $(pwd))
    FRONTEND_IMAGE="${PROJECT_NAME}-frontend"
    BACKEND_IMAGE="${PROJECT_NAME}-backend"
fi

echo "Frontend image: $FRONTEND_IMAGE"
echo "Backend image: $BACKEND_IMAGE"
echo ""

# Save frontend image
echo "Saving frontend image..."
docker save -o $EXPORT_DIR/frontend.tar $FRONTEND_IMAGE 2>/dev/null || \
    docker save -o $EXPORT_DIR/frontend.tar log-app-frontend:latest
echo -e "${GREEN}✓ Frontend image saved${NC}"

# Save backend image
echo "Saving backend image..."
docker save -o $EXPORT_DIR/backend.tar $BACKEND_IMAGE 2>/dev/null || \
    docker save -o $EXPORT_DIR/backend.tar log-app-backend:latest
echo -e "${GREEN}✓ Backend image saved${NC}"

# Save MariaDB image
echo "Saving MariaDB image..."
docker pull mariadb:11.0 > /dev/null 2>&1
docker save -o $EXPORT_DIR/mariadb.tar mariadb:11.0
echo -e "${GREEN}✓ MariaDB image saved${NC}"
echo ""

# Step 3: Copy necessary files
echo -e "${GREEN}Step 3: Copying configuration files...${NC}"
cp docker-compose.yml $EXPORT_DIR/
cp .env.example $EXPORT_DIR/
cp setup-env.sh $EXPORT_DIR/
cp open-ports.sh $EXPORT_DIR/ 2>/dev/null || true
cp install-docker-rocky.sh $EXPORT_DIR/ 2>/dev/null || true
cp README.md $EXPORT_DIR/
cp DOCKER-SHARE.md $EXPORT_DIR/
echo -e "${GREEN}✓ Configuration files copied${NC}"
echo ""

# Step 4: Create load script
echo -e "${GREEN}Step 4: Creating load script...${NC}"
cat > $EXPORT_DIR/load-images.sh << 'EOF'
#!/bin/bash

# Docker Image Load Script
# This script loads Docker images from TAR files

set -e

GREEN='\033[0;32m'
NC='\033[0m'

echo "Loading Docker images..."
echo ""

echo "Loading frontend image..."
docker load -i frontend.tar
echo -e "${GREEN}✓ Frontend image loaded${NC}"

echo "Loading backend image..."
docker load -i backend.tar
echo -e "${GREEN}✓ Backend image loaded${NC}"

echo "Loading MariaDB image..."
docker load -i mariadb.tar
echo -e "${GREEN}✓ MariaDB image loaded${NC}"

echo ""
echo "Verifying loaded images..."
docker images | grep -E "log-app|mariadb"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Images loaded successfully!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Run: ./setup-env.sh"
echo "  2. Run: docker compose up -d"
echo "  3. Access: http://YOUR_IP:3000"
echo ""
EOF

chmod +x $EXPORT_DIR/load-images.sh
chmod +x $EXPORT_DIR/setup-env.sh
chmod +x $EXPORT_DIR/open-ports.sh 2>/dev/null || true
chmod +x $EXPORT_DIR/install-docker-rocky.sh 2>/dev/null || true
echo -e "${GREEN}✓ Load script created${NC}"
echo ""

# Step 5: Create README for export
cat > $EXPORT_DIR/IMPORT-INSTRUCTIONS.md << 'EOF'
# Docker Images Import Instructions

## Quick Start

### 1. Load Docker Images
```bash
chmod +x load-images.sh
./load-images.sh
```

### 2. Configure Environment
```bash
chmod +x setup-env.sh
./setup-env.sh
```

### 3. Start Application
```bash
docker compose up -d
```

### 4. Check Status
```bash
docker compose ps
docker compose logs -f
```

### 5. Access Application
- Frontend: http://YOUR_IP:3000
- Backend API: http://YOUR_IP:5000/api/health
- Database: localhost:3306

## For Rocky Linux Users

### Install Docker First (if needed)
```bash
chmod +x install-docker-rocky.sh
sudo ./install-docker-rocky.sh
```

### Open Firewall Ports
```bash
chmod +x open-ports.sh
sudo ./open-ports.sh
```

## Troubleshooting

### Check if images are loaded
```bash
docker images
```

### Check if services are running
```bash
docker compose ps
docker compose logs -f
```

### Restart services
```bash
docker compose down
docker compose up -d
```

See DOCKER-SHARE.md for more details.
EOF

# Step 6: Display file sizes
echo -e "${GREEN}Step 5: Checking file sizes...${NC}"
echo ""
ls -lh $EXPORT_DIR/*.tar | awk '{print $9, "-", $5}'
echo ""

# Step 7: Create compressed archive
echo -e "${GREEN}Step 6: Creating compressed archive...${NC}"
ARCHIVE_NAME="logapp-docker-images-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf $ARCHIVE_NAME $EXPORT_DIR/
echo -e "${GREEN}✓ Archive created: $ARCHIVE_NAME${NC}"
echo ""

# Display final summary
ARCHIVE_SIZE=$(ls -lh $ARCHIVE_NAME | awk '{print $5}')
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Export Complete!${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "Archive created: $ARCHIVE_NAME"
echo "Archive size: $ARCHIVE_SIZE"
echo ""
echo "Contents:"
echo "  - frontend.tar (Frontend React app)"
echo "  - backend.tar (Backend Express API)"
echo "  - mariadb.tar (MariaDB database)"
echo "  - docker-compose.yml"
echo "  - Configuration files and scripts"
echo "  - Documentation"
echo ""
echo -e "${YELLOW}To share with others:${NC}"
echo "  1. Transfer $ARCHIVE_NAME to target machine"
echo "  2. Extract: tar -xzf $ARCHIVE_NAME"
echo "  3. Run: cd $EXPORT_DIR && ./load-images.sh"
echo "  4. Run: ./setup-env.sh"
echo "  5. Run: docker compose up -d"
echo ""
echo -e "${GREEN}Directory with individual files: $EXPORT_DIR/${NC}"
echo ""

exit 0
