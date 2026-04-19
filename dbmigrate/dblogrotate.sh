#!/bin/bash

LOG_DIR="/path/to/your/project" # Update this to your actual project path
LOG_FILE="$LOG_DIR/dbmigrate.log"
TIMESTAMP=$(date +%Y%m%d)

if [ -f "$LOG_FILE" ]; then
    mv "$LOG_FILE" "${LOG_FILE}_${TIMESTAMP}"
    touch "$LOG_FILE"
    chmod 664 "$LOG_FILE"
    echo "Log rotated on $(date)" >> "$LOG_FILE"
fi
