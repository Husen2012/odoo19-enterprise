#!/bin/bash

#############################################
# Odoo 19 Enterprise Backup Script
# Create and manage backups
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
BACKUP_DIR="$PROJECT_DIR/backups"

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

# Create backup
create_backup() {
    print_header "Creating Backup"
    
    DATE=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$BACKUP_DIR"
    
    # Check if services are running
    if ! docker compose ps | grep -q "running"; then
        print_error "Services are not running. Please start them first."
        exit 1
    fi
    
    print_info "Creating database backup..."
    if docker compose exec -T db pg_dumpall -U odoo > "$BACKUP_DIR/database_$DATE.sql"; then
        print_success "Database backup created: database_$DATE.sql"
    else
        print_error "Failed to create database backup"
        exit 1
    fi
    
    print_info "Creating filestore backup..."
    if [[ -d "filestore" ]] && [[ "$(ls -A filestore)" ]]; then
        tar -czf "$BACKUP_DIR/filestore_$DATE.tar.gz" filestore/
        print_success "Filestore backup created: filestore_$DATE.tar.gz"
    else
        print_info "Filestore is empty, skipping..."
    fi
    
    print_info "Creating configuration backup..."
    tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" config/ docker-compose.yml .env 2>/dev/null
    print_success "Configuration backup created: config_$DATE.tar.gz"
    
    print_info "Creating enterprise modules backup..."
    if [[ -d "enterprise" ]] && [[ "$(ls -A enterprise)" ]]; then
        tar -czf "$BACKUP_DIR/enterprise_$DATE.tar.gz" enterprise/
        print_success "Enterprise modules backup created: enterprise_$DATE.tar.gz"
    else
        print_info "Enterprise directory is empty, skipping..."
    fi
    
    # Create complete backup archive
    print_info "Creating complete backup archive..."
    tar -czf "$BACKUP_DIR/complete_backup_$DATE.tar.gz" \
        -C "$BACKUP_DIR" \
        "database_$DATE.sql" \
        "filestore_$DATE.tar.gz" \
        "config_$DATE.tar.gz" \
        "enterprise_$DATE.tar.gz" 2>/dev/null
    
    # Calculate sizes
    DB_SIZE=$(du -h "$BACKUP_DIR/database_$DATE.sql" 2>/dev/null | cut -f1)
    FILESTORE_SIZE=$(du -h "$BACKUP_DIR/filestore_$DATE.tar.gz" 2>/dev/null | cut -f1)
    CONFIG_SIZE=$(du -h "$BACKUP_DIR/config_$DATE.tar.gz" 2>/dev/null | cut -f1)
    ENTERPRISE_SIZE=$(du -h "$BACKUP_DIR/enterprise_$DATE.tar.gz" 2>/dev/null | cut -f1)
    COMPLETE_SIZE=$(du -h "$BACKUP_DIR/complete_backup_$DATE.tar.gz" 2>/dev/null | cut -f1)
    
    print_success "Complete backup created successfully!"
    echo ""
    echo -e "${GREEN}Backup Summary:${NC}"
    echo -e "  Date: ${BLUE}$DATE${NC}"
    echo -e "  Database: ${BLUE}$DB_SIZE${NC}"
    echo -e "  Filestore: ${BLUE}$FILESTORE_SIZE${NC}"
    echo -e "  Configuration: ${BLUE}$CONFIG_SIZE${NC}"
    echo -e "  Enterprise Modules: ${BLUE}$ENTERPRISE_SIZE${NC}"
    echo -e "  Complete Archive: ${BLUE}$COMPLETE_SIZE${NC}"
    echo ""
    echo -e "${YELLOW}Backup Location:${NC} $BACKUP_DIR"
}

# List backups
list_backups() {
    print_header "Available Backups"
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        print_info "No backups found"
        return
    fi
    
    echo -e "${YELLOW}Complete Backups:${NC}"
    ls -lh "$BACKUP_DIR"/complete_backup_*.tar.gz 2>/dev/null | while read -r line; do
        echo "  $line"
    done
    echo ""
    
    echo -e "${YELLOW}Database Backups:${NC}"
    ls -lh "$BACKUP_DIR"/database_*.sql 2>/dev/null | while read -r line; do
        echo "  $line"
    done
    echo ""
    
    echo -e "${YELLOW}Filestore Backups:${NC}"
    ls -lh "$BACKUP_DIR"/filestore_*.tar.gz 2>/dev/null | while read -r line; do
        echo "  $line"
    done
    echo ""
    
    echo -e "${YELLOW}Configuration Backups:${NC}"
    ls -lh "$BACKUP_DIR"/config_*.tar.gz 2>/dev/null | while read -r line; do
        echo "  $line"
    done
    echo ""
    
    # Show total backup size
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo -e "${GREEN}Total Backup Size: ${BLUE}$TOTAL_SIZE${NC}"
}

