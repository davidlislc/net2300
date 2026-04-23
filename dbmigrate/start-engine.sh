#!/bin/bash
DB_USER="logapp"
DB_PASS="logapp123"
DB_NAME="logdb"
DB_HOST="127.0.0.1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGFILE="$SCRIPT_DIR/dbmigrate.log"
LAST_ROTATE=""

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ====== start-engine started (PID=$$) ======"

while true; do
  # Check if it's midnight and we haven't rotated yet today
  CURRENT_HOUR=$(date +"%H")
  TODAY=$(date +"%Y%m%d")
  if [ "$CURRENT_HOUR" = "00" ] && [ "$LAST_ROTATE" != "$TODAY" ]; then
    bash "$SCRIPT_DIR/dblogrotate.sh"
    LAST_ROTATE="$TODAY"
  fi

  data=$(mysql -h $DB_HOST -u$DB_USER -p$DB_PASS $DB_NAME -Nse \
    "SELECT id, message FROM logs WHERE status='pending';" 2>/dev/null)

  if [ -n "$data" ]; then
    while IFS=$'\t' read -r id cmd; do
      [ -z "$id" ] && continue
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Processing id=$id cmd='$cmd'"
      output=$(bash -c "$cmd" 2>&1)
      result=$?
      cmd_esc=$(echo "$cmd" | sed "s/'/''/g")
      output_esc=$(echo "$output" | sed "s/'/''/g")
      mysql -h $DB_HOST -u$DB_USER -p$DB_PASS $DB_NAME -e \
        "UPDATE logs SET status=IF($result=0,'done','error') WHERE id=$id;" 2>/dev/null
      mysql -h $DB_HOST -u$DB_USER -p$DB_PASS $DB_NAME -e \
        "INSERT INTO execution_log (log_id, command, output, exit_code)
         VALUES ($id, '$cmd_esc', '$output_esc', $result);" 2>/dev/null
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] exit=$result id=$id cmd='$cmd'" >> "$LOGFILE"
      echo "  output: $output" >> "$LOGFILE"
    done <<< "$data"
  fi

  sleep 5
done
