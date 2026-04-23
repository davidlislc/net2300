#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$SCRIPT_DIR/backup_${TIMESTAMP}.sql"
DB_HOST="127.0.0.1"
DB_USER="root"
DB_PASS="rootpassword"
DB_NAME="logdb"

echo "Running: mysqldump -h $DB_HOST -u $DB_USER -p****** $DB_NAME > $BACKUP_FILE"

mysqldump --column-statistics=0 -h $DB_HOST -u$DB_USER -p$DB_PASS $DB_NAME > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
  echo "Backup successful: $BACKUP_FILE"
else
  echo "Backup failed"
fi
