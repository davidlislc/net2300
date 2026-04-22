# Node.js in Docker Configuration

This document explains how Node.js is used in the Docker containers for this application.

## Overview

This application uses Node.js in two Docker containers:

1. **Backend Container**: Runs Node.js application (Express API)
2. **Frontend Container**: Uses Node.js to build React app (build stage only)

## Backend Container (Node.js Runtime)

### Dockerfile: `backend/Dockerfile`

```dockerfile
FROM node:18-alpine
```

**What it includes:**
- Node.js v18.x LTS (Long Term Support)
- npm (Node Package Manager)
- Alpine Linux (minimal, ~5MB base image)

### Key Features

#### 1. Multi-stage Build Pattern
```dockerfile
# Copy package files first
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .
```

**Benefits:**
- Better Docker layer caching
- Faster rebuilds when only code changes
- Smaller image size (production dependencies only)

#### 2. Security Hardening
```dockerfile
# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Run as non-root
USER nodejs
```

**Why?**
- Prevents privilege escalation
- Follows Docker security best practices
- Limits potential damage from vulnerabilities

#### 3. Health Checks
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD node -e "require('http').get('http://localhost:5000/api/health', ...)"
```

**Purpose:**
- Docker monitors container health
- Automatic restart if unhealthy
- Load balancer integration

## Frontend Container (Node.js Build Only)

### Dockerfile: `frontend/Dockerfile`

Uses **multi-stage build**:

#### Stage 1: Build (Node.js)
```dockerfile
FROM node:18-alpine AS build

# Install dependencies and build
RUN npm ci
RUN npm run build
```

#### Stage 2: Production (Apache)
```dockerfile
FROM httpd:2.4-alpine

# Copy built files from stage 1
COPY --from=build /app/build /usr/local/apache2/htdocs/
```

**Result:**
- Final image does NOT contain Node.js
- Only contains compiled static files + Apache
- Much smaller image size (~20MB vs ~150MB)

## Node.js Version Management

### Why Node.js 18?

- **LTS (Long Term Support)**: Supported until April 2025
- **Stable**: Production-ready with security updates
- **Modern Features**: ES modules, fetch API, etc.
- **Performance**: V8 engine improvements

### Upgrading Node.js Version

To upgrade to Node.js 20 (next LTS):

**Backend:**
```dockerfile
FROM node:20-alpine
```

**Frontend:**
```dockerfile
FROM node:20-alpine AS build
```

Then rebuild:
```bash
docker compose build --no-cache
```

## Package Management

### npm install vs npm ci

This project uses `npm install`:

```dockerfile
RUN npm install --production
```

**Why `npm install` instead of `npm ci`?**
- Works without package-lock.json
- More flexible for development
- Automatically resolves dependency versions

**Note:** For production environments, consider:
1. Generate package-lock.json: `npm install` (locally)
2. Commit package-lock.json to version control
3. Update Dockerfile to use `npm ci --only=production`

**Benefits of `npm ci` (when package-lock.json exists):**
- Faster installation
- Reproducible builds
- Removes node_modules before install
- Better for CI/CD pipelines

### Dependencies

**Backend** (`backend/package.json`):
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.5",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1"
  }
}
```

**Frontend** (`frontend/package.json`):
```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1"
  }
}
```

## Development vs Production

### Development Mode

**With hot-reload** (using docker-compose.override.yml):

```yaml
backend:
  volumes:
    - ./backend:/app
    - /app/node_modules
  command: npm run dev
```

**Benefits:**
- Code changes reflect immediately
- No rebuild needed
- Uses nodemon for auto-restart

### Production Mode

**Optimized build** (default docker-compose.yml):

```yaml
backend:
  environment:
    NODE_ENV: production
  command: node server.js
```

**Benefits:**
- Faster startup
- Smaller memory footprint
- No dev dependencies

## Troubleshooting

### Node version mismatch

**Problem:** Different Node versions on host vs container

**Solution:**
```bash
# Check container version
docker compose exec backend node --version

# Should match package.json engines field
```

### node_modules permission errors

**Problem:** Permission denied accessing node_modules

**Solution:**
```bash
# Remove local node_modules
rm -rf backend/node_modules frontend/node_modules

# Rebuild containers
docker compose build --no-cache
```

### npm install fails

**Problem:** Package installation fails in Dockerfile

**Solution:**
```dockerfile
# Add build dependencies if needed
RUN apk add --no-cache python3 make g++
```

### Container keeps restarting

**Check logs:**
```bash
docker compose logs backend
```

**Common issues:**
- Missing environment variables
- Database connection failure
- Port already in use

## Performance Optimization

### 1. Layer Caching

```dockerfile
# Good: Copy package.json first
COPY package*.json ./
RUN npm ci

# Then copy source code
COPY . .
```

**Why?** Dependencies rarely change, code changes often.

### 2. Multi-stage Builds

Frontend uses multi-stage to reduce final image size:
- Build stage: ~150MB (Node.js + build tools)
- Final stage: ~20MB (Apache + static files)

### 3. Alpine Linux

```dockerfile
FROM node:18-alpine  # ~40MB
# vs
FROM node:18         # ~900MB
```

**Savings:** ~95% smaller base image

### 4. Production Dependencies Only

```dockerfile
RUN npm install --production
```

**Result:** Excludes devDependencies like testing tools

## Security Best Practices

### 1. Non-root User

```dockerfile
USER nodejs
```

Never run as root in production.

### 2. Vulnerability Scanning

```bash
# Scan for vulnerabilities
docker scout cves logapp-backend
docker scout cves logapp-frontend
```

### 3. Regular Updates

```bash
# Update base images
docker compose pull
docker compose build --no-cache
```

### 4. Secrets Management

**Never hardcode:**
```dockerfile
ENV DB_PASSWORD=password123  # ❌ Bad
```

**Use environment variables:**
```yaml
environment:
  DB_PASSWORD: ${DB_PASSWORD}  # ✓ Good
```

## Monitoring

### Check Node.js Process

```bash
# Backend container
docker compose exec backend ps aux
docker compose exec backend node --version
docker compose exec backend npm list
```

### Memory Usage

```bash
# View container stats
docker compose stats backend

# Inside container
docker compose exec backend node -e "console.log(process.memoryUsage())"
```

### CPU Usage

```bash
# Set CPU limits in docker-compose.yml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
```

## Advanced Configuration

### Custom npm Registry

```dockerfile
RUN npm config set registry https://registry.npmjs.org/
```

### Offline Installation

```dockerfile
# Copy node_modules from local
COPY node_modules ./node_modules
```

### Build Arguments

```dockerfile
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine
```

Build with:
```bash
docker compose build --build-arg NODE_VERSION=20
```

## Resources

- [Node.js Docker Best Practices](https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md)
- [Official Node.js Docker Images](https://hub.docker.com/_/node)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
