#!/bin/bash
set -euo pipefail

BACKUP_DIR="/workspace/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/supabase_backup_$TIMESTAMP.sql"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Creating database backup..."
echo "=========================="

# Create backup
PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump \
    -h db \
    -p 5432 \
    -U postgres \
    -d postgres \
    --no-owner \
    --clean \
    --if-exists \
    > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup created successfully: $BACKUP_FILE"
    echo "File size: $(du -h "$BACKUP_FILE" | cut -f1)"
    
    # Keep only the last 5 backups
    echo "Cleaning up old backups..."
    ls -t "$BACKUP_DIR"/supabase_backup_*.sql 2>/dev/null | tail -n +6 | xargs -r rm -f
    echo "✅ Cleanup complete"
else
    echo "❌ Backup failed!"
    exit 1
fi