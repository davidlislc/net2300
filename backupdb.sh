#!/bin/bash

# Configuration
CONTAINER="docker-compose-db-1"
DB_USER="root"
DB_PASS="somewordpress"
DB_NAME="wordpress"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${TIMESTAMP}.sql"

# Masked Password for log security
MASKED_PASS="**********"

echo "Starting automated backup for database: ${DB_NAME}..."
echo "Using password: ${MASKED_PASS}"

# Execute the dump via Docker container
docker exec $CONTAINER mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "Backup successful: ${BACKUP_FILE}"
else
    echo "Backup failed! Ensure the database container is healthy."
    exit 1
fi
