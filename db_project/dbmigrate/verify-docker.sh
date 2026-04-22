#!/bin/bash

################################################################################
# Docker and Node.js Installation Verification Script
# 
# This script verifies that Docker, Docker Compose, and Node.js are properly
# installed and working on Rocky Linux
#
# Usage: ./verify-docker.sh
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

PASSED=0
FAILED=0

echo "========================================"
echo "Docker & Node.js Verification"
echo "========================================"
echo ""

# Check if Docker is installed
print_info "Checking Docker installation..."
if command -v docker &> /dev/null; then
    print_pass "Docker command found"
    echo "   Version: $(docker --version)"
    ((PASSED++))
else
    print_fail "Docker command not found"
    ((FAILED++))
fi
echo ""

# Check if Docker Compose is installed
print_info "Checking Docker Compose installation..."
if docker compose version &> /dev/null; then
    print_pass "Docker Compose plugin found"
    echo "   Version: $(docker compose version)"
    ((PASSED++))
else
    print_fail "Docker Compose plugin not found"
    ((FAILED++))
fi
echo ""

# Check if Docker daemon is running
print_info "Checking Docker daemon status..."
if systemctl is-active --quiet docker; then
    print_pass "Docker daemon is running"
    ((PASSED++))
else
    print_fail "Docker daemon is not running"
    echo "   Try: sudo systemctl start docker"
    ((FAILED++))
fi
echo ""

# Check if Docker is enabled on boot
print_info "Checking Docker auto-start configuration..."
if systemctl is-enabled --quiet docker; then
    print_pass "Docker is enabled to start on boot"
    ((PASSED++))
else
    print_fail "Docker is not enabled on boot"
    echo "   Try: sudo systemctl enable docker"
    ((FAILED++))
fi
echo ""

# Check if user can run Docker without sudo
print_info "Checking Docker permissions (non-sudo access)..."
if docker ps &> /dev/null; then
    print_pass "User can run Docker commands without sudo"
    ((PASSED++))
else
    print_fail "User cannot run Docker without sudo"
    echo "   Try: sudo usermod -aG docker \$USER && newgrp docker"
    ((FAILED++))
fi
echo ""

# Try to run hello-world container
print_info "Testing Docker functionality..."
if docker run --rm hello-world &> /dev/null; then
    print_pass "Docker can run containers successfully"
    ((PASSED++))
else
    print_fail "Docker cannot run containers"
    echo "   Check Docker logs: sudo journalctl -u docker.service"
    ((FAILED++))
fi
echo ""

# Check Docker info
print_info "Docker system information:"
docker info 2>/dev/null | grep -E "Server Version|Storage Driver|Cgroup Driver|Cgroup Version" || echo "   (Docker not accessible)"
echo ""

# Check if Node.js is installed
print_info "Checking Node.js installation..."
if command -v node &> /dev/null; then
    print_pass "Node.js command found"
    echo "   Version: $(node --version)"
    ((PASSED++))
else
    print_fail "Node.js command not found"
    echo "   (Optional - run install script to install Node.js)"
    # Don't increment FAILED for optional component
fi
echo ""

# Check if npm is installed
print_info "Checking npm installation..."
if command -v npm &> /dev/null; then
    print_pass "npm command found"
    echo "   Version: $(npm --version)"
    ((PASSED++))
else
    print_fail "npm command not found"
    echo "   (Optional - run install script to install npm)"
    # Don't increment FAILED for optional component
fi
echo ""

# Summary
echo "========================================"
echo "Verification Summary"
echo "========================================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    print_pass "All checks passed! Docker is ready to use."
    exit 0
else
    print_fail "Some checks failed. Please review the output above."
    exit 1
fi
