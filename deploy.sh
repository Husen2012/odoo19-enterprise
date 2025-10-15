#!/bin/bash

#############################################
# Odoo 19 Enterprise Deployment Script
# One-command deployment on any server
# Repository: https://github.com/Husen2012/odoo19-enterprise-deployment
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Version
VERSION="1.0.0"

# Default configuration
DEFAULT_MAIN_PORT="10024"
DEFAULT_LONGPOLLING_PORT="20024"
DEFAULT_DB_PASSWORD="odoo19enterprise@$(date +%Y)"
DEFAULT_ADMIN_PASSWORD="Enterprise@$(date +%Y)"
DEFAULT_INSTALL_DIR="/opt/odoo19-enterprise"
DEFAULT_GITHUB_REPO="https://github.com/odoo/enterprise.git"
DEFAULT_BRANCH="19.0"

# Functions
print_banner() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║        🚀 Odoo 19 Enterprise Deployment v${VERSION}         ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║        📦 719+ Enterprise Modules                         ║${NC}"
    echo -e "${CYAN}║        🐳 Docker-based Deployment                         ║${NC}"
    echo -e "${CYAN}║        ⚡ One-command Setup                               ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================${NC}"
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

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_info "Running as root user"
    else
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Cannot detect operating system"
        exit 1
    fi
    
    print_info "Detected OS: $OS $VER"
}

# Install Docker
install_docker() {
    print_step "Installing Docker..."
    
    if command -v docker &> /dev/null; then
        print_info "Docker already installed: $(docker --version)"
        return
    fi
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    
    # Start Docker service
    systemctl start docker
    systemctl enable docker
    
    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    print_success "Docker installed successfully"
}

# Get configuration
get_configuration() {
    print_header "Configuration Setup"
    
    # Check for command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto)
                AUTO_MODE=true
                shift
                ;;
            --github-user)
                GITHUB_USER="$2"
                shift 2
                ;;
            --github-token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            --main-port)
                MAIN_PORT="$2"
                shift 2
                ;;
            --longpolling-port)
                LONGPOLLING_PORT="$2"
                shift 2
                ;;
            --db-password)
                DB_PASSWORD="$2"
                shift 2
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --env)
                ENV_MODE=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Use environment variables if ENV_MODE
    if [[ "$ENV_MODE" == "true" ]]; then
        GITHUB_USER=${GITHUB_USER:-$GITHUB_USER}
        GITHUB_TOKEN=${GITHUB_TOKEN:-$GITHUB_TOKEN}
        MAIN_PORT=${MAIN_PORT:-$DEFAULT_MAIN_PORT}
        LONGPOLLING_PORT=${LONGPOLLING_PORT:-$DEFAULT_LONGPOLLING_PORT}
        DB_PASSWORD=${DB_PASSWORD:-$DEFAULT_DB_PASSWORD}
        ADMIN_PASSWORD=${ADMIN_PASSWORD:-$DEFAULT_ADMIN_PASSWORD}
        INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}
        return
    fi
    
    # Interactive mode if not auto
    if [[ "$AUTO_MODE" != "true" ]]; then
        echo -e "${YELLOW}Please provide the following information:${NC}"
        echo ""
        
        read -p "GitHub Username: " GITHUB_USER
        read -sp "GitHub Token (Personal Access Token): " GITHUB_TOKEN
        echo ""
        
        read -p "Main Port [$DEFAULT_MAIN_PORT]: " MAIN_PORT
        MAIN_PORT=${MAIN_PORT:-$DEFAULT_MAIN_PORT}
        
        read -p "Longpolling Port [$DEFAULT_LONGPOLLING_PORT]: " LONGPOLLING_PORT
        LONGPOLLING_PORT=${LONGPOLLING_PORT:-$DEFAULT_LONGPOLLING_PORT}
        
        read -p "Installation Directory [$DEFAULT_INSTALL_DIR]: " INSTALL_DIR
        INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}
        
        read -sp "Database Password [$DEFAULT_DB_PASSWORD]: " DB_PASSWORD
        DB_PASSWORD=${DB_PASSWORD:-$DEFAULT_DB_PASSWORD}
        echo ""
        
        read -sp "Admin Password [$DEFAULT_ADMIN_PASSWORD]: " ADMIN_PASSWORD
        ADMIN_PASSWORD=${ADMIN_PASSWORD:-$DEFAULT_ADMIN_PASSWORD}
        echo ""
    else
        # Set defaults for auto mode
        MAIN_PORT=${MAIN_PORT:-$DEFAULT_MAIN_PORT}
        LONGPOLLING_PORT=${LONGPOLLING_PORT:-$DEFAULT_LONGPOLLING_PORT}
        DB_PASSWORD=${DB_PASSWORD:-$DEFAULT_DB_PASSWORD}
        ADMIN_PASSWORD=${ADMIN_PASSWORD:-$DEFAULT_ADMIN_PASSWORD}
        INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}
    fi
    
    # Validate required parameters
    if [[ -z "$GITHUB_USER" || -z "$GITHUB_TOKEN" ]]; then
        print_error "GitHub username and token are required!"
        exit 1
    fi
    
    print_success "Configuration completed"
}

