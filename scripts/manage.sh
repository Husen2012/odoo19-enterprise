#!/bin/bash

#############################################
# Odoo 19 Enterprise Management Script
# Manage your Odoo deployment easily
#############################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to project directory
cd "$PROJECT_DIR"

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

# Check if docker-compose.yml exists
check_project() {
    if [[ ! -f "docker-compose.yml" ]]; then
        print_error "docker-compose.yml not found in $PROJECT_DIR"
        print_info "Make sure you're running this from the correct directory"
        exit 1
    fi
}

# Start services
start_services() {
    print_header "Starting Odoo 19 Enterprise"
    
    print_info "Pulling latest images..."
    docker compose pull
    
    print_info "Starting services..."
    docker compose up -d
    
    print_info "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    if docker compose ps | grep -q "healthy\|running"; then
        print_success "Services started successfully!"
        
        # Get server IP
        SERVER_IP=$(hostname -I | awk '{print $1}')
        MAIN_PORT=$(grep -E "^\s*-\s*\"[0-9]+:8069\"" docker-compose.yml | sed 's/.*"\([0-9]*\):8069".*/\1/')
        LONGPOLLING_PORT=$(grep -E "^\s*-\s*\"[0-9]+:8072\"" docker-compose.yml | sed 's/.*"\([0-9]*\):8072".*/\1/')
        
        echo ""
        echo -e "${GREEN}🌐 Access URLs:${NC}"
        echo -e "   Main Interface: ${BLUE}http://$SERVER_IP:$MAIN_PORT${NC}"
        echo -e "   Longpolling:    ${BLUE}http://$SERVER_IP:$LONGPOLLING_PORT${NC}"
        echo ""
    else
        print_error "Some services may not be healthy. Check logs with: $0 logs"
    fi
}

# Stop services
stop_services() {
    print_header "Stopping Odoo 19 Enterprise"
    
    print_info "Stopping services..."
    docker compose down
    
    print_success "Services stopped successfully!"
}

# Restart services
restart_services() {
    print_header "Restarting Odoo 19 Enterprise"
    
    print_info "Restarting services..."
    docker compose restart
    
    print_info "Waiting for services to be ready..."
    sleep 20
    
    print_success "Services restarted successfully!"
}

# Show service status
show_status() {
    print_header "Service Status"
    
    echo -e "${YELLOW}Container Status:${NC}"
    docker compose ps
    echo ""
    
    echo -e "${YELLOW}Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo ""
    
    echo -e "${YELLOW}Network Information:${NC}"
    docker network ls | grep -E "(NETWORK|odoo)"
    echo ""
    
    # Check if services are accessible
    SERVER_IP=$(hostname -I | awk '{print $1}')
    MAIN_PORT=$(grep -E "^\s*-\s*\"[0-9]+:8069\"" docker-compose.yml | sed 's/.*"\([0-9]*\):8069".*/\1/')
    
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$MAIN_PORT/web/health" | grep -q "200"; then
        echo -e "${GREEN}✅ Odoo is accessible${NC}"
    else
        echo -e "${RED}❌ Odoo is not accessible${NC}"
    fi
}

# Show logs
show_logs() {
    print_header "Service Logs"
    
    SERVICE=${2:-"odoo19"}
    LINES=${3:-"100"}
    
    case "$SERVICE" in
        odoo|odoo19)
            print_info "Showing Odoo logs (last $LINES lines)..."
            docker compose logs --tail="$LINES" -f odoo19
            ;;
        db|database|postgres)
            print_info "Showing Database logs (last $LINES lines)..."
            docker compose logs --tail="$LINES" -f db
            ;;
        all)
            print_info "Showing all logs (last $LINES lines)..."
            docker compose logs --tail="$LINES" -f
            ;;
        *)
            print_error "Unknown service: $SERVICE"
            print_info "Available services: odoo, db, all"
            exit 1
            ;;
    esac
}

# Execute command in container
exec_command() {
    print_header "Execute Command"
    
    SERVICE=${2:-"odoo19"}
    COMMAND=${3:-"/bin/bash"}
    
    print_info "Executing command in $SERVICE container..."
    docker compose exec "$SERVICE" $COMMAND
}