# Restore backup
restore_backup() {
    if [[ -z "$2" ]]; then
        print_error "Please specify backup file to restore"
        print_info "Usage: $0 restore <backup_file>"
        echo ""
        list_backups
        exit 1
    fi
    
    BACKUP_FILE="$2"
    
    # Check if file exists (try both absolute and relative paths)
    if [[ ! -f "$BACKUP_FILE" ]] && [[ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]]; then
        print_error "Backup file not found: $BACKUP_FILE"
        print_info "Available backups:"
        list_backups
        exit 1
    fi
    
    # Use full path if relative path was provided
    if [[ ! -f "$BACKUP_FILE" ]] && [[ -f "$BACKUP_DIR/$BACKUP_FILE" ]]; then
        BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
    fi
    
    print_header "Restoring Backup"
    print_info "Backup file: $BACKUP_FILE"
    
    # Confirm restoration
    echo -e "${YELLOW}WARNING: This will overwrite existing data!${NC}"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Restoration cancelled"
        exit 0
    fi
    
    # Stop services
    print_info "Stopping services..."
    docker compose down
    
    # Determine backup type and restore accordingly
    if [[ "$BACKUP_FILE" == *complete_backup*.tar.gz ]]; then
        restore_complete_backup "$BACKUP_FILE"
    elif [[ "$BACKUP_FILE" == *database*.sql ]]; then
        restore_database_backup "$BACKUP_FILE"
    elif [[ "$BACKUP_FILE" == *filestore*.tar.gz ]]; then
        restore_filestore_backup "$BACKUP_FILE"
    elif [[ "$BACKUP_FILE" == *config*.tar.gz ]]; then
        restore_config_backup "$BACKUP_FILE"
    else
        print_error "Unknown backup type: $BACKUP_FILE"
        exit 1
    fi
    
    # Start services
    print_info "Starting services..."
    docker compose up -d
    
    print_success "Backup restored successfully!"
}

# Restore complete backup
restore_complete_backup() {
    local backup_file="$1"
    local temp_dir="/tmp/odoo_restore_$$"
    
    print_info "Extracting complete backup..."
    mkdir -p "$temp_dir"
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # Restore database
    if [[ -f "$temp_dir"/database_*.sql ]]; then
        print_info "Restoring database..."
        docker compose up -d db
        sleep 15
        docker compose exec -T db dropdb -U odoo --if-exists postgres
        docker compose exec -T db createdb -U odoo postgres
        docker compose exec -T db psql -U odoo -d postgres < "$temp_dir"/database_*.sql
    fi
    
    # Restore filestore
    if [[ -f "$temp_dir"/filestore_*.tar.gz ]]; then
        print_info "Restoring filestore..."
        rm -rf filestore/
        tar -xzf "$temp_dir"/filestore_*.tar.gz
    fi
    
    # Restore configuration
    if [[ -f "$temp_dir"/config_*.tar.gz ]]; then
        print_info "Restoring configuration..."
        tar -xzf "$temp_dir"/config_*.tar.gz
    fi
    
    # Restore enterprise modules
    if [[ -f "$temp_dir"/enterprise_*.tar.gz ]]; then
        print_info "Restoring enterprise modules..."
        rm -rf enterprise/
        tar -xzf "$temp_dir"/enterprise_*.tar.gz
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Restore database backup
restore_database_backup() {
    local backup_file="$1"
    
    print_info "Restoring database from $backup_file..."
    docker compose up -d db
    sleep 15
    
    # Drop and recreate database
    docker compose exec -T db dropdb -U odoo --if-exists postgres
    docker compose exec -T db createdb -U odoo postgres
    
    # Restore database
    docker compose exec -T db psql -U odoo -d postgres < "$backup_file"
}

# Restore filestore backup
restore_filestore_backup() {
    local backup_file="$1"
    
    print_info "Restoring filestore from $backup_file..."
    rm -rf filestore/
    tar -xzf "$backup_file"
}

# Restore configuration backup
restore_config_backup() {
    local backup_file="$1"
    
    print_info "Restoring configuration from $backup_file..."
    tar -xzf "$backup_file"
}

# Clean old backups
clean_backups() {
    print_header "Cleaning Old Backups"
    
    DAYS=${2:-30}
    
    print_info "Removing backups older than $DAYS days..."
    
    if [[ -d "$BACKUP_DIR" ]]; then
        find "$BACKUP_DIR" -name "*.sql" -mtime +$DAYS -delete
        find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$DAYS -delete
        
        print_success "Old backups cleaned successfully!"
    else
        print_info "No backup directory found"
    fi
}

# Schedule automatic backups
schedule_backups() {
    print_header "Scheduling Automatic Backups"
    
    SCHEDULE=${2:-"daily"}
    
    case "$SCHEDULE" in
        daily)
            CRON_TIME="0 2 * * *"
            ;;
        weekly)
            CRON_TIME="0 2 * * 0"
            ;;
        monthly)
            CRON_TIME="0 2 1 * *"
            ;;
        *)
            print_error "Invalid schedule: $SCHEDULE"
            print_info "Valid schedules: daily, weekly, monthly"
            exit 1
            ;;
    esac
    
    CRON_COMMAND="$PROJECT_DIR/scripts/backup.sh create"
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "$CRON_TIME $CRON_COMMAND") | crontab -
    
    print_success "Automatic backup scheduled: $SCHEDULE"
    print_info "Cron entry: $CRON_TIME $CRON_COMMAND"
}

# Show help
show_help() {
    echo -e "${BLUE}Odoo 19 Enterprise Backup Script${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 <command> [options]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  create                Create complete backup"
    echo "  list                  List available backups"
    echo "  restore <file>        Restore from backup"
    echo "  clean [days]          Clean backups older than N days (default: 30)"
    echo "  schedule <frequency>  Schedule automatic backups (daily/weekly/monthly)"
    echo "  help                  Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 create                                    # Create backup"
    echo "  $0 list                                      # List backups"
    echo "  $0 restore complete_backup_20251004_143022.tar.gz"
    echo "  $0 restore database_20251004_143022.sql"
    echo "  $0 clean 7                                   # Clean backups older than 7 days"
    echo "  $0 schedule daily                            # Schedule daily backups"
}

# Main function
main() {
    case "$1" in
        create)
            create_backup
            ;;
        list)
            list_backups
            ;;
        restore)
            restore_backup "$@"
            ;;
        clean)
            clean_backups "$@"
            ;;
        schedule)
            schedule_backups "$@"
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
