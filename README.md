# Code-Server Installer 🎯

> **One-Click Code-Server Installation & Management Script**  
> Automates the complete installation, configuration, and management of VS Code in the browser

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Ubuntu](https://img.shields.io/badge/Platform-Ubuntu%20|%20Debian%20|%20CentOS-red.svg)]()

## ✨ Features

### 🔧 **Complete Installation Automation**
- ✅ **Native or Docker Installation** - Choose your preferred method
- ✅ **SSL Certificate Setup** - Automatic Let's Encrypt integration
- ✅ **Nginx Reverse Proxy** - Professional web server configuration
- ✅ **Firewall Configuration** - Automatic security setup
- ✅ **System Requirements Check** - Validates hardware and software

### 🛡️ **Security & Validation**
- ✅ **Password Validation** - Prevents problematic characters (backslash, spaces)
- ✅ **JSON Config Validation** - Ensures configuration file integrity
- ✅ **Secure File Permissions** - Automatic permission hardening
- ✅ **SSL Auto-Renewal** - Transparent certificate management

### 🎛️ **Management Panel**
- ✅ **Interactive CLI Panel** - Easy service management
- ✅ **Status Monitoring** - Real-time service health checks
- ✅ **Log Viewer** - Integrated log access
- ✅ **Backup System** - Configuration backup & restore
- ✅ **SSL Status Check** - Certificate validity monitoring
- ✅ **One-Click Updates** - Simple version management

### 🚀 **Advanced Features**
- ✅ **Swap Space Management** - Automatic for low-memory systems
- ✅ **Multi-OS Support** - Ubuntu, Debian, CentOS, RHEL, Fedora
- ✅ **Error Recovery** - Automatic problem detection and fixes
- ✅ **Comprehensive Logging** - Full installation audit trail

---

## 📦 Installation

### Quick Start (One-Liner)

```bash
curl -fsSL https://raw.githubusercontent.com/Pezhman5252/code-server-installer/main/install-code-server-fixed.sh -o install.sh && chmod +x install.sh && ./install.sh
```

### Step-by-Step Installation

```bash
# Download the installer
curl -fsSL https://raw.githubusercontent.com/Pezhman5252/code-server-installer/main/install-code-server-fixed.sh -o install.sh

# Make it executable
chmod +x install.sh

# Run the installer
./install.sh
```

### What You'll Need

- **Domain Name** - Pointed to your server's IP
- **Email Address** - For SSL certificate registration  
- **VPS/Server** - Ubuntu 18.04+, Debian 9+, CentOS 7+, or similar
- **Root Access** - sudo privileges required

---

## 🚀 Usage

### Access Code-Server

After installation, access your Code-Server at:
```
https://your-domain.com
```

**Login with your configured password.**

### Management Panel

Use the built-in management panel:
```bash
sudo code-server-panel
```

### Management Panel Features

The interactive panel provides:

#### 🔍 **Service Management**
- **Check Status** - View Code-Server health and connectivity
- **Start/Stop/Restart** - Control service state
- **Log Viewer** - Real-time log monitoring

#### 📊 **System Information**
- **SSL Certificate Status** - Check certificate validity and expiry
- **System Resources** - Monitor RAM, disk usage, and performance
- **Service Details** - Installation method and configuration info

#### 💾 **Maintenance**
- **Backup Configuration** - Create configuration backups
- **Update Code-Server** - One-click version updates
- **SSL Renewal** - Monitor certificate auto-renewal

---

## 🎯 Installation Process

### 1. **System Validation**
- Checks available RAM (configures swap if < 2GB)
- Validates disk space (minimum 5GB required)
- Verifies sudo/root privileges
- Confirms OS compatibility

### 2. **Dependencies Installation**
- curl, wget, jq utilities
- Docker & Docker Compose (if selected)
- Nginx web server
- SSL certificate tools (certbot)

### 3. **Code-Server Installation**
- **Native**: Direct installation from official repository
- **Docker**: Containerized setup with persistent volumes

### 4. **Web Configuration**
- Nginx reverse proxy setup
- SSL certificate generation with Let's Encrypt
- Firewall rule configuration
- Auto-renewal setup

### 5. **Management Tools**
- Installation of management panel at `/usr/local/bin/code-server-panel`
- Configuration file creation at `/etc/code-server/installer-config.json`
- Service auto-start configuration

---

## 🔧 Configuration

### Configuration File Location
```
/etc/code-server/installer-config.json
```

### Sample Configuration
```json
{
    "domain": "code.example.com",
    "admin_email": "admin@example.com",
    "code_server_password": "YourSecurePassword123",
    "install_method": "native",
    "timezone": "America/New_York",
    "install_date": "2025-11-28T21:37:22+00:00",
    "version": "2.2"
}
```

### Password Requirements
- ✅ Minimum 8 characters
- ✅ At least one uppercase letter
- ✅ At least one number
- ❌ Cannot contain spaces
- ❌ Cannot contain backslash (`\`) characters

---

## 🛠️ Troubleshooting

### Common Issues

#### **"Invalid configuration file" Error**
```bash
# Run the config fix script
curl -fsSL https://raw.githubusercontent.com/Pezhman5252/code-server-installer/main/config-backslash-fix.sh -o fix.sh
chmod +x fix.sh
sudo ./fix.sh
```

#### **Service Not Starting**
```bash
# Check service status
sudo systemctl status code-server@$USER

# View logs
sudo journalctl -u code-server@$USER -f

# Restart service
sudo systemctl restart code-server@$USER
```

#### **SSL Certificate Issues**
```bash
# Check certificate status
sudo certbot certificates

# Manual renewal
sudo certbot renew

# Check domain configuration
nslookup your-domain.com
```

#### **Access Denied**
```bash
# Verify nginx configuration
sudo nginx -t

# Check firewall
sudo ufw status
sudo firewall-cmd --list-all
```

### Password Recovery
If you forget your Code-Server password:

```bash
# View current password from config
sudo jq -r '.code_server_password' /etc/code-server/installer-config.json
```

To change password:
```bash
# Edit configuration file
sudo nano /etc/code-server/installer-config.json

# Update the password field, then restart
sudo systemctl restart code-server@$USER
```

---

## 🔒 Security Considerations

### Network Security
- Uses HTTPS with modern TLS protocols
- Implements security headers (X-Frame-Options, X-Content-Type-Options)
- Configures secure SSL cipher suites

### File Permissions
- Configuration files: `600` (owner read/write only)
- Management panel: Executable by root only
- Service files: Restricted system permissions

### Access Control
- Code-Server password-protected
- Management panel requires sudo
- SSL certificates auto-managed and renewed

---

## 📋 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+, Fedora 28+
- **RAM**: 2GB (swap configured automatically if needed)
- **Storage**: 5GB available disk space
- **Network**: Domain name pointing to server IP

### Recommended
- **RAM**: 4GB+
- **CPU**: 2+ cores
- **Storage**: 10GB+ SSD
- **Bandwidth**: 100Mbps+

---

## 🆘 Support

### Getting Help

1. **Check Logs**:
   ```bash
   sudo code-server-panel
   # Select option 5: View logs
   ```

2. **Verify Configuration**:
   ```bash
   sudo jq empty /etc/code-server/installer-config.json
   ```

3. **Test Connectivity**:
   ```bash
   curl -I https://your-domain.com
   ```

### Reporting Issues
- Check the troubleshooting section above
- Verify your system meets minimum requirements
- Ensure your domain DNS is correctly configured

---

## 📚 Additional Resources

- [Official Code-Server Documentation](https://code-server.dev/)
- [Let's Encrypt SSL Certificates](https://letsencrypt.org/)
- [Nginx Documentation](https://nginx.org/en/docs/)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and enhancement requests.

### Development Setup
```bash
# Clone the repository
git clone https://github.com/Pezhman5252/code-server-installer.git
cd code-server-installer

# Test on a clean system
./install-code-server-fixed.sh
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🎉 Acknowledgments

- [Code-Server](https://github.com/coder/code-server) by Coder
- [Let's Encrypt](https://letsencrypt.org/) for free SSL certificates
- [Nginx](https://nginx.org/) for the web server
- Community contributors and testers

---

**Made with ❤️ for developers who want VS Code in the browser**

---

*Last updated: November 28, 2025*