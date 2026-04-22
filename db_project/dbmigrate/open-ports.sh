#!/bin/bash

################################################################################
# Open Firewall Ports for Log Application on Rocky Linux
# 
# This script will:
# - Open port 3000 (Frontend - React App)
# - Open port 5000 (Backend - API)
# - Open port 3306 (MariaDB)
# - Open port 8080 (phpMyAdmin)
# - Configure firewalld rules
#
# Usage: sudo ./open-ports.sh
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

print_info "Opening firewall ports for Log Application..."

# Check if firewalld is installed and running
if ! systemctl is-active --quiet firewalld; then
    print_warn "firewalld is not running"
    read -p "Do you want to start firewalld? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl start firewalld
        systemctl enable firewalld
        print_info "firewalld started and enabled"
    else
        print_error "firewalld is required for this script"
        exit 1
    fi
fi

# Open port 3000 (Frontend)
print_info "Opening port 3000 (Frontend - React App)..."
firewall-cmd --permanent --add-port=3000/tcp
if [ $? -eq 0 ]; then
    print_info "✓ Port 3000 opened"
else
    print_error "Failed to open port 3000"
fi

# Open port 5000 (Backend API)
print_info "Opening port 5000 (Backend - API)..."
firewall-cmd --permanent --add-port=5000/tcp
if [ $? -eq 0 ]; then
    print_info "✓ Port 5000 opened"
else
    print_error "Failed to open port 5000"
fi

# Open port 3306 (MariaDB)
print_info "Opening port 3306 (MariaDB)..."
firewall-cmd --permanent --add-port=3306/tcp
if [ $? -eq 0 ]; then
    print_info "✓ Port 3306 opened"
else
    print_error "Failed to open port 3306"
fi

# Open port 8080 (phpMyAdmin)
print_info "Opening port 8080 (phpMyAdmin)..."
firewall-cmd --permanent --add-port=8080/tcp
if [ $? -eq 0 ]; then
    print_info "✓ Port 8080 opened"
else
    print_error "Failed to open port 8080"
fi

# Ask about HTTP/HTTPS ports
echo ""
read -p "Also open HTTP (80) and HTTPS (443) ports? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    print_info "✓ HTTP (80) and HTTPS (443) opened"
fi

# Reload firewall to apply changes
print_info "Reloading firewall..."
firewall-cmd --reload

# Display current firewall configuration
echo ""
print_info "================================"
print_info "Firewall Configuration"
print_info "================================"
echo ""
firewall-cmd --list-all

echo ""
print_info "================================"
print_info "Ports Opened Successfully!"
print_info "================================"
echo ""
print_info "You can now access:"
echo "  - Frontend:    http://$(hostname -I | awk '{print $1}'):3000"
echo "  - Backend API: http://$(hostname -I | awk '{print $1}'):5000"
echo "  - phpMyAdmin:  http://$(hostname -I | awk '{print $1}'):8080"
echo "  - API Health:  http://$(hostname -I | awk '{print $1}'):5000/api/health"
echo ""
print_info "Useful Commands:"
echo "  - View firewall status:  sudo firewall-cmd --list-all"
echo "  - Close a port:          sudo firewall-cmd --permanent --remove-port=5000/tcp"
echo "  - Reload firewall:       sudo firewall-cmd --reload"
echo "  - Check open ports:      sudo ss -tuln | grep LISTEN"
echo ""

exit 0
