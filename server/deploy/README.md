# BLEScanner Backend Deployment Guide

This guide covers deploying the BLEScanner backend to a DigitalOcean droplet.

## Prerequisites

- DigitalOcean account
- Domain name (optional, can use IP address)
- SSH access to your droplet

## Step 1: Create DigitalOcean Droplet

1. Log in to https://cloud.digitalocean.com/
2. Create a new Droplet:
   - **Image**: Ubuntu 22.04 LTS
   - **Plan**: Regular $6/month (1 CPU, 1GB RAM, 25GB SSD)
   - **Datacenter**: Choose closest to you
   - **Hostname**: `blescanner-api`
   - **Authentication**: SSH key (recommended) or password

3. Note your droplet's IP address

## Step 2: Initial Server Setup

SSH into your server:

```bash
ssh root@YOUR_SERVER_IP
```

Copy and run the setup script:

```bash
# Create a temporary directory
mkdir -p ~/setup
cd ~/setup

# Download or copy the setup script
# (You'll need to copy the contents of setup.sh to the server)

# Make it executable
chmod +x setup.sh

# Run it
./setup.sh
```

Or run commands manually:

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install Nginx
sudo apt install -y nginx

# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Install PM2
sudo npm install -g pm2

# Configure firewall
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# Create app directory
sudo mkdir -p /var/www/blescanner-backend
sudo chown -R $USER:$USER /var/www/blescanner-backend
```

## Step 3: Set Up PostgreSQL Database

Run the database setup script:

```bash
chmod +x setup-db.sh
./setup-db.sh
```

**IMPORTANT**: Save the database credentials that are printed. You'll need them for the `.env` file.

## Step 4: Deploy Application Code

### Option A: Clone from Git (Recommended)

```bash
cd /var/www
git clone https://github.com/YOUR_USERNAME/BLEScanner.git blescanner-backend
cd blescanner-backend/server
```

### Option B: Upload files manually

Use `scp` to copy files from your local machine:

```bash
# From your local machine
scp -r ~/Desktop/GitHub/BLEScanner/server root@YOUR_SERVER_IP:/var/www/blescanner-backend/
```

## Step 5: Configure Environment Variables

Create `.env` file on the server:

```bash
cd /var/www/blescanner-backend/server
nano .env
```

Add these variables (use the credentials from setup-db.sh):

```bash
# Server
NODE_ENV=production
PORT=3000

# Database (use credentials from setup-db.sh)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=blescanner
DB_USER=blescanner_user
DB_PASSWORD=YOUR_GENERATED_PASSWORD_HERE

# JWT (generate a new secret)
JWT_SECRET=$(openssl rand -base64 32)
JWT_EXPIRATION=30d

# APNs
APNS_KEY_ID=X859SFN76P
APNS_TEAM_ID=NV97R9Q8MF
APNS_TOPIC=com.prishajain.blescanner
APNS_KEY_PATH=/var/www/blescanner-backend/server/config/AuthKey_X859SFN76P.p8
APNS_PRODUCTION=true
```

Save and exit (Ctrl+X, Y, Enter).

## Step 6: Copy APNs Key

Copy your `.p8` file to the server:

```bash
# From your local machine
scp ~/Desktop/GitHub/BLEScanner/server/config/AuthKey_X859SFN76P.p8 root@YOUR_SERVER_IP:/var/www/blescanner-backend/server/config/
```

## Step 7: Install Dependencies and Run Migrations

```bash
cd /var/www/blescanner-backend/server

# Install dependencies
npm install --production

# Run database migrations
source .env
PGPASSWORD=$DB_PASSWORD psql -h localhost -U blescanner_user -d blescanner -f db/schema.sql
```

## Step 8: Configure Nginx

Create Nginx configuration:

```bash
sudo nano /etc/nginx/sites-available/blescanner
```

Paste this configuration (replace YOUR_DOMAIN_OR_IP):

```nginx
server {
    listen 80;
    server_name YOUR_DOMAIN_OR_IP;

    client_max_body_size 10M;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/blescanner /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Step 9: Start Application with PM2

```bash
cd /var/www/blescanner-backend/server
pm2 start index.js --name blescanner-backend
pm2 save
pm2 startup
```

Copy and run the command that PM2 outputs.

## Step 10: Set Up SSL (If Using Domain)

If you have a domain name:

```bash
sudo certbot --nginx -d your-domain.com
```

Follow the prompts and choose to redirect HTTP to HTTPS.

## Step 11: Test the API

```bash
# Health check
curl http://YOUR_SERVER_IP/api/health

# Register a test user
curl -X POST http://YOUR_SERVER_IP/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"testpass123"}'
```

## Step 12: Update iOS App

Update `BLEScanner/Utilities/APIConstants.swift`:

```swift
struct APIConfig {
    #if DEBUG
    static let baseURL = "http://YOUR_SERVER_IP/api"
    // Or if using domain with SSL:
    // static let baseURL = "https://your-domain.com/api"
    #else
    static let baseURL = "https://your-domain.com/api"
    #endif

    static let timeout: TimeInterval = 30
}
```

## Useful PM2 Commands

```bash
pm2 status                    # Check status
pm2 logs blescanner-backend   # View logs
pm2 restart blescanner-backend # Restart app
pm2 stop blescanner-backend   # Stop app
pm2 delete blescanner-backend # Remove from PM2
```

## Updating the Application

When you make changes:

```bash
cd /var/www/blescanner-backend
git pull origin main          # Pull latest changes
cd server
npm install --production      # Install new dependencies
pm2 restart blescanner-backend # Restart app
```

Or use the deploy.sh script:

```bash
chmod +x deploy/deploy.sh
./deploy/deploy.sh
```

## Troubleshooting

**Can't connect to server:**
- Check firewall: `sudo ufw status`
- Check Nginx: `sudo systemctl status nginx`
- Check application: `pm2 logs blescanner-backend`

**Database errors:**
- Check PostgreSQL: `sudo systemctl status postgresql`
- Check credentials in `.env`
- Test connection: `psql -U blescanner_user -d blescanner`

**Push notifications not working:**
- Verify APNs key path is correct
- Check `.p8` file permissions
- View logs: `pm2 logs blescanner-backend`
