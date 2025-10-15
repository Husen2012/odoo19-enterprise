#!/bin/bash

#############################################
# GitHub Repository Creation Script
# Create and push to GitHub repository
#############################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║        📦 GitHub Repository Setup                         ║${NC}"
    echo -e "${CYAN}║        🚀 Odoo 19 Enterprise Deployment                   ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

# Check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install git first."
        exit 1
    fi
    print_success "Git is installed"
}

# Check if GitHub CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_info "GitHub CLI is not installed. You'll need to create the repository manually."
        return 1
    fi
    print_success "GitHub CLI is installed"
    return 0
}

# Initialize git repository
init_git() {
    print_header "Initializing Git Repository"
    
    if [[ -d ".git" ]]; then
        print_info "Git repository already exists"
    else
        git init
        print_success "Git repository initialized"
    fi
    
    # Create .gitignore
    cat > .gitignore << 'EOF'
# Environment files
.env
*.env

# Odoo data directories
filestore/
sessions/
postgresql/
backups/
enterprise/

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Docker volumes
volumes/

# SSL certificates
ssl/
*.pem
*.crt
*.key

# Custom addons (if you want to exclude them)
# addons/

# Python cache
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
EOF
    
    print_success ".gitignore created"
}

# Add files to git
add_files() {
    print_header "Adding Files to Git"
    
    git add .
    git status
    
    print_success "Files added to git"
}

# Create initial commit
create_commit() {
    print_header "Creating Initial Commit"
    
    git commit -m "🚀 Initial commit: Odoo 19 Enterprise Deployment

Features:
- One-command deployment script
- 719+ Enterprise modules support
- Docker-based architecture
- Management scripts (start/stop/backup/update)
- Multi-server deployment support
- Automated backups
- SSL support
- Production-ready configuration

Usage:
curl -s https://raw.githubusercontent.com/Husen2012/odoo19-enterprise-deployment/main/deploy.sh | bash"
    
    print_success "Initial commit created"
}

# Create GitHub repository using CLI
create_github_repo() {
    print_header "Creating GitHub Repository"
    
    REPO_NAME="odoo19-enterprise-deployment"
    DESCRIPTION="🚀 One-command deployment of Odoo 19 Enterprise with 719+ modules. Docker-based, production-ready, multi-server support."
    
    if check_gh_cli; then
        print_info "Creating repository using GitHub CLI..."
        
        gh repo create "$REPO_NAME" \
            --description "$DESCRIPTION" \
            --public \
            --source=. \
            --remote=origin \
            --push
        
        print_success "Repository created and pushed to GitHub!"
        echo -e "Repository URL: ${BLUE}https://github.com/Husen2012/$REPO_NAME${NC}"
    else
        print_info "Please create the repository manually:"
        echo -e "1. Go to ${BLUE}https://github.com/new${NC}"
        echo -e "2. Repository name: ${BLUE}$REPO_NAME${NC}"
        echo -e "3. Description: ${BLUE}$DESCRIPTION${NC}"
        echo -e "4. Make it public"
        echo -e "5. Don't initialize with README (we already have one)"
        echo ""
        echo -e "Then run these commands:"
        echo -e "${CYAN}git remote add origin https://github.com/Husen2012/$REPO_NAME.git${NC}"
        echo -e "${CYAN}git branch -M main${NC}"
        echo -e "${CYAN}git push -u origin main${NC}"
    fi
}

# Setup repository
setup_repository() {
    print_header "Setting Up Repository"
    
    # Set main branch
    git branch -M main
    
    # Add repository topics/tags
    if check_gh_cli; then
        gh repo edit --add-topic "odoo"
        gh repo edit --add-topic "enterprise"
        gh repo edit --add-topic "docker"
        gh repo edit --add-topic "deployment"
        gh repo edit --add-topic "automation"
        gh repo edit --add-topic "erp"
        gh repo edit --add-topic "postgresql"
        gh repo edit --add-topic "one-click"
        
        print_success "Repository topics added"
    fi
}

