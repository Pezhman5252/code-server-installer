#!/bin/bash

# ===============================================
# System Requirements Checker for Code-Server (Enhanced)
# Author: MiniMax Agent
# Version: 1.2 (Enhanced with Bug Fixes)
# Description: Pre-installation system compatibility check
# ===============================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

print_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${NC}$1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "⚠️  RUNNING AS ROOT USER ⚠️"
        print_info "It's recommended to use a regular user with sudo privileges for security."
        print_info "However, this script will work with root privileges."
        echo ""
        read -p "Continue with root privileges? (yes/no): " confirm_root
        if [[ ! "$confirm_root" =~ ^[Yy][Ee][Ss]$ ]]; then
            print_info "Please switch to a regular user: su - username"
            exit 1
        fi
        echo ""
    else
        if ! sudo -n true 2>/dev/null; then
            print_fail "No sudo privileges. Please configure sudo access."
            print_info "Run: sudo usermod -aG sudo $USER (then logout and login again)"
            exit 1
        fi
    fi
    print_pass "Sudo access verified"
}

# Function to check OS compatibility
check_os() {
    print_header "=== Operating System Check ==="
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="$ID"
        VERSION="$VERSION_ID"
        print_info "Detected OS: $NAME $VERSION"
        
        case $OS in
            ubuntu)
                VERSION_NUM=$(echo "$VERSION_ID" | cut -d. -f1)
                if [[ $VERSION_NUM -ge 18 ]]; then
                    print_pass "Ubuntu $VERSION (supported)"
                else
                    print_fail "Ubuntu $VERSION (too old, need 18.04+)"
                fi
                ;;
            debian)
                VERSION_NUM=$(echo "$VERSION_ID" | cut -d. -f1)
                if [[ $VERSION_NUM -ge 9 ]]; then
                    print_pass "Debian $VERSION (supported)"
                else
                    print_fail "Debian $VERSION (too old, need 9+)"
                fi
                ;;
            centos|rhel)
                VERSION_NUM=$(echo "$VERSION_ID" | cut -d. -f1)
                if [[ $VERSION_NUM -ge 7 ]]; then
                    print_pass "$NAME $VERSION (supported)"
                else
                    print_fail "$NAME $VERSION (too old, need 7+)"
                fi
                ;;
            fedora)
                print_pass "Fedora $VERSION (supported)"
                ;;
            *)
                print_warning "$NAME $VERSION (not officially supported)"
                print_info "Installation may still work but isn't guaranteed"
                ;;
        esac
    else
        print_fail "Cannot determine operating system"
        exit 1
    fi
    echo
}

# Function to check system resources
check_resources() {
    print_header "=== System Resources Check ==="
    
    # Check memory
    if command_exists free; then
        TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
        AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')
        
        print_info "Total Memory: ${TOTAL_MEM}MB"
        print_info "Available Memory: ${AVAILABLE_MEM}MB"
        
        if [[ $TOTAL_MEM -ge 2048 ]]; then
            print_pass "Memory: Excellent (${TOTAL_MEM}MB >= 2GB)"
        elif [[ $TOTAL_MEM -ge 1024 ]]; then
            print_warning "Memory: Good (${TOTAL_MEM}MB >= 1GB, recommend 2GB+)"
            print_info "Installer will offer to create swap space during installation"
        else
            print_fail "Memory: Insufficient (${TOTAL_MEM}MB < 1GB)"
            print_info "SOLUTION: Installer will offer to create swap space"
        fi
        
        # Check existing swap
        SWAP_TOTAL=$(free -m | awk 'NR==3{print $2}')
        if [[ $SWAP_TOTAL -gt 0 ]]; then
            print_info "Existing Swap: ${SWAP_TOTAL}MB"
        else
            print_info "Existing Swap: None (will be created if needed)"
        fi
    else
        print_info "Memory check skipped (free command not available)"
    fi
    
    # Check disk space
    if command_exists df; then
        DISK_SPACE_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
        DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
        
        print_info "Disk Space: ${DISK_SPACE_GB}GB available (Usage: $DISK_USAGE)"
        
        if [[ $DISK_SPACE_GB -ge 20 ]]; then
            print_pass "Disk Space: Excellent (${DISK_SPACE_GB}GB >= 20GB)"
        elif [[ $DISK_SPACE_GB -ge 10 ]]; then
            print_pass "Disk Space: Good (${DISK_SPACE_GB}GB >= 10GB)"
        elif [[ $DISK_SPACE_GB -ge 5 ]]; then
            print_warning "Disk Space: Adequate (${DISK_SPACE_GB}GB >= 5GB, recommend 10GB+)"
        else
            print_fail "Disk Space: Insufficient (${DISK_SPACE_GB}GB < 5GB, need at least 5GB)"
        fi
    else
        print_info "Disk check skipped (df command not available)"
    fi
    
    # Check CPU
    if [[ -f /proc/cpuinfo ]]; then
        CPU_CORES=$(grep -c "^processor" /proc/cpuinfo)
        CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        print_info "CPU: $CPU_MODEL"
        print_info "CPU Cores: $CPU_CORES"
        
        if [[ $CPU_CORES -ge 2 ]]; then
            print_pass "CPU: Good ($CPU_CORES cores >= 2)"
        elif [[ $CPU_CORES -eq 1 ]]; then
            print_warning "CPU: Single core (recommend 2+ cores for better performance)"
        fi
    else
        print_info "CPU check skipped"
    fi
    echo
}

