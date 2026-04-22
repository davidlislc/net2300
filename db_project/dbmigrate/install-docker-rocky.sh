#!/bin/bash

################################################################################
# Docker and Docker Compose Installation Script for Rocky Linux
# 
# This script will:
# - Install Docker CE (Community Edition)
# - Install Docker Compose plugin
# - Configure Docker to start on boot
# - Configure firewall for Docker and application ports
# - Optionally add current user to docker group
#
# Usage: sudo ./install-docker-rocky.sh
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root or with sudo"
    exit 1
fi

print_info "Starting Docker and Docker Compose installation on Rocky Linux..."

# Check Rocky Linux version
if [ -f /etc/redhat-release ]; then
    OS_VERSION=$(cat /etc/redhat-release)
    print_info "Detected: $OS_VERSION"
else
    print_error "This script is designed for Rocky Linux"
    exit 1
fi

echo ""

################################################################################
# DOCKER INSTALLATION
################################################################################

# Step 1: Remove old Docker installations if any
print_info "Removing old Docker installations (if any)..."
dnf remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine \
    podman \
    runc 2>/dev/null || true

# Step 2: Install required packages
print_info "Installing required packages..."
dnf install -y dnf-plugins-core

# Step 3: Add Docker repository
print_info "Adding Docker CE repository..."
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Step 4: Install Docker Engine
print_info "Installing Docker CE, Docker CLI, and containerd..."
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 5: Start and enable Docker service
print_info "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Step 6: Verify Docker installation
print_info "Verifying Docker installation..."
if docker --version; then
    print_info "Docker installed successfully: $(docker --version)"
else
    print_error "Docker installation failed"
    exit 1
fi

# Step 7: Verify Docker Compose installation
print_info "Verifying Docker Compose installation..."
if docker compose version; then
    print_info "Docker Compose installed successfully: $(docker compose version)"
else
    print_error "Docker Compose installation failed"
    exit 1
fi

# Step 8: Test Docker with hello-world
print_info "Testing Docker with hello-world container..."
if docker run --rm hello-world > /dev/null 2>&1; then
    print_info "Docker is working correctly!"
else
    print_warn "Docker test failed, but installation completed"
fi

# Step 9: Configure firewall (if firewalld is running)
if systemctl is-active --quiet firewalld; then
        print_info "Configuring firewall for Docker..."
        firewall-cmd --permanent --zone=trusted --add-interface=docker0 2>/dev/null || true
        firewall-cmd --permanent --zone=public --add-masquerade 2>/dev/null || true
        firewall-cmd --permanent --zone=docker --change-interface=docker0 2>/dev/null || true
        firewall-cmd --reload
        print_info "Firewall configured for Docker"
        
        # Ask about opening application ports
        echo ""
        print_warn "Application Ports Configuration"
        read -p "Open ports for the log application (3000, 5000, 3306, 8080)? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Opening port 3000 (Frontend - React App)..."
            firewall-cmd --permanent --add-port=3000/tcp
            
            print_info "Opening port 5000 (Backend - API)..."
            firewall-cmd --permanent --add-port=5000/tcp
            
            print_info "Opening port 3306 (MariaDB)..."
            firewall-cmd --permanent --add-port=3306/tcp
            
            print_info "Opening port 8080 (phpMyAdmin)..."
            firewall-cmd --permanent --add-port=8080/tcp
            
            # Ask about HTTP/HTTPS ports
            read -p "Also open HTTP (80) and HTTPS (443) ports? [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "Opening port 80 (HTTP)..."
                firewall-cmd --permanent --add-service=http
                
                print_info "Opening port 443 (HTTPS)..."
                firewall-cmd --permanent --add-service=https
            fi
            
            # Reload firewall to apply changes
            firewall-cmd --reload
            print_info "Application ports configured successfully!"
            
            # Display opened ports
            echo ""
            print_info "Current firewall configuration:"
            firewall-cmd --list-all | grep -E "(ports|services)"
        fi
    fi

# Step 10: Ask to add user to docker group
echo ""
print_warn "To run Docker without sudo, add your user to the docker group"
read -p "Add current user ($SUDO_USER) to docker group? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker "$SUDO_USER"
        print_info "User $SUDO_USER added to docker group"
        print_warn "Please log out and log back in for group changes to take effect"
        print_warn "Or run: newgrp docker"
    else
        print_warn "Could not detect user. Run manually: sudo usermod -aG docker \$USER"
    fi
fi

# Display summary
echo ""
print_info "================================"
print_info "Installation Complete!"
print_info "================================"
echo ""
echo "Docker version:         $(docker --version 2>/dev/null || echo 'Not installed')"
echo "Docker Compose version: $(docker compose version 2>/dev/null || echo 'Not installed')"
echo ""

print_info "Next Steps:"
echo "  1. Log out and log back in (if user was added to docker group)"
echo "  2. Test Docker: docker run hello-world"
echo "  3. Test Docker Compose: docker compose version"
echo "  4. Deploy the application: cd log-app && docker compose up -d"
echo ""

print_info "Docker Commands:"
echo "  - Check Docker status:      sudo systemctl status docker"
echo "  - Start Docker:             sudo systemctl start docker"
echo "  - Stop Docker:              sudo systemctl stop docker"
echo "  - Docker info:              docker info"
echo "  - View running containers:  docker ps"
echo "  - View logs:                docker compose logs -f"
echo ""

print_info "Documentation:"
echo "  - Docker:   https://docs.docker.com/"
echo "  - Compose:  https://docs.docker.com/compose/"
echo ""

print_info "Note: Node.js is NOT installed on the host system."
print_info "The application will run Node.js inside Docker containers."
echo ""

exit 0
