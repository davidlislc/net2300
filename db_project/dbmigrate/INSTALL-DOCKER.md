# Docker and Node.js Installation Scripts for Rocky Linux

This directory contains scripts to install Docker, Docker Compose, and Node.js on Rocky Linux.

## Quick Installation

### Automated Script (Recommended)

Run the full installation script:

```bash
sudo ./install-docker-rocky.sh
```

**Installation Options:**
1. **Full Installation** (Docker + Docker Compose + Node.js) - Default
2. **Docker Only** (Docker + Docker Compose)
3. **Node.js Only** (Node.js 18.x LTS + npm)

This script will:
- ✅ Remove old Docker installations
- ✅ Install Docker CE and Docker Compose plugin
- ✅ Install Node.js 18.x LTS and npm
- ✅ Configure Docker to start on boot
- ✅ Configure firewall rules
- ✅ Optionally add your user to docker group
- ✅ Optionally install global npm packages (yarn, pm2)
- ✅ Test the installation

### Manual Docker Installation

If you prefer a quick manual installation:

```bash
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo && \
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin && \
sudo systemctl start docker && \
sudo systemctl enable docker && \
docker --version && \
docker compose version
```

### Manual Node.js Installation

Install Node.js 18.x LTS:

```bash
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo dnf install -y nodejs
node --version
npm --version
```

Install global packages (optional):
```bash
sudo npm install -g yarn pm2
```

### Add User to Docker Group

To run Docker without sudo:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Or log out and log back in.

## Verification

### Automated Verification

Run the verification script:
```bash
./verify-docker.sh
```

This will check:
- ✅ Docker command availability
- ✅ Docker Compose plugin
- ✅ Docker daemon status
- ✅ Auto-start configuration
- ✅ Non-sudo access
- ✅ Container execution
- ✅ Node.js installation (optional)
- ✅ npm installation (optional)

### Manual Tests

Test Docker:
```bash
docker run hello-world
```

Test Docker Compose:
```bash
docker compose version
```

Test Node.js:
```bash
node --version
npm --version
```

## Troubleshooting

### Check Docker status
```bash
sudo systemctl status docker
```

### View Docker logs
```bash
sudo journalctl -u docker.service
```

### Restart Docker
```bash
sudo systemctl restart docker
```

### Check firewall
```bash
sudo firewall-cmd --list-all
```

### Permission denied error
If you get "permission denied" when running docker commands:
```bash
# Verify docker group exists
getent group docker

# Check if user is in docker group
groups $USER

# If not in group, add and reload:
sudo usermod -aG docker $USER
newgrp docker
```

## Uninstall

### Uninstall Docker

If you need to remove Docker:

```bash
# Stop Docker service
sudo systemctl stop docker

# Remove Docker packages
sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Remove Docker data (WARNING: This deletes all containers, images, volumes)
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

### Uninstall Node.js

If you need to remove Node.js:

```bash
# Remove Node.js and npm
sudo dnf remove -y nodejs npm

# Remove NodeSource repository
sudo rm -f /etc/yum.repos.d/nodesource*.repo

# Clean dnf cache
sudo dnf clean all
```

## Post-Installation Configuration

### Configure Docker to use different data directory
Edit `/etc/docker/daemon.json`:
```json
{
  "data-root": "/new/path/to/docker"
}
```

Then restart Docker:
```bash
sudo systemctl restart docker
```

### Configure npm global packages location (avoid sudo)

Create npm global directory:
```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
```

Add to ~/.bashrc:
```bash
export PATH=~/.npm-global/bin:$PATH
```

Reload:
```bash
source ~/.bashrc
```

Now you can install global packages without sudo:
```bash
npm install -g yarn pm2
```

## Additional Resources

### Limit Docker log size
Edit `/etc/docker/daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Rocky Linux Documentation](https://docs.rockylinux.org/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Node.js Documentation](https://nodejs.org/docs/)
- [npm Documentation](https://docs.npmjs.com/)