# Show help
show_help() {
    echo -e "${BLUE}Odoo 19 Enterprise Management Script${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 <command> [options]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  start                 Start all services"
    echo "  stop                  Stop all services"
    echo "  restart               Restart all services"
    echo "  status                Show service status"
    echo "  logs [service] [lines] Show logs (default: odoo, 100 lines)"
    echo "  exec [service] [cmd]  Execute command in container"
    echo "  shell [service]       Open shell in container"
    echo "  update                Update containers"
    echo "  backup                Create backup"
    echo "  restore <file>        Restore from backup"
    echo "  help                  Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 start              # Start all services"
    echo "  $0 logs odoo 50       # Show last 50 Odoo logs"
    echo "  $0 logs db            # Show database logs"
    echo "  $0 shell odoo19       # Open shell in Odoo container"
    echo "  $0 exec odoo19 'ls -la /mnt/enterprise-addons'"
    echo ""
    echo -e "${YELLOW}Services:${NC}"
    echo "  odoo19, odoo          Odoo application container"
    echo "  db, database, postgres PostgreSQL database container"
    echo "  all                   All services"
}

# Update containers
update_containers() {
    print_header "Updating Containers"
    
    print_info "Pulling latest images..."
    docker compose pull
    
    print_info "Recreating containers with new images..."
    docker compose up -d --force-recreate
    
    print_success "Containers updated successfully!"
}

# Create backup
create_backup() {
    print_header "Creating Backup"
    
    BACKUP_DIR="./backups"
    DATE=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$BACKUP_DIR"
    
    print_info "Creating database backup..."
    docker compose exec -T db pg_dumpall -U odoo > "$BACKUP_DIR/database_$DATE.sql"
    
    print_info "Creating filestore backup..."
    tar -czf "$BACKUP_DIR/filestore_$DATE.tar.gz" filestore/ 2>/dev/null || true
    
    print_info "Creating configuration backup..."
    tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" config/ docker-compose.yml 2>/dev/null || true
    
    print_success "Backup created successfully!"
    echo -e "Files created:"
    echo -e "  - Database: ${BLUE}$BACKUP_DIR/database_$DATE.sql${NC}"
    echo -e "  - Filestore: ${BLUE}$BACKUP_DIR/filestore_$DATE.tar.gz${NC}"
    echo -e "  - Config: ${BLUE}$BACKUP_DIR/config_$DATE.tar.gz${NC}"
}

# Restore backup
restore_backup() {
    if [[ -z "$2" ]]; then
        print_error "Please specify backup file to restore"
        print_info "Usage: $0 restore <backup_file>"
        print_info "Available backups:"
        ls -la backups/ 2>/dev/null || echo "No backups found"
        exit 1
    fi
    
    print_header "Restoring Backup"
    
    BACKUP_FILE="$2"
    
    if [[ ! -f "$BACKUP_FILE" ]]; then
        print_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi
    
    print_info "Stopping services..."
    docker compose down
    
    print_info "Restoring from $BACKUP_FILE..."
    # Add restore logic based on file type
    if [[ "$BACKUP_FILE" == *.sql ]]; then
        print_info "Restoring database..."
        docker compose up -d db
        sleep 10
        docker compose exec -T db psql -U odoo -d postgres < "$BACKUP_FILE"
    elif [[ "$BACKUP_FILE" == *filestore*.tar.gz ]]; then
        print_info "Restoring filestore..."
        tar -xzf "$BACKUP_FILE"
    fi
    
    print_info "Starting services..."
    docker compose up -d
    
    print_success "Backup restored successfully!"
}

# Open shell in container
open_shell() {
    SERVICE=${2:-"odoo19"}
    
    print_info "Opening shell in $SERVICE container..."
    docker compose exec "$SERVICE" /bin/bash
}

# Main function
main() {
    check_project
    
    case "$1" in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$@"
            ;;
        exec)
            exec_command "$@"
            ;;
        shell)
            open_shell "$@"
            ;;
        update)
            update_containers
            ;;
        backup)
            create_backup
            ;;
        restore)
            restore_backup "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
