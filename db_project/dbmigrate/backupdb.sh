#!/bin/bash

# --- Configurations ---
DB_HOST="127.0.0.1"
DB_USER="root"
DB_PASS="rootpassword"
DB_NAME="logdb"
ARCHIVE_PATH="./sql_archive"

# --- Timestamped Output File ---
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
OUTPUT_FILE="$ARCHIVE_PATH/backup_{$TIMESTAMP}.sql"

# --- Terminal Display ---
echo "=== Starting Database Backup ==="
echo "Database: $DB_NAME"
echo "Host: $DB_HOST"
echo "User: $DB_USER"
echo "Password: *******"
echo "Output File: $OUTPUT_FILE"

# --- Backup Execution ---
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$OUTPUT_FILE"

# --- Execution Status ---
STATUS=$?

if [ $STATUS -eq 0 ]; then
	echo "Backup Completed Successfully."
	echo "Backup File Created: $OUTPUT_FILE"
else
	echo "Backup FAILED with exit code: $STATUS"
fi
