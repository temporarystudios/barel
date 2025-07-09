#!/bin/bash
set -euo pipefail

BACKUP_DIR="/workspace/backups"

# Check if backup file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file>"
    echo ""
    echo "Available backups:"
    ls -la "$BACKUP_DIR"/supabase_backup_*.sql 2>/dev/null || echo "No backups found in $BACKUP_DIR"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Restoring database from: $BACKUP_FILE"
echo "===================================="
echo "⚠️  WARNING: This will replace all current data!"
read -p "Are you sure you want to continue? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

# Restore the backup
echo "Restoring database..."
PGPASSWORD="${POSTGRES_PASSWORD}" psql \
    -h db \
    -p 5432 \
    -U postgres \
    -d postgres \
    < "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Database restored successfully!"
    echo ""
    echo "You may need to restart the Supabase services:"
    echo "  docker-compose restart"
else
    echo "❌ Restore failed!"
    exit 1
fi