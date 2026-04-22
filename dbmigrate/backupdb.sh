#!/bin/bash

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="logdb_backup_${TIMESTAMP}.sql"

echo "Starting database backup..."
echo "Using password: ********"

docker exec logapp-mariadb sh -c \
"mariadb-dump -u root -prootpassword logdb" > "$BACKUP_FILE"

echo "Backup complete: $BACKUP_FILE"
