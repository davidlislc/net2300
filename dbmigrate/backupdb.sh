#!/bin/bash

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="backup_$TIMESTAMP.sql"

docker exec logapp-mariadb sh -c "mariadb-dump -u root -prootpassword logdb > /$BACKUP_FILE"

MASKED_CMD="mariadb-dump -u root -p****** logdb > $BACKUP_FILE"

echo "[$(date)] Executed: $MASKED_CMD"
echo "Backup created: $BACKUP_FILE"
