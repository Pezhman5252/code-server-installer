#!/bin/bash

# Code-Server Service Management Panel

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[ERROR]${NC} This script must be run with root or sudo privileges."
  exit 1
fi

# Function to show status
show_status() {
    echo -e "${BLUE}--- Current Service Status ---${NC}"
    cd /opt/code-server
    docker compose ps
    echo "---------------------------------"
}

# Main menu loop
while true; do
    clear
    echo -e "${GREEN}===== Code-Server Management Panel =====${NC}"
    show_status
    echo -e "${YELLOW}Please select an option:${NC}"
    echo "1) Start Service"
    echo "2) Stop Service"
    echo "3) Restart Service"
    echo "4) Update Service"
    echo "5) View Live Logs"
    echo "6) Exit"
    echo "---------------------------------"
    read -p "Enter your choice [1-6]: " choice

    case $choice in
        1)
            echo -e "${YELLOW}[INFO]${NC} Starting service..."
            cd /opt/code-server && docker compose up -d
            echo -e "${GREEN}[SUCCESS]${NC} Service started successfully."
            read -p "Press Enter to continue..."
            ;;
        2)
            echo -e "${YELLOW}[INFO]${NC} Stopping service..."
            cd /opt/code-server && docker compose down
            echo -e "${GREEN}[SUCCESS]${NC} Service stopped successfully."
            read -p "Press Enter to continue..."
            ;;
        3)
            echo -e "${YELLOW}[INFO]${NC} Restarting service..."
            cd /opt/code-server && docker compose restart
            echo -e "${GREEN}[SUCCESS]${NC} Service restarted successfully."
            read -p "Press Enter to continue..."
            ;;
        4)
            echo -e "${YELLOW}[INFO]${NC} Updating service (this process may take a few minutes)..."
            cd /opt/code-server && docker compose pull && docker compose up -d --build
            echo -e "${GREEN}[SUCCESS]${NC} Service updated successfully."
            read -p "Press Enter to continue..."
            ;;
        5)
            echo -e "${YELLOW}[INFO]${NC} Displaying live logs. Press Ctrl+C to exit."
            cd /opt/code-server && docker compose logs -f
            ;;
        6)
            echo -e "${GREEN}[INFO]${NC} Exiting the management panel..."
            exit 0
            ;;
        *)
            echo -e "${RED}[ERROR]${NC} Invalid option. Please try again."
            read -p "Press Enter to continue..."
            ;;
    esac
done