# Check port availability
check_ports() {
    print_step "Checking port availability..."
    
    if netstat -tulpn | grep -q ":$MAIN_PORT "; then
        print_error "Port $MAIN_PORT is already in use"
        exit 1
    fi
    
    if netstat -tulpn | grep -q ":$LONGPOLLING_PORT "; then
        print_error "Port $LONGPOLLING_PORT is already in use"
        exit 1
    fi
    
    print_success "Ports $MAIN_PORT and $LONGPOLLING_PORT are available"
}

# Create directory structure
create_directories() {
    print_step "Creating directory structure..."
    
    mkdir -p $INSTALL_DIR/{addons,enterprise,etc,filestore,sessions,postgresql,ssl,backups,scripts}
    chmod 777 $INSTALL_DIR/filestore
    chmod 777 $INSTALL_DIR/sessions
    
    print_success "Directory structure created at $INSTALL_DIR"
}

# Clone enterprise repository
clone_enterprise() {
    print_step "Cloning Odoo Enterprise repository..."
    
    cd $INSTALL_DIR
    
    if [[ -d "enterprise/.git" ]]; then
        print_info "Enterprise repository exists, updating..."
        cd enterprise
        git pull origin $DEFAULT_BRANCH
        cd ..
    else
        print_info "Cloning enterprise repository (this may take 5-10 minutes)..."
        git clone -b $DEFAULT_BRANCH https://$GITHUB_USER:$GITHUB_TOKEN@github.com/odoo/enterprise.git enterprise
    fi
    
    # Verify clone
    MODULE_COUNT=$(ls -1 enterprise | wc -l)
    if [[ $MODULE_COUNT -gt 500 ]]; then
        print_success "Enterprise modules cloned successfully: $MODULE_COUNT modules"
    else
        print_error "Enterprise clone failed or incomplete"
        exit 1
    fi
}

# Create configuration files
create_config() {
    print_step "Creating configuration files..."
    
    # Create odoo.conf
    cat > $INSTALL_DIR/etc/odoo.conf << EOF
[options]
admin_passwd = $ADMIN_PASSWORD
db_host = db
db_port = 5432
db_user = odoo
db_password = $DB_PASSWORD
db_maxconn = 64
db_template = template0
addons_path = /mnt/enterprise-addons,/usr/lib/python3/dist-packages/odoo/addons
workers = 4
max_cron_threads = 2
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
log_level = info
log_handler = :INFO
list_db = True
proxy_mode = True
http_enable = True
http_interface = 0.0.0.0
http_port = 8069
unaccent = True
without_demo = True
data_dir = /var/lib/odoo
EOF
    
    # Create docker-compose.yml
    cat > $INSTALL_DIR/docker-compose.yml << EOF
version: '3.8'

services:
  db:
    image: postgres:17
    container_name: odoo19-enterprise-db
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_USER=odoo
      - POSTGRES_PASSWORD=$DB_PASSWORD
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - ./postgresql:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U odoo"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - odoo_network

  odoo19:
    image: odoo:19
    container_name: odoo19-enterprise
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "$MAIN_PORT:8069"
      - "$LONGPOLLING_PORT:8072"
    volumes:
      - ./addons:/mnt/extra-addons
      - ./enterprise:/mnt/enterprise-addons
      - ./etc:/etc/odoo
      - ./sessions:/var/lib/odoo/sessions
      - ./filestore:/var/lib/odoo/filestore
      - ./ssl:/etc/ssl/odoo:ro
    environment:
      - HOST=db
      - PORT=5432
      - USER=odoo
      - PASSWORD=$DB_PASSWORD
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8069/web/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    networks:
      - odoo_network
    deploy:
      resources:
        limits:
          memory: 2560M
        reservations:
          memory: 2048M

networks:
  odoo_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.35.0.0/16
EOF
    
    print_success "Configuration files created"
}

# Create management scripts
create_scripts() {
    print_step "Creating management scripts..."
    
    # Create manage.sh
    cat > $INSTALL_DIR/scripts/manage.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/.."

case "$1" in
    start)
        echo "Starting Odoo 19 Enterprise..."
        docker compose up -d
        ;;
    stop)
        echo "Stopping Odoo 19 Enterprise..."
        docker compose down
        ;;
    restart)
        echo "Restarting Odoo 19 Enterprise..."
        docker compose restart
        ;;
    status)
        echo "=== Container Status ==="
        docker compose ps
        ;;
    logs)
        docker compose logs -f "${2:-odoo19}"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
