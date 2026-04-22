#!/bin/bash

LOG_FILE="start-engine.log"
DB_CONTAINER="logapp-mariadb"
DB_NAME="logdb"
DB_USER="root"
DB_PASS="rootpassword"

echo "[$(date)] start-engine.sh started" | tee -a "$LOG_FILE"

PENDING_ROWS=$(docker exec -i "$DB_CONTAINER" mariadb -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B -e "
SELECT id, message
FROM logs
WHERE status='pending';
")

if [[ -z "$PENDING_ROWS" ]]; then
  echo "[$(date)] No pending commands found" | tee -a "$LOG_FILE"
  exit 0
fi

while IFS=$'\t' read -r LOG_ID CMD; do
  echo "[$(date)] Running id=$LOG_ID command: $CMD" | tee -a "$LOG_FILE"

  OUTPUT=$(bash -c "$CMD" 2>&1)
  EXIT_CODE=$?

  SAFE_CMD=$(printf "%s" "$CMD" | sed "s/'/''/g")
  SAFE_OUTPUT=$(printf "%s" "$OUTPUT" | sed "s/'/''/g")

  if [[ $EXIT_CODE -eq 0 ]]; then
    echo "[$(date)] SUCCESS id=$LOG_ID" | tee -a "$LOG_FILE"
    echo "$OUTPUT" | tee -a "$LOG_FILE"

    docker exec -i "$DB_CONTAINER" mariadb -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
UPDATE logs
SET status='done'
WHERE id=$LOG_ID;
" 2>&1 | tee -a "$LOG_FILE"

    docker exec -i "$DB_CONTAINER" mariadb -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
INSERT INTO execution_log (log_id, command, output, exit_code)
VALUES ($LOG_ID, '$SAFE_CMD', '$SAFE_OUTPUT', $EXIT_CODE);
" 2>&1 | tee -a "$LOG_FILE"

  else
    echo "[$(date)] ERROR id=$LOG_ID" | tee -a "$LOG_FILE"
    echo "$OUTPUT" | tee -a "$LOG_FILE"

    docker exec -i "$DB_CONTAINER" mariadb -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
UPDATE logs
SET status='error'
WHERE id=$LOG_ID;
" 2>&1 | tee -a "$LOG_FILE"

    docker exec -i "$DB_CONTAINER" mariadb -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
INSERT INTO execution_log (log_id, command, output, exit_code)
VALUES ($LOG_ID, '$SAFE_CMD', '$SAFE_OUTPUT', $EXIT_CODE);
" 2>&1 | tee -a "$LOG_FILE"
  fi

done <<< "$PENDING_ROWS"

echo "[$(date)] start-engine.sh finished" | tee -a "$LOG_FILE"
