# 🚀 Odoo 19 Enterprise Deployment Repository

**One-command deployment of Odoo 19 Enterprise with 719+ modules on any server!**

## ✨ Features

- 🎯 **One-command deployment** - Deploy in minutes
- 🏢 **719+ Enterprise modules** - Full enterprise feature set
- 🐳 **Docker-based** - Clean, isolated deployment
- 🔒 **Production-ready** - Optimized configuration
- 📱 **Mobile-friendly** - Responsive interface
- 🔧 **Easy management** - Simple start/stop/backup commands
- 🌐 **Multi-server ready** - Deploy on any Linux server

## 🎯 Quick Start

### **One-Command Deployment:**

```bash
curl -s https://raw.githubusercontent.com/Husen2012/odoo19-enterprise/main/deploy.sh | bash
```

### **Or Manual Deployment:**

```bash
# Clone repository
git clone https://github.com/Husen2012/odoo19-enterprise.git
cd odoo19-enterprise

# Run deployment
./deploy.sh
```

## 📋 Requirements

- **OS**: Ubuntu 20.04+ / Debian 10+ / CentOS 8+
- **RAM**: 4GB minimum, 8GB recommended
- **Disk**: 20GB minimum, 50GB recommended
- **Ports**: 10024, 20024 (or custom ports)
- **GitHub Access**: Personal Access Token for enterprise modules

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│   Odoo 19 Enterprise Container      │
│   - 719+ Enterprise Modules         │
│   - Port 10024 (Main)               │
│   - Port 20024 (Longpolling)        │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│   PostgreSQL 17 Container           │
│   - Optimized for Odoo              │
│   - Persistent storage              │
└─────────────────────────────────────┘
```

## 📦 What's Included

### **Enterprise Modules (719+):**
- 🎨 **Odoo Studio** - Visual app builder
- 📁 **Documents** - Document management system
- 🎫 **Helpdesk** - Advanced ticketing system
- 📅 **Planning** - Resource planning
- 💼 **Advanced Accounting** - Full accounting suite
- 👥 **HR Payroll** - Payroll management
- 🏭 **Manufacturing** - MRP & Quality control
- 📈 **Marketing Automation** - Campaign management
- 🔧 **Field Service** - FSM management
- 📱 **Mobile Apps** - iOS/Android support

### **Infrastructure:**
- 🐳 **Docker Compose** - Container orchestration
- 🗄️ **PostgreSQL 17** - Latest database
- 🔄 **Auto-restart** - Service reliability
- 📊 **Health checks** - Service monitoring
- 💾 **Persistent storage** - Data safety
- 🔒 **Security** - Production hardening

## 🚀 Deployment Options

### **Option 1: Interactive Deployment**
```bash
./deploy.sh
```
- Prompts for configuration
- GitHub token input
- Port selection
- Database credentials

### **Option 2: Automated Deployment**
```bash
./deploy.sh --auto \
  --github-user "yourusername" \
  --github-token "ghp_your_token" \
  --main-port 10024 \
  --longpolling-port 20024 \
  --db-password "your_secure_password"
```

### **Option 3: Environment Variables**
```bash
export GITHUB_USER="yourusername"
export GITHUB_TOKEN="ghp_your_token"
export MAIN_PORT="10024"
export LONGPOLLING_PORT="20024"
export DB_PASSWORD="your_secure_password"
./deploy.sh --env
```

## ⚙️ Configuration

### **Default Settings:**
- **Main Port**: 10024
- **Longpolling Port**: 20024
- **Database**: PostgreSQL 17
- **Admin Password**: `Enterprise@2025`
- **Workers**: 4
- **Memory Limit**: 2.5GB

### **Custom Configuration:**
Edit `config/odoo.conf` before deployment:
```ini
[options]
admin_passwd = YourMasterPassword
workers = 6
limit_memory_hard = 4294967296
# ... more options
```

## 🔧 Management Commands

### **Service Management:**
```bash
# Start services
./manage.sh start

# Stop services
./manage.sh stop

# Restart services
./manage.sh restart

# View status
./manage.sh status

# View logs
./manage.sh logs
```

### **Backup & Restore:**
```bash
# Create backup
./backup.sh create

# List backups
./backup.sh list

# Restore backup
./backup.sh restore backup_20251004_143022.tar.gz
```

### **Update Enterprise Modules:**
```bash
# Update from GitHub
./update.sh modules

