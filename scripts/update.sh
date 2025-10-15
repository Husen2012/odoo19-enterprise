#!/bin/bash

#############################################
# Odoo 19 Enterprise Update Script
# Update enterprise modules and containers
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

# Update enterprise modules
update_modules() {
    print_header "Updating Enterprise Modules"
    
    if [[ ! -d "enterprise/.git" ]]; then
        print_error "Enterprise directory is not a git repository"
        print_info "Please ensure enterprise modules were cloned properly"
        exit 1
    fi
    
    cd enterprise
    
    print_info "Fetching latest changes from GitHub..."
    git fetch origin
    
    print_info "Checking current branch..."
    CURRENT_BRANCH=$(git branch --show-current)
    print_info "Current branch: $CURRENT_BRANCH"
    
    if [[ "$CURRENT_BRANCH" != "19.0" ]]; then
        print_info "Switching to branch 19.0..."
        git checkout 19.0
    fi
    
    print_info "Pulling latest changes..."
    if git pull origin 19.0; then
        print_success "Enterprise modules updated successfully"
        
        # Count modules
        MODULE_COUNT=$(ls -1 | grep -v "^\." | wc -l)
        print_info "Total modules: $MODULE_COUNT"
        
        # Show recent changes
        print_info "Recent changes:"
        git log --oneline -5
        
    else
        print_error "Failed to update enterprise modules"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    
    # Restart Odoo to load updated modules
    print_info "Restarting Odoo to load updated modules..."
    docker compose restart odoo19
    
    print_success "Enterprise modules update completed!"
}

# Update Odoo container
update_odoo() {
    print_header "Updating Odoo Container"
    
    print_info "Pulling latest Odoo 19 image..."
    if docker compose pull odoo19; then
        print_success "Odoo image updated successfully"
    else
        print_error "Failed to pull Odoo image"
        exit 1
    fi
    
    print_info "Recreating Odoo container..."
    docker compose up -d --force-recreate odoo19
    
    print_info "Waiting for Odoo to start..."
    sleep 30
    
    # Check if Odoo is healthy
    if docker compose ps odoo19 | grep -q "healthy\|running"; then
        print_success "Odoo container updated and running"
    else
        print_error "Odoo container may not be healthy"
        print_info "Check logs with: ./manage.sh logs odoo"
    fi
}

# Update PostgreSQL container
update_database() {
    print_header "Updating PostgreSQL Container"
    
    print_info "Creating database backup before update..."
    ./scripts/backup.sh create
    
    print_info "Pulling latest PostgreSQL 17 image..."
    if docker compose pull db; then
        print_success "PostgreSQL image updated successfully"
    else
        print_error "Failed to pull PostgreSQL image"
        exit 1
    fi
    
    print_info "Recreating database container..."
    docker compose up -d --force-recreate db
    
    print_info "Waiting for database to start..."
    sleep 20
    
    # Check if database is healthy
    if docker compose ps db | grep -q "healthy\|running"; then
        print_success "Database container updated and running"
    else
        print_error "Database container may not be healthy"
        print_info "Check logs with: ./manage.sh logs db"
    fi
}

# Update all components
update_all() {
    print_header "Updating All Components"
    
    print_info "Creating backup before updates..."
    ./scripts/backup.sh create
    
    print_info "Step 1: Updating enterprise modules..."
    update_modules
    
    print_info "Step 2: Updating containers..."
    docker compose pull
    docker compose up -d --force-recreate
    
    print_info "Waiting for all services to start..."
    sleep 45
    
    # Check service health
    if docker compose ps | grep -q "healthy\|running"; then
        print_success "All components updated successfully!"
        
        # Show version information
        print_info "Current versions:"
        echo -e "  Odoo: ${BLUE}$(docker compose exec -T odoo19 odoo --version 2>/dev/null | head -1)${NC}"
        echo -e "  PostgreSQL: ${BLUE}$(docker compose exec -T db psql --version 2>/dev/null)${NC}"
        
        # Show module count
        MODULE_COUNT=$(docker compose exec -T odoo19 ls -1 /mnt/enterprise-addons/ 2>/dev/null | wc -l)
        echo -e "  Enterprise Modules: ${BLUE}$MODULE_COUNT${NC}"
        
    else
        print_error "Some services may not be healthy after update"
        print_info "Check status with: ./manage.sh status"
    fi
}