# Function to check network connectivity
check_network() {
    print_header "=== Network Connectivity Check ==="
    
    # Check internet connectivity
    print_info "Testing internet connectivity..."
    if ping -c 1 -W 3 google.com >/dev/null 2>&1; then
        print_pass "Internet connectivity: OK"
    elif ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
        print_pass "Internet connectivity: OK (DNS may have issues)"
    else
        print_fail "Internet connectivity: Failed"
        print_info "Please check your internet connection"
    fi
    
    # Get server IP
    if command_exists curl; then
        SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 icanhazip.com 2>/dev/null || echo "Unable to detect")
        print_info "Server Public IP: $SERVER_IP"
    fi
    
    # Check required ports availability - IMPROVED VERSION
    PORTS=(80 443 8080)
    print_info "Checking port availability:"
    
    for port in "${PORTS[@]}"; do
        if command_exists netstat; then
            if netstat -tuln 2>/dev/null | grep -q ":$port "; then
                # IMPROVED: Safer process detection
                PROCESS_INFO=$(netstat -tlnp 2>/dev/null | grep ":$port " | head -1)
                if [[ -n "$PROCESS_INFO" ]]; then
                    # Extract process info more safely
                    PROCESS=$(echo "$PROCESS_INFO" | awk '{print $7}' | grep -o '[^/]*' | head -1)
                    if [[ -n "$PROCESS" && "$PROCESS" != "-" ]]; then
                        print_warning "Port $port: In use by $PROCESS"
                    else
                        print_warning "Port $port: In use by unknown process"
                    fi
                else
                    print_warning "Port $port: In use (may need to stop existing service)"
                fi
            else
                print_pass "Port $port: Available"
            fi
        elif command_exists ss; then
            if ss -tuln 2>/dev/null | grep -q ":$port "; then
                # IMPROVED: Simpler and more reliable process detection
                PROCESS_INFO=$(ss -tlnp 2>/dev/null | grep ":$port " | head -1)
                if [[ -n "$PROCESS_INFO" ]]; then
                    # Extract PID/Process name more safely
                    if echo "$PROCESS_INFO" | grep -q "users:((.*))"; then
                        PROCESS=$(echo "$PROCESS_INFO" | sed 's/.*users:((\([^)]*\)).*/\1/' | cut -d',' -f1 | cut -d'/' -f1)
                        if [[ -n "$PROCESS" && "$PROCESS" != "" ]]; then
                            print_warning "Port $port: In use by PID $PROCESS"
                        else
                            print_warning "Port $port: In use (process detection limited)"
                        fi
                    else
                        print_warning "Port $port: In use (process info unavailable)"
                    fi
                else
                    print_warning "Port $port: In use (may need to stop existing service)"
                fi
            else
                print_pass "Port $port: Available"
            fi
        else
            print_info "Port check skipped (netstat/ss not available)"
            break
        fi
    done
    echo
}

