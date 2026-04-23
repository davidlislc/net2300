#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGFILE="$SCRIPT_DIR/dbmigrate.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE="$SCRIPT_DIR/dbmigrate_${TIMESTAMP}.log.gz"

if [ -f "$LOGFILE" ]; then
  gzip -c "$LOGFILE" > "$ARCHIVE"
  > "$LOGFILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Rotated to $ARCHIVE" >> "$LOGFILE"
fi
