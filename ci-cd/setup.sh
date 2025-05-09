#!/bin/bash

# setup.sh - Install required dependencies for Interactive Map backend
# This script installs Docker, Docker Compose, and other necessary tools
# To be placed in the ci-cd directory and run manually

set -e  # Exit immediately if a command exits with non-zero status

echo "===== Installing dependencies for Interactive Map Backend ====="

# Update package repository
echo "Updating system packages..."
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    openssl

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    echo "Docker installed successfully"
else
    echo "Docker is already installed"
fi

# Add current user to docker group to run docker without sudo
echo "Adding user to docker group..."
sudo usermod -aG docker $USER
# Create docker group if it doesn't exist (rare case)
sudo groupadd -f docker
# Set permissions for docker socket
sudo chmod 666 /var/run/docker.sock
echo "User added to docker group and permissions set"

# Install Docker Compose
echo "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -SL https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose is already installed"
fi

# Make run.sh executable
if [ -f "run.sh" ]; then
    chmod +x run.sh
    echo "Made run.sh executable"
fi

echo ""
echo "===== Installation Complete ====="
echo "All necessary tools have been installed."
echo ""
echo "IMPORTANT: For Docker permission changes to take effect, you need to either:"
echo "  1. Log out and log back in, or"
echo "  2. Run the following command: newgrp docker"
echo ""
echo "Once completed, you can run the application with: ./run.sh"
echo ""

# Use newgrp to apply docker group to current session without requiring logout
echo "Attempting to update group membership for current session..."
exec newgrp docker << EOF
echo "Docker group permissions applied to current session."
echo "You can now run docker commands without sudo."
EOF