# Function to check package manager
check_package_manager() {
    print_header "=== Package Manager Check ==="
    
    case ${OS:-unknown} in
        ubuntu|debian)
            if command_exists apt; then
                print_pass "APT package manager: Available"
                # Check if sudo apt update works
                print_info "Testing repository access..."
                if sudo apt update -qq >/dev/null 2>&1; then
                    print_pass "APT repository access: OK"
                else
                    print_warning "APT repository access: Issues detected"
                    print_info "Try: sudo apt update"
                fi
            else
                print_fail "APT package manager: Not found"
            fi
            ;;
        centos|rhel|fedora)
            if command_exists yum || command_exists dnf; then
                PACKAGE_CMD="yum"
                [[ ${OS:-} == "fedora" ]] && PACKAGE_CMD="dnf"
                print_pass "$PACKAGE_CMD package manager: Available"
                # Check repository access
                print_info "Testing repository access..."
                if sudo "$PACKAGE_CMD" repolist >/dev/null 2>&1; then
                    print_pass "Repository access: OK"
                else
                    print_warning "Repository access: Issues detected"
                fi
            else
                print_fail "YUM/DNF package manager: Not found"
            fi
            ;;
        *)
            print_warning "Package manager check skipped (unknown OS)"
            ;;
    esac
    echo
}

# Function to check required software
check_software() {
    print_header "=== Required Software Check ==="
    
    REQUIRED_SOFTWARE=(curl wget git)
    
    print_info "Essential software:"
    for software in "${REQUIRED_SOFTWARE[@]}"; do
        if command_exists "$software"; then
            VERSION=$($software --version 2>/dev/null | head -1 | awk '{print $1, $2, $3}')
            print_pass "$software: Available"
        else
            print_fail "$software: Not found (will be installed automatically)"
        fi
    done
    
    echo ""
    print_info "Optional software (will be installed if needed):"
    OPTIONAL_SOFTWARE=(docker nginx certbot jq)
    
    for software in "${OPTIONAL_SOFTWARE[@]}"; do
        if command_exists "$software"; then
            VERSION=$($software --version 2>/dev/null | head -1 | awk '{print $1, $2, $3}')
            print_pass "$software: Available"
        else
            print_info "$software: Not found (will be installed)"
        fi
    done
    
    # Check Docker Compose specifically - IMPROVED
    echo ""
    print_info "Docker Compose check:"
    if command -v docker &>/dev/null && docker compose version &>/dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "unknown")
        print_pass "Docker Compose (V2): Available ($COMPOSE_VERSION)"
    elif command_exists docker-compose; then
        COMPOSE_VERSION=$(docker-compose --version 2>/dev/null | awk '{print $3}' | tr -d ',')
        print_pass "Docker Compose (V1): Available ($COMPOSE_VERSION)"
    else
        print_info "Docker Compose: Not found (will be installed if Docker method chosen)"
    fi
    echo
}