# Update Odoo container
./update.sh odoo

# Full system update
./update.sh all
```

## 🌐 Multi-Server Deployment

### **Deploy on Multiple Servers:**

```bash
# Server 1
./deploy.sh --server-name "production" --main-port 10024

# Server 2  
./deploy.sh --server-name "staging" --main-port 10025

# Server 3
./deploy.sh --server-name "development" --main-port 10026
```

### **Load Balancer Setup:**
```bash
# Deploy with load balancer support
./deploy.sh --load-balancer --replicas 3
```

## 🔒 Security Features

- 🔐 **Secure passwords** - Auto-generated strong passwords
- 🌐 **Network isolation** - Docker networks
- 🔒 **SSL ready** - HTTPS configuration
- 🛡️ **Firewall rules** - Port restrictions
- 📝 **Audit logging** - Security monitoring

## 📊 Monitoring

### **Built-in Monitoring:**
- ✅ **Health checks** - Container health
- 📈 **Resource usage** - CPU/Memory monitoring
- 📊 **Performance metrics** - Response times
- 🚨 **Alerts** - Email notifications

### **Monitoring Commands:**
```bash
# System status
./monitor.sh status

# Performance report
./monitor.sh performance

# Resource usage
./monitor.sh resources
```

## 🔄 Updates & Maintenance

### **Automatic Updates:**
```bash
# Enable auto-updates
./maintenance.sh enable-auto-update

# Schedule maintenance
./maintenance.sh schedule --time "02:00" --day "sunday"
```

### **Manual Updates:**
```bash
# Check for updates
./maintenance.sh check-updates

# Apply updates
./maintenance.sh update

# Rollback if needed
./maintenance.sh rollback
```

## 🌍 Environment Support

### **Supported Operating Systems:**
- ✅ **Ubuntu** 20.04, 22.04, 24.04
- ✅ **Debian** 10, 11, 12
- ✅ **CentOS** 8, 9
- ✅ **RHEL** 8, 9
- ✅ **Amazon Linux** 2
- ✅ **Rocky Linux** 8, 9

### **Cloud Providers:**
- ☁️ **AWS** - EC2, ECS, Fargate
- ☁️ **Google Cloud** - Compute Engine, GKE
- ☁️ **Azure** - Virtual Machines, ACI
- ☁️ **DigitalOcean** - Droplets, Kubernetes
- ☁️ **Linode** - Compute instances
- 🏠 **On-Premise** - Physical servers, VMs

## 📚 Documentation

### **Included Documentation:**
- 📖 **Installation Guide** - Step-by-step setup
- 🔧 **Configuration Reference** - All options explained
- 🚨 **Troubleshooting Guide** - Common issues & solutions
- 🎯 **Best Practices** - Production recommendations
- 📱 **API Documentation** - Integration guides

### **Quick Links:**
- [Installation Guide](docs/installation.md)
- [Configuration Reference](docs/configuration.md)
- [Troubleshooting](docs/troubleshooting.md)
- [API Documentation](docs/api.md)
- [Best Practices](docs/best-practices.md)

## 🆘 Support

### **Getting Help:**
- 📖 **Documentation** - Check docs/ folder
- 🐛 **Issues** - GitHub Issues
- 💬 **Discussions** - GitHub Discussions
- 📧 **Email** - support@yourdomain.com

### **Contributing:**
- 🍴 **Fork** the repository
- 🌿 **Create** feature branch
- 📝 **Commit** your changes
- 🚀 **Push** to branch
- 📬 **Create** Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Odoo SA** - For the amazing ERP system
- **Docker** - For containerization technology
- **PostgreSQL** - For the robust database
- **Community** - For contributions and feedback

---

## 🎯 Quick Commands Reference

```bash
# Deploy
curl -s https://raw.githubusercontent.com/Husen2012/odoo19-enterprise-deployment/main/deploy.sh | bash

# Manage
./manage.sh [start|stop|restart|status|logs]

# Backup
./backup.sh [create|list|restore]

# Update
./update.sh [modules|odoo|all]

# Monitor
./monitor.sh [status|performance|resources]
```

---

**🚀 Ready to deploy Odoo 19 Enterprise on any server in minutes!**

**Repository**: https://github.com/Husen2012/odoo19-enterprise
**Version**: 1.0.0  
**Modules**: 719+ Enterprise modules  
**Status**: Production ready  

**Star ⭐ this repository if it helps you!**