# Check for updates
check_updates() {
    print_header "Checking for Updates"
    
    # Check enterprise modules
    if [[ -d "enterprise/.git" ]]; then
        cd enterprise
        git fetch origin
        
        LOCAL_COMMIT=$(git rev-parse HEAD)
        REMOTE_COMMIT=$(git rev-parse origin/19.0)
        
        if [[ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]]; then
            print_info "Enterprise modules updates available"
            echo -e "  Local:  ${BLUE}$LOCAL_COMMIT${NC}"
            echo -e "  Remote: ${BLUE}$REMOTE_COMMIT${NC}"
            
            # Show what's new
            print_info "New commits:"
            git log --oneline $LOCAL_COMMIT..$REMOTE_COMMIT | head -5
        else
            print_success "Enterprise modules are up to date"
        fi
        
        cd "$PROJECT_DIR"
    else
        print_info "Enterprise modules not found or not a git repository"
    fi
    
    # Check container images
    print_info "Checking for container updates..."
    
    # Get current image IDs
    CURRENT_ODOO_ID=$(docker images --format "{{.ID}}" odoo:19 | head -1)
    CURRENT_POSTGRES_ID=$(docker images --format "{{.ID}}" postgres:17 | head -1)
    
    # Pull latest images (without updating containers)
    docker pull odoo:19 >/dev/null 2>&1
    docker pull postgres:17 >/dev/null 2>&1
    
    # Get new image IDs
    NEW_ODOO_ID=$(docker images --format "{{.ID}}" odoo:19 | head -1)
    NEW_POSTGRES_ID=$(docker images --format "{{.ID}}" postgres:17 | head -1)
    
    if [[ "$CURRENT_ODOO_ID" != "$NEW_ODOO_ID" ]]; then
        print_info "Odoo container update available"
    else
        print_success "Odoo container is up to date"
    fi
    
    if [[ "$CURRENT_POSTGRES_ID" != "$NEW_POSTGRES_ID" ]]; then
        print_info "PostgreSQL container update available"
    else
        print_success "PostgreSQL container is up to date"
    fi
}

# Rollback to previous version
rollback() {
    print_header "Rolling Back Updates"
    
    if [[ -z "$2" ]]; then
        print_error "Please specify what to rollback"
        print_info "Usage: $0 rollback [modules|containers|all]"
        exit 1
    fi
    
    case "$2" in
        modules)
            rollback_modules
            ;;
        containers)
            rollback_containers
            ;;
        all)
            rollback_all
            ;;
        *)
            print_error "Invalid rollback option: $2"
            print_info "Valid options: modules, containers, all"
            exit 1
            ;;
    esac
}

# Rollback enterprise modules
rollback_modules() {
    print_info "Rolling back enterprise modules..."
    
    if [[ ! -d "enterprise/.git" ]]; then
        print_error "Enterprise directory is not a git repository"
        exit 1
    fi
    
    cd enterprise
    
    # Show recent commits
    print_info "Recent commits:"
    git log --oneline -10
    
    echo ""
    read -p "Enter commit hash to rollback to: " COMMIT_HASH
    
    if [[ -n "$COMMIT_HASH" ]]; then
        git reset --hard "$COMMIT_HASH"
        print_success "Enterprise modules rolled back to $COMMIT_HASH"
        
        cd "$PROJECT_DIR"
        docker compose restart odoo19
    else
        print_info "Rollback cancelled"
    fi
}

# Rollback containers
rollback_containers() {
    print_info "Rolling back containers..."
    
    # List available backups
    print_info "Available backups:"
    ls -la backups/complete_backup_*.tar.gz 2>/dev/null || {
        print_error "No complete backups found"
        exit 1
    }
    
    echo ""
    read -p "Enter backup filename to restore: " BACKUP_FILE
    
    if [[ -n "$BACKUP_FILE" ]]; then
        ./scripts/backup.sh restore "$BACKUP_FILE"
    else
        print_info "Rollback cancelled"
    fi
}

# Rollback all
rollback_all() {
    print_info "Rolling back all components..."
    rollback_containers
}

# Show help
show_help() {
    echo -e "${BLUE}Odoo 19 Enterprise Update Script${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 <command> [options]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  modules               Update enterprise modules from GitHub"
    echo "  odoo                  Update Odoo container"
    echo "  database              Update PostgreSQL container"
    echo "  all                   Update all components"
    echo "  check                 Check for available updates"
    echo "  rollback <component>  Rollback updates (modules/containers/all)"
    echo "  help                  Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 modules            # Update enterprise modules"
    echo "  $0 odoo               # Update Odoo container"
    echo "  $0 all                # Update everything"
    echo "  $0 check              # Check for updates"
    echo "  $0 rollback modules   # Rollback module updates"
}

# Main function
main() {
    case "$1" in
        modules)
            update_modules
            ;;
        odoo)
            update_odoo
            ;;
        database|db)
            update_database
            ;;
        all)
            update_all
            ;;
        check)
            check_updates
            ;;
        rollback)
            rollback "$@"
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
