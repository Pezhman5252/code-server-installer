# Quick Reference Guide

## 🔥 One-Liner Installation
```bash
curl -fsSL https://raw.githubusercontent.com/Pezhman5252/code-server-installer/main/install-code-server-fixed.sh -o install.sh && chmod +x install.sh && ./install.sh
```

## 🎛️ Management Commands
```bash
# Open management panel
sudo code-server-panel

# Check service status
sudo systemctl status code-server@$USER

# View logs
sudo journalctl -u code-server@$USER -f

# Restart service
sudo systemctl restart code-server@$USER

# Check SSL certificates
sudo certbot certificates
```

## 🚨 Emergency Fixes
```bash
# Fix config file errors
curl -fsSL https://raw.githubusercontent.com/Pezhman5252/code-server-installer/main/config-backslash-fix.sh -o fix.sh && chmod +x fix.sh && sudo ./fix.sh

# Check nginx configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx

# Check firewall status
sudo ufw status
```

## 🔑 Password Management
```bash
# View current password
sudo jq -r '.code_server_password' /etc/code-server/installer-config.json

# Edit configuration
sudo nano /etc/code-server/installer-config.json
```

## 🌐 Network Diagnostics
```bash
# Test HTTPS access
curl -I https://your-domain.com

# Check DNS resolution
nslookup your-domain.com

# Test local connectivity
curl -I http://127.0.0.1:8080
```