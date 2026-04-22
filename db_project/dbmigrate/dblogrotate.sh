#!/bin/bash

LOGFILE="dbmigrate.log"
DATE=$(date +%Y-%m-%d)
ARCHIVE_DIR="./log_archive"
ARCHIVE_FILE="$ARCHIVE_DIR/dbmigrate.log.$DATE"

# ONLY ROTATE IF TODAY'S ARCHIVE DOESN'T EXIST
if [ ! -f "$ARCHIVE_FILE" ]; then
	mv "$LOGFILE" "$ARCHIVE_FILE" 	     # Move current day log to archive
	touch "$LOGFILE" 	             # Create fresh log for new day
fi
