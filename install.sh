#!/bin/bash

# Automated Code-Server Installation Guide
# Run this script with the following command:
# curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install.sh | sudo bash

# --- Initial script setup and security ---
set -euo pipefail

# Colors for better output readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Message printing functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# --- Start of the script ---
log_info "Starting the automated Code-Server installation process..."

# Check if the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run with root or sudo privileges. Please use sudo."
fi

# Get information from the user
echo "----------------------------------------------------------------"
log_info "Please enter the required information:"
echo "----------------------------------------------------------------"

read -p "1. Subdomain (e.g., code.yourdomain.com): " DOMAIN
while [[ -z "$DOMAIN" ]]; do
    log_error "Subdomain cannot be empty."
    read -p "1. Subdomain (e.g., code.yourdomain.com): " DOMAIN
done

read -p "2. Your email for the SSL certificate (e.g., your-email@example.com): " EMAIL
while [[ -z "$EMAIL" ]]; do
    log_error "Email cannot be empty."
    read -p "2. Your email for the SSL certificate (e.g., your-email@example.com): " EMAIL
done

read -s -p "3. Enter a strong password for Code-Server: " PASSWORD
while [[ -z "$PASSWORD" ]]; do
    echo
    log_error "Password cannot be empty."
    read -s -p "3. Enter a strong password for Code-Server: " PASSWORD
done
echo
echo "----------------------------------------------------------------"

# --- Step 1: Server Preparation ---
log_info "Step 1: Initial server preparation and optimization..."
fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
apt update && apt upgrade -y
log_success "Server prepared successfully."

# --- Step 2: Install Docker and Docker Compose ---
log_info "Step 2: Installing Docker and Docker Compose..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
apt-get update
apt-get install -y docker-compose-plugin
log_success "Docker and Docker Compose installed successfully."

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
chown -R $(id -u):$(id -g) /srv/projects
cd /opt/code-server
log_success "Project structure created successfully."

# --- Step 5: Create Configuration Files ---
log_info "Step 5: Creating configuration files..."

# Create .env file
cat > .env <<EOF
CODE_SERVER_PASSWORD=$PASSWORD
EOF

# Create Dockerfile
cat > Dockerfile <<'EOF'
FROM codercom/code-server:latest
USER root
RUN apt-get update && apt-get install -y python3 python3-pip python3-venv tmux sudo && rm -rf /var/lib/apt/lists/*
RUN addgroup --gid ${PGID:-1000} coder && \
    adduser --uid ${PUID:-1000} --ingroup coder --home /home/coder --shell /bin/bash --disabled-password --gecos "" coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER coder
EOF

# Create docker-compose.yml file
cat > docker-compose.yml <<EOF
services:
  code-server:
    build: .
    image: my-custom-code-server
    container_name: code-server
    restart: unless-stopped
    environment:
      - PASSWORD=\${CODE_SERVER_PASSWORD}
      - PUID=$(id -u)
      - PGID=$(id -g)
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

# Create nginx.conf file
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
log_success "Code-Server service started successfully."

# --- Step 7: Set up automatic SSL renewal ---
log_info "Step 7: Setting up automatic SSL renewal..."
(crontab -l 2>/dev/null; echo "30 3 * * * docker run --rm -v /etc/letsencrypt:/etc/letsencrypt -v /var/lib/letsencrypt:/var/lib/letsencrypt certbot/certbot renew --quiet") | crontab -
log_success "Automatic SSL renewal configured successfully."

# --- Step 8: Download management script ---
log_info "Step 8: Downloading the management script..."
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/manage.sh -o /usr/local/bin/code-server-panel
chmod +x /usr/local/bin/code-server-panel
log_success "Management script installed as 'code-server-panel'."

# --- End ---
echo "----------------------------------------------------------------"
log_success "Installation completed successfully!"
echo "----------------------------------------------------------------"
echo -e "Code-Server Access URL: ${GREEN}https://$DOMAIN${NC}"
echo -e "Your password is: ${YELLOW}$PASSWORD${NC}"
echo
echo "To manage the service, use the following command:"
echo -e "${YELLOW}sudo code-server-panel${NC}"
echo "----------------------------------------------------------------"
