#!/bin/bash

# BLEScanner Backend Server Setup Script
# Run this on a fresh Ubuntu 22.04 server

set -e  # Exit on any error

echo "======================================"
echo "BLEScanner Backend Server Setup"
echo "======================================"

# Update system packages
echo ""
echo "[1/8] Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install Node.js 18
echo ""
echo "[2/8] Installing Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify Node.js installation
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

# Install PostgreSQL
echo ""
echo "[3/8] Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

echo "PostgreSQL installed and started"

# Install Nginx
echo ""
echo "[4/8] Installing Nginx..."
sudo apt install -y nginx

# Start Nginx service
sudo systemctl start nginx
sudo systemctl enable nginx

echo "Nginx installed and started"

# Install Certbot for SSL (Let's Encrypt)
echo ""
echo "[5/8] Installing Certbot..."
sudo apt install -y certbot python3-certbot-nginx

# Install PM2 globally
echo ""
echo "[6/8] Installing PM2..."
sudo npm install -g pm2

# Set up firewall
echo ""
echo "[7/8] Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

echo "Firewall configured"

# Create application directory
echo ""
echo "[8/8] Creating application directory..."
sudo mkdir -p /var/www/blescanner-backend
sudo chown -R $USER:$USER /var/www/blescanner-backend

echo ""
echo "======================================"
echo "✓ Server setup complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Set up PostgreSQL database (run setup-db.sh)"
echo "2. Clone your repository to /var/www/blescanner-backend"
echo "3. Configure environment variables"
echo "4. Deploy the application"
echo ""