EOF
    
    # Create backup.sh
    cat > $INSTALL_DIR/scripts/backup.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/.."
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

case "$1" in
    create)
        echo "Creating backup..."
        mkdir -p $BACKUP_DIR
        docker compose exec -T db pg_dumpall -U odoo > "$BACKUP_DIR/db_$DATE.sql"
        tar -czf "$BACKUP_DIR/filestore_$DATE.tar.gz" filestore/
        echo "Backup created: $DATE"
        ;;
    list)
        echo "Available backups:"
        ls -la $BACKUP_DIR/
        ;;
    restore)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 restore <backup_file>"
            exit 1
        fi
        echo "Restoring backup: $2"
        # Add restore logic here
        ;;
    *)
        echo "Usage: $0 {create|list|restore}"
        exit 1
        ;;
esac
EOF
    
    # Create update.sh
    cat > $INSTALL_DIR/scripts/update.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/.."

case "$1" in
    modules)
        echo "Updating enterprise modules..."
        cd enterprise
        git pull origin 19.0
        cd ..
        docker compose restart odoo19
        ;;
    odoo)
        echo "Updating Odoo container..."
        docker compose pull odoo19
        docker compose up -d odoo19
        ;;
    all)
        echo "Updating everything..."
        $0 modules
        $0 odoo
        ;;
    *)
        echo "Usage: $0 {modules|odoo|all}"
        exit 1
        ;;
esac
EOF
    
    # Make scripts executable
    chmod +x $INSTALL_DIR/scripts/*.sh
    
    # Create symlinks in install directory
    ln -sf scripts/manage.sh $INSTALL_DIR/manage.sh
    ln -sf scripts/backup.sh $INSTALL_DIR/backup.sh
    ln -sf scripts/update.sh $INSTALL_DIR/update.sh
    
    print_success "Management scripts created"
}

# Deploy services
deploy_services() {
    print_step "Deploying services..."
    
    cd $INSTALL_DIR
    
    # Pull images
    docker compose pull
    
    # Start services
    docker compose up -d
    
    print_success "Services deployed"
}

# Wait for services
wait_for_services() {
    print_step "Waiting for services to start..."
    
    sleep 30
    
    # Check if services are healthy
    cd $INSTALL_DIR
    if docker compose ps | grep -q "healthy"; then
        print_success "Services are healthy"
    else
        print_error "Services may not be healthy, check logs"
    fi
}

# Display final information
display_final_info() {
    print_header "Deployment Complete!"
    echo ""
    print_success "Odoo 19 Enterprise deployed successfully!"
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Access Information${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "🌐 Main Interface:    ${BLUE}http://$(hostname -I | awk '{print $1}'):$MAIN_PORT${NC}"
    echo -e "🔗 Longpolling:       ${BLUE}http://$(hostname -I | awk '{print $1}'):$LONGPOLLING_PORT${NC}"
    echo -e "🔑 Master Password:   ${BLUE}$ADMIN_PASSWORD${NC}"
    echo -e "💾 Database User:     ${BLUE}odoo${NC}"
    echo -e "🔐 Database Password: ${BLUE}$DB_PASSWORD${NC}"
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Management Commands${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "Start:    ${CYAN}cd $INSTALL_DIR && ./manage.sh start${NC}"
    echo -e "Stop:     ${CYAN}cd $INSTALL_DIR && ./manage.sh stop${NC}"
    echo -e "Restart:  ${CYAN}cd $INSTALL_DIR && ./manage.sh restart${NC}"
    echo -e "Status:   ${CYAN}cd $INSTALL_DIR && ./manage.sh status${NC}"
    echo -e "Logs:     ${CYAN}cd $INSTALL_DIR && ./manage.sh logs${NC}"
    echo -e "Backup:   ${CYAN}cd $INSTALL_DIR && ./backup.sh create${NC}"
    echo -e "Update:   ${CYAN}cd $INSTALL_DIR && ./update.sh all${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Next Steps:${NC}"
    echo "1. Open the web interface in your browser"
    echo "2. Create your first database"
    echo "3. Install enterprise modules (Apps → Update Apps List)"
    echo "4. Configure SSL (optional)"
    echo ""
    echo -e "${PURPLE}🎉 Enjoy your Odoo 19 Enterprise with 719+ modules!${NC}"
}

# Main deployment function
main() {
    print_banner
    
    check_root
    detect_os
    install_docker
    get_configuration "$@"
    check_ports
    create_directories
    clone_enterprise
    create_config
    create_scripts
    deploy_services
    wait_for_services
    display_final_info
}

# Run main function with all arguments
main "$@"