# Create release
create_release() {
    print_header "Creating Release"
    
    if check_gh_cli; then
        print_info "Creating v1.0.0 release..."
        
        gh release create v1.0.0 \
            --title "🚀 Odoo 19 Enterprise Deployment v1.0.0" \
            --notes "## 🎉 Initial Release

### ✨ Features
- **One-command deployment** - Deploy Odoo 19 Enterprise in minutes
- **719+ Enterprise modules** - Full enterprise feature set from GitHub
- **Docker-based architecture** - Clean, isolated deployment
- **Production-ready** - Optimized configuration for production use
- **Multi-server support** - Deploy on multiple servers easily
- **Management scripts** - Easy start/stop/backup/update commands
- **Automated backups** - Scheduled backups with retention
- **SSL support** - HTTPS configuration ready
- **Mobile-friendly** - Responsive interface

### 🚀 Quick Start
\`\`\`bash
curl -s https://raw.githubusercontent.com/Husen2012/odoo19-enterprise-deployment/main/deploy.sh | bash
\`\`\`

### 📦 What's Included
- **deploy.sh** - Main deployment script
- **manage.sh** - Service management
- **backup.sh** - Backup and restore
- **update.sh** - Update modules and containers
- **docker-compose.yml** - Container configuration
- **config/odoo.conf** - Odoo configuration
- **Complete documentation** - Installation and usage guides

### 🎯 Supported Platforms
- Ubuntu 20.04+
- Debian 10+
- CentOS 8+
- RHEL 8+
- Amazon Linux 2
- Rocky Linux 8+

### 🔧 Requirements
- 4GB RAM minimum (8GB recommended)
- 20GB disk space minimum (50GB recommended)
- Docker and Docker Compose
- GitHub Personal Access Token

### 📚 Documentation
- [Installation Guide](INSTALL.md)
- [README](README.md)
- [Configuration Reference](config/odoo.conf)

**Enjoy your Odoo 19 Enterprise deployment!** 🎊" \
            --latest
        
        print_success "Release v1.0.0 created!"
    else
        print_info "Create release manually at: https://github.com/Husen2012/odoo19-enterprise-deployment/releases/new"
    fi
}

# Display final information
display_final_info() {
    print_header "Repository Setup Complete!"
    
    echo -e "${GREEN}🎉 Your Odoo 19 Enterprise Deployment repository is ready!${NC}"
    echo ""
    echo -e "${YELLOW}Repository Information:${NC}"
    echo -e "  📦 Name: ${BLUE}odoo19-enterprise-deployment${NC}"
    echo -e "  🌐 URL: ${BLUE}https://github.com/Husen2012/odoo19-enterprise-deployment${NC}"
    echo -e "  📋 Description: One-command Odoo 19 Enterprise deployment"
    echo -e "  🏷️ Version: ${BLUE}v1.0.0${NC}"
    echo ""
    echo -e "${YELLOW}Quick Deployment Command:${NC}"
    echo -e "${CYAN}curl -s https://raw.githubusercontent.com/Husen2012/odoo19-enterprise-deployment/main/deploy.sh | bash${NC}"
    echo ""
    echo -e "${YELLOW}Repository Features:${NC}"
    echo -e "  ✅ One-command deployment"
    echo -e "  ✅ 719+ Enterprise modules"
    echo -e "  ✅ Docker-based architecture"
    echo -e "  ✅ Management scripts"
    echo -e "  ✅ Automated backups"
    echo -e "  ✅ Multi-server support"
    echo -e "  ✅ Production-ready"
    echo -e "  ✅ Complete documentation"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  1. ⭐ Star the repository"
    echo -e "  2. 📢 Share with others"
    echo -e "  3. 🧪 Test deployment on a server"
    echo -e "  4. 📝 Add more features"
    echo -e "  5. 🐛 Report issues"
    echo ""
    echo -e "${GREEN}🚀 Ready to deploy Odoo 19 Enterprise anywhere!${NC}"
}

# Main function
main() {
    print_banner
    
    check_git
    init_git
    add_files
    create_commit
    create_github_repo
    setup_repository
    create_release
    display_final_info
}

# Run main function
main "$@"
