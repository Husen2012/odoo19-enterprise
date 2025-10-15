# 🚀 Quick Installation Guide

## ⚡ One-Command Installation

```bash
curl -s https://raw.githubusercontent.com/Husen2012/odoo19-enterprise-deployment/main/deploy.sh | bash
```

## 📋 Prerequisites

Before installation, ensure you have:

- **Root access** or sudo privileges
- **GitHub Personal Access Token** with repository access
- **Minimum 4GB RAM** (8GB recommended)
- **Minimum 20GB disk space** (50GB recommended)
- **Open ports**: 10024, 20024 (or your custom ports)

## 🔑 GitHub Token Setup

1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `read:org` (Read org and team membership)
4. Copy the generated token (starts with `ghp_`)

## 🛠️ Manual Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/Husen2012/odoo19-enterprise-deployment.git
cd odoo19-enterprise-deployment
```

### Step 2: Make Scripts Executable

```bash
chmod +x deploy.sh
chmod +x scripts/*.sh
```

### Step 3: Run Deployment

#### Interactive Mode:
```bash
./deploy.sh
```

#### Automated Mode:
```bash
./deploy.sh --auto \
  --github-user "yourusername" \
  --github-token "ghp_your_token_here" \
  --main-port 10024 \
  --longpolling-port 20024
```

#### Environment Variables Mode:
```bash
export GITHUB_USER="yourusername"
export GITHUB_TOKEN="ghp_your_token_here"
export MAIN_PORT="10024"
export LONGPOLLING_PORT="20024"
./deploy.sh --env
```

## 🎯 Post-Installation

### 1. Access Odoo
- Open: `http://your-server-ip:10024`
- Master Password: `Enterprise@2025` (or your custom password)

### 2. Create Database
- Click "Create Database"
- Fill in database details
- Wait for creation to complete

### 3. Install Enterprise Modules
- Go to **Apps** menu
- Click **"Update Apps List"**
- Search and install:
  - **Odoo Studio** (Visual app builder)
  - **Web Enterprise** (Enterprise UI)
  - **Documents** (Document management)
  - **Helpdesk** (Ticketing system)

## 🔧 Management Commands

### Service Management:
```bash
cd /opt/odoo19-enterprise  # or your install directory

# Start services
./manage.sh start

# Stop services
./manage.sh stop

# Restart services
./manage.sh restart

# Check status
./manage.sh status

# View logs
./manage.sh logs
```

### Backup & Restore:
```bash
# Create backup
./backup.sh create

# List backups
./backup.sh list

# Restore backup
./backup.sh restore complete_backup_20251004_143022.tar.gz
```

### Updates:
```bash
# Update enterprise modules
./update.sh modules

# Update containers
./update.sh odoo

# Update everything
./update.sh all
```

## 🌐 Multi-Server Deployment

### Deploy on Multiple Servers:

```bash
# Server 1 (Production)
./deploy.sh --auto \
  --github-user "yourusername" \
  --github-token "ghp_your_token" \
  --main-port 10024 \
  --install-dir "/opt/odoo19-production"

# Server 2 (Staging)
./deploy.sh --auto \
  --github-user "yourusername" \
  --github-token "ghp_your_token" \
  --main-port 10025 \
  --install-dir "/opt/odoo19-staging"
```

## 🔒 Security Recommendations

### 1. Change Default Passwords
```bash
# Edit configuration
nano config/odoo.conf

# Change admin_passwd and db_password
# Restart services
./manage.sh restart
```

### 2. Setup SSL (with Nginx Proxy Manager)
```bash
# Install Nginx Proxy Manager
docker run -d \
  --name nginx-proxy-manager \
  -p 80:80 -p 443:443 -p 81:81 \
  jc21/nginx-proxy-manager:latest

# Access: http://your-server-ip:81
# Add proxy host for your Odoo domain
```

### 3. Firewall Configuration
```bash
# Allow only necessary ports
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 10024/tcp # Odoo (if direct access needed)
ufw enable
```

## 🚨 Troubleshooting

### Issue 1: Services Not Starting
```bash
# Check Docker status
systemctl status docker

# Check logs
./manage.sh logs

# Restart Docker
systemctl restart docker
./manage.sh start
```

### Issue 2: Enterprise Modules Not Loading
```bash
# Check enterprise directory
ls -la enterprise/

# Update modules
./update.sh modules

# Restart Odoo
./manage.sh restart
```

### Issue 3: Database Connection Issues
```bash
# Check database logs
./manage.sh logs db

# Restart database
docker compose restart db
```

### Issue 4: Port Already in Use
```bash
# Check what's using the port
netstat -tulpn | grep :10024

# Kill the process or change port in docker-compose.yml
```

## 📊 System Requirements

### Minimum Requirements:
- **CPU**: 2 cores
- **RAM**: 4GB
- **Disk**: 20GB
- **OS**: Ubuntu 20.04+, Debian 10+, CentOS 8+

### Recommended Requirements:
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Disk**: 50GB+ SSD
- **OS**: Ubuntu 22.04 LTS

### Production Requirements:
- **CPU**: 8+ cores
- **RAM**: 16GB+
- **Disk**: 100GB+ SSD
- **Network**: 1Gbps+
- **Backup**: Automated daily backups

## 🔄 Backup Strategy

### Automated Backups:
```bash
# Schedule daily backups at 2 AM
./backup.sh schedule daily

# Schedule weekly backups
./backup.sh schedule weekly

# Clean old backups (older than 30 days)
./backup.sh clean 30
```

### Manual Backups:
```bash
# Before major updates
./backup.sh create

# Before configuration changes
./backup.sh create

# Before module installations
./backup.sh create
```

## 📞 Support

### Getting Help:
- 📖 **Documentation**: Check `docs/` folder
- 🐛 **Issues**: GitHub Issues
- 💬 **Discussions**: GitHub Discussions

### Useful Commands:
```bash
# Check system resources
./manage.sh status

# Monitor performance
docker stats

# Check disk usage
df -h

# Check memory usage
free -h
```

## 🎉 Success!

If everything is working correctly, you should see:

- ✅ Odoo accessible at `http://your-server-ip:10024`
- ✅ 719+ Enterprise modules available
- ✅ All containers running and healthy
- ✅ Database connection working
- ✅ Enterprise features activated

**Enjoy your Odoo 19 Enterprise deployment!** 🚀

---

**Repository**: https://github.com/Husen2012/odoo19-enterprise-deployment  
**Version**: 1.0.0  
**Support**: Create an issue on GitHub
