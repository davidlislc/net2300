#!/bin/bash

LOG_FILE="dbmigrate.log"
ARCHIVE_DIR="logs_archive"

mkdir -p $ARCHIVE_DIR

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

if [ -f "$LOG_FILE" ]; then
    mv $LOG_FILE $ARCHIVE_DIR/dbmigrate_$TIMESTAMP.log
    touch $LOG_FILE
fi
