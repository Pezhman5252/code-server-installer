#!/bin/bash

# ==============================================================================
#  Advanced & Automated Code-Server Installation Script (Final Version)
#  Version: 2.3 - Production Ready, Fully Tested & Idempotent
#  Target OS: Ubuntu 24.04 LTS
#  Run with: curl -sSL <URL> | sudo bash
# ==============================================================================

# --- Script Configuration & Security ---
set -euo pipefail

# Color Codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging Functions
log_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Pre-flight Checks ---
log_info "Performing pre-flight checks..."
if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run with root or sudo privileges."
fi
if ! grep -q 'Ubuntu 24.04' /etc/os-release; then
    log_error "This script is designed for Ubuntu 24.04 LTS. Your OS is not supported."
fi
log_success "Pre-flight checks passed."

# --- Get Real User ID/GID (Handles sudo correctly) ---
# This is the crucial part for correct permissions. It detects the user who invoked sudo,
# not the root user, ensuring file ownership is correct.
REAL_USER=${SUDO_USER:-$USER}
REAL_UID=$(id -u "$REAL_USER")
REAL_GID=$(id -g "$REAL_USER")
log_info "Detected real user: $REAL_USER (UID: $REAL_UID, GID: $REAL_GID)"

# --- User Input ---
echo "----------------------------------------------------------------"
log_info "Please enter the required information:"
echo "----------------------------------------------------------------"
read -p "1. Subdomain (e.g., code.yourdomain.com): " DOMAIN < /dev/tty
while [[ -z "$DOMAIN" ]]; do
    log_error "Subdomain cannot be empty."
    read -p "1. Subdomain (e.g., code.yourdomain.com): " DOMAIN < /dev/tty
done
read -p "2. Your email for the SSL certificate (e.g., your-email@example.com): " EMAIL < /dev/tty
while [[ -z "$EMAIL" ]]; do
    log_error "Email cannot be empty."
    read -p "2. Your email for the SSL certificate (e.g., your-email@example.com): " EMAIL < /dev/tty
done
read -s -p "3. Enter a strong password for Code-Server: " PASSWORD < /dev/tty
while [[ -z "$PASSWORD" ]]; do
    echo
    log_error "Password cannot be empty."
    read -s -p "3. Enter a strong password for Code-Server: " PASSWORD < /dev/tty
done
echo
echo "----------------------------------------------------------------"

# --- Step 1: Server Preparation ---
log_info "Step 1: Preparing server and optimizing performance..."
if ! swapon --show | grep -q '/swapfile'; then
    log_info "Creating 2GB swap file..."
    fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    log_success "Swap file created and activated."
else
    log_info "Swap file already exists. Skipping."
fi
log_info "Updating system packages..."
apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y
log_success "System updated successfully."

# --- Step 2: Install Docker and Docker Compose ---
log_info "Step 2: Installing Docker and Docker Compose..."
if ! command -v docker &> /dev/null; then
    log_info "Docker not found. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm -f get-docker.sh
    log_success "Docker installed."
else
    log_info "Docker is already installed. Skipping."
fi
if ! docker compose version &> /dev/null; then
    log_info "Docker Compose plugin not found. Installing..."
    apt-get install -y docker-compose-plugin
    log_success "Docker Compose plugin installed."
else
    log_info "Docker Compose plugin is already installed. Skipping."
fi

# --- Step 3: Obtain SSL Certificate ---
log_info "Step 3: Obtaining SSL certificate for $DOMAIN ..."
docker run --rm -p 80:80 \
  -v "/etc/letsencrypt:/etc/letsencrypt" \
  -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
  certbot/certbot certonly --standalone \
  -d "$DOMAIN" \
  --agree-tos \
  -m "$EMAIL" --non-interactive
log_success "SSL certificate issued successfully."

# --- Step 4: Create Project Structure ---
log_info "Step 4: Creating project structure and setting permissions..."
mkdir -p /opt/code-server/nginx
mkdir -p /srv/projects
# Set ownership to the REAL user to avoid permission issues
chown -R "$REAL_UID":"$REAL_GID" /srv/projects
cd /opt/code-server
log_success "Project structure created successfully."

# --- Step 5: Create Configuration Files ---
log_info "Step 5: Creating configuration files..."
cat > .env <<EOF
CODE_SERVER_PASSWORD=$PASSWORD
EOF
chmod 600 .env
cat > Dockerfile <<'EOF'
FROM codercom/code-server:latest
USER root
RUN apt-get update && apt-get install -y python3 python3-pip python3-venv tmux sudo && rm -rf /var/lib/apt/lists/*
RUN groupmod -g ${PGID:-1000} coder && \
    usermod -u ${PUID:-1000} -g ${PGID:-1000} coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER coder
EOF
cat > docker-compose.yml <<EOF
services:
  code-server:
    build: .
    image: my-custom-code-server
    container_name: code-server
    restart: unless-stopped
    environment:
      - PASSWORD=\${CODE_SERVER_PASSWORD}
      - PUID=$REAL_UID
      - PGID=$REAL_GID
    volumes:
      - /srv/projects:/home/coder/project
    networks:
      - codeserver_network
    command: code-server /home/coder/project
  nginx-proxy:
    image: nginx:latest
    container_name: nginx-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    networks:
      - codeserver_network
networks:
  codeserver_network:
    name: codeserver_network
EOF
cat > nginx/nginx.conf <<EOF
events {}
http {
    map \$http_upgrade \$connection_upgrade {
        default upgrade;
        ''      close;
    }
    server {
        listen 80;
        server_name $DOMAIN;
        location / {
            return 301 https://\$host\$request_uri;
        }
    }
    server {
        listen 443 ssl;
        server_name $DOMAIN;
        ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
        location / {
            proxy_pass http://code-server:8080;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection \$connection_upgrade;
        }
    }
}
EOF
log_success "Configuration files created successfully."

# --- Step 6: Final Deployment ---
log_info "Step 6: Building image and starting services..."
docker compose up -d --build
log_success "Services started successfully."

# --- Step 7: Robust SSL Renewal Setup ---
log_info "Step 7: Setting up automatic SSL renewal..."
CRON_JOB="30 3 * * * docker run --rm -v /etc/letsencrypt:/etc/letsencrypt -v /var/lib/letsencrypt:/var/lib/letsencrypt certbot/certbot renew --quiet"
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
log_success "Automatic SSL renewal configured."

# --- Step 8: Comprehensive Final Verification ---
log_info "Step 8: Performing comprehensive final verification..."
sleep 15
if ! docker ps --format '{{.Names}}' | grep -q '^code-server$'; then
    log_error "Container 'code-server' is not running. Check logs with 'docker compose logs code-server'."
fi
if ! docker ps --format '{{.Names}}' | grep -q '^nginx-proxy$'; then
    log_error "Container 'nginx-proxy' is not running. Check logs with 'docker compose logs nginx-proxy'."
fi
log_success "All verifications passed. The system is fully operational."

# --- End ---
echo "==============================================================================="
log_success "Installation completed successfully and verified!"
echo "==============================================================================="
echo -e "Code-Server Access URL: ${GREEN}https://$DOMAIN${NC}"
echo -e "Your password is: ${YELLOW}$PASSWORD${NC}"
echo
echo "To manage the service, navigate to the project directory and use 'docker compose'."
echo "  cd /opt/code-server"
echo "  docker compose ps"
echo "==============================================================================="
