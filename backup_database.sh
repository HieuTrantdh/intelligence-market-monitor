#!/bin/bash
# ============================================================================
# Intelligence Market Monitor - Database Backup Script
# ============================================================================
# Usage: ./backup_database.sh
# Backups database to: backups/intelligence_market_YYYY-MM-DD_HH-MM-SS.sql
# ============================================================================

# Load environment variables
source .env

# Create backups directory if not exists
mkdir -p backups

# Generate backup filename with timestamp
BACKUP_FILENAME="backups/intelligence_market_$(date +%Y-%m-%d_%H-%M-%S).sql"

# Run pg_dump
echo " Starting backup of database: $DB_NAME..."
export PGPASSWORD="$DB_PASS"
pg_dump \
  --host "$DB_HOST" \
  --port "$DB_PORT" \
  --username "$DB_USER" \
  --no-password \
  --verbose \
  $DB_NAME > "$BACKUP_FILENAME"

unset PGPASSWORD
# Check if backup was successful
if [ $? -eq 0 ]; then
    echo " Backup successful: $BACKUP_FILENAME"
    echo " File size: $(du -h "$BACKUP_FILENAME" | cut -f1)"
else
    echo " Backup failed!"
    exit 1
fi

# Optional: Keep only last 10 backups (cleanup old ones)
BACKUP_COUNT=$(ls -1 backups/ | wc -l)
if [ "$BACKUP_COUNT" -gt 10 ]; then
    echo "Cleaning up old backups (keeping last 10)..."
    ls -t backups/ | tail -n +11 | xargs -I {} rm backups/{}
fi

echo " Done!"
