#!/bin/bash

# Docker installation script
# Source: https://docs.docker.com/engine/install/ubuntu/
# Applicable for:
# - Ubuntu Oracular 24.10
# - Ubuntu Noble 24.04 (LTS)
# - Ubuntu Jammy 22.04 (LTS)
# - Ubuntu Focal 20.04 (LTS)

# Update the package index
sudo apt-get update

# Install necessary dependencies
sudo apt-get install -y ca-certificates curl

# Create a keyring directory and add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package index again
sudo apt-get update

# Install Docker and its related components
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker and enable it to start on boot
sudo systemctl start docker
sudo systemctl enable docker

# Verify that Docker is installed successfully
docker --version

# Check if the current user is not root
if [ "$(id -u)" -ne 0 ]; then
    CURRENT_USER=$(whoami)
    echo "To run Docker commands without sudo, add the current user to the Docker group:"
    echo "sudo usermod -aG docker $CURRENT_USER"
fi