# Function to check domain configuration - IMPROVED
check_domain() {
    print_header "=== Domain Configuration Check ==="
    
    echo -n -e "${CYAN}Enter your domain name for code-server (press Enter to skip): ${NC}"
    read -r DOMAIN
    
    if [[ -z "$DOMAIN" ]]; then
        print_info "Domain check skipped (no domain provided)"
        echo ""
        return
    fi
    
    # IMPROVED: Better domain validation
    if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]*\.[a-zA-Z]{2,}$ ]]; then
        print_fail "Invalid domain name format"
        print_info "Examples: example.com, code.example.com, my-site.co.uk"
        echo ""
        return
    fi
    
    print_info "Checking domain: $DOMAIN"
    
    # IMPROVED: Domain resolution check with fallback
    DOMAIN_IP=""
    if command_exists dig; then
        DOMAIN_IP=$(dig +short "$DOMAIN" @8.8.8.8 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
        if [[ -n "$DOMAIN_IP" ]]; then
            print_pass "Domain resolves to: $DOMAIN_IP"
        else
            print_warning "Domain does not resolve to an IP address"
        fi
    elif command_exists nslookup; then
        if nslookup "$DOMAIN" >/dev/null 2>&1; then
            DOMAIN_IP=$(nslookup "$DOMAIN" 2>/dev/null | awk '/^Address: / { print $2 }' | tail -1 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
            if [[ -n "$DOMAIN_IP" ]]; then
                print_pass "Domain resolves to: $DOMAIN_IP"
            else
                print_warning "Domain may not resolve to a valid IP"
            fi
        else
            print_warning "Domain DNS lookup failed"
        fi
    elif command_exists host; then
        if host "$DOMAIN" >/dev/null 2>&1; then
            DOMAIN_IP=$(host "$DOMAIN" 2>/dev/null | awk '/has address/ { print $4 }' | head -1 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
            if [[ -n "$DOMAIN_IP" ]]; then
                print_pass "Domain resolves to: $DOMAIN_IP"
            else
                print_warning "Domain may not resolve to a valid IP"
            fi
        else
            print_warning "Domain host lookup failed"
        fi
    else
        print_info "Domain DNS check skipped (dig/nslookup/host not available)"
        print_info "You can manually verify that $DOMAIN points to this server's IP"
    fi
    
    # IMPROVED: Check domain IP vs server IP with better error handling
    if command_exists curl; then
        SERVER_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 icanhazip.com 2>/dev/null || echo "")
        
        if [[ -n "${DOMAIN_IP:-}" && -n "$SERVER_IP" ]]; then
            if [[ "$DOMAIN_IP" == "$SERVER_IP" ]]; then
                print_pass "Domain points to this server: $SERVER_IP ✓"
            else
                print_warning "Domain points to: $DOMAIN_IP, but server IP is: $SERVER_IP"
                print_info "You need to update DNS records before SSL setup"
            fi
        elif [[ -n "$SERVER_IP" ]]; then
            print_info "Server IP: $SERVER_IP"
            if [[ -z "${DOMAIN_IP:-}" ]]; then
                print_warning "Could not verify domain DNS configuration"
            fi
        fi
    fi
    echo
}

# Function to show recommendations
show_recommendations() {
    print_header "=== Recommendations ==="
    
    print_info "Pre-installation checklist:"
    echo "  • Point your domain DNS A record to this server's IP"
    echo "  • Ensure ports 80, 443 are accessible from internet"
    echo "  • Have a valid email address for SSL certificate"
    echo "  • Prepare a strong password (min 8 characters)"
    echo ""
    
    print_info "Performance recommendations:"
    echo "  • Minimum: 1GB RAM + 2GB Swap"
    echo "  • Recommended: 2GB+ RAM for optimal performance"
    echo "  • At least 10GB free disk space"
    echo "  • 2+ CPU cores for development work"
    echo ""
    
    print_info "Security recommendations:"
    echo "  • Use a strong, unique password (8+ characters)"
    echo "  • Keep your domain DNS properly configured"
    echo "  • Regular system updates after installation"
    echo "  • Monitor logs for suspicious activity"
    echo "  • Consider using SSH key authentication"
    echo ""
    
    print_info "Installation method comparison:"
    echo "  • Native: Lower resource usage, better performance"
    echo "  • Docker: Better isolation, easier management & updates"
    echo "  • For personal servers: Native recommended"
    echo "  • For production/team: Docker recommended"
    echo ""
}

# Function to generate summary
generate_summary() {
    print_header "=== Pre-Installation Summary ==="
    
    # Count checks
    local warnings=0
    local failures=0
    
    # Memory check
    if [[ ${TOTAL_MEM:-0} -lt 1024 ]]; then
        ((failures++))
    elif [[ ${TOTAL_MEM:-0} -lt 2048 ]]; then
        ((warnings++))
    fi
    
    # Disk check
    if [[ ${DISK_SPACE_GB:-0} -lt 5 ]]; then
        ((failures++))
    elif [[ ${DISK_SPACE_GB:-0} -lt 10 ]]; then
        ((warnings++))
    fi
    
    echo ""
    if [[ $failures -eq 0 && $warnings -eq 0 ]]; then
        print_pass "All checks passed! System is ready for installation."
    elif [[ $failures -eq 0 ]]; then
        print_warning "Some warnings detected but installation can proceed."
    else
        print_fail "Critical issues detected. Please resolve them before installation."
    fi
    echo ""
}

# Main function
main() {
    echo -e "${PURPLE}"
    cat <<'EOF'
    _____ _                 _ _            
   / ____| |               | (_)           
  | |    | |__   __ _ _ __ | |_  ___  ___  
  | |    | '_ \ / _` | '_ \| | |/ _ \/ _ \ 
  | |____| | | | (_| | | | | | |  __/ (_) |
   \_____|_| |_|\__,_|_| |_|_|_|\___|\___/ 
                                            
    Code-Server System Requirements Checker
    Author: MiniMax Agent
    Version: 1.2 (Enhanced with Bug Fixes)
EOF
    echo -e "${NC}"
    echo ""
    
    check_root
    check_os
    check_resources
    check_network
    check_package_manager
    check_software
    check_domain
    show_recommendations
    generate_summary
    
    echo -e "${CYAN}Review the results above and address any failures before installation.${NC}"
    echo ""
    echo -e "${GREEN}If ready to proceed, run the installation script:${NC}"
    echo -e "${YELLOW}  chmod +x install-code-server-enhanced.sh${NC}"
    echo -e "${YELLOW}  ./install-code-server-enhanced.sh${NC}"
    echo ""
}

# Run main function
main "$@"