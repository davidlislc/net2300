#!/bin/bash

# Configuration
DB_HOST="127.0.0.1"
DB_USER="logapp"
DB_PASS="logapp123"
DB_NAME="logdb"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_${DB_NAME}_${TIMESTAMP}.sql"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Masked Password for Logging
MASKED_PASS="********"

echo "[$(date)] Starting backup for $DB_NAME..."
echo "[$(date)] Using command: mysqldump -h $DB_HOST -u $DB_USER -p$MASKED_PASS $DB_NAME > $BACKUP_FILE"

# Execute the dump
export MYSQL_PWD="$DB_PASS"
mysqldump --column-statistics=0 -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"
EXIT_CODE=$?
unset MYSQL_PWD

if [ $EXIT_CODE -eq 0 ]; then
    echo "[$(date)] Backup successful: $BACKUP_FILE"
    exit 0
else
    echo "[$(date)] Backup failed with exit code $EXIT_CODE"
    exit 1
fi
