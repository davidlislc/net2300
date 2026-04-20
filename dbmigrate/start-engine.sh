#!/bin/bash

DB_CONTAINER="logapp-mariadb"
DB_USER="root"
DB_PASS="rootpassword"
DB_NAME="logdb"

LOG_FILE="engine.log"

echo "Starting script engine..." | tee -a "$LOG_FILE"

while true; do

    RESULTS=$(docker exec -i $DB_CONTAINER mariadb -u$DB_USER -p$DB_PASS -D $DB_NAME -se \
    "SELECT id, message FROM logs WHERE status='pending';")

    if [ -z "$RESULTS" ]; then
        sleep 5
        continue
    fi

    echo "$RESULTS" | while read -r ID CMD; do

        echo "Processing ID=$ID CMD=$CMD" | tee -a "$LOG_FILE"

        # Set processing
        docker exec -i $DB_CONTAINER mariadb -u$DB_USER -p$DB_PASS -D $DB_NAME -e \
        "UPDATE logs SET status='processing' WHERE id=$ID;"

        # Execute command
        OUTPUT=$(bash -c "$CMD" 2>&1)
        EXIT_CODE=$?

        if [ $EXIT_CODE -eq 0 ]; then
            STATUS="done"
        else
            STATUS="error"
        fi

        # Update logs table
        docker exec -i $DB_CONTAINER mariadb -u$DB_USER -p$DB_PASS -D $DB_NAME -e \
        "UPDATE logs SET status='$STATUS' WHERE id=$ID;"

        # Escape quotes
        SAFE_CMD=$(echo "$CMD" | sed 's/"/\\"/g')
        SAFE_OUTPUT=$(echo "$OUTPUT" | sed 's/"/\\"/g')

        # Insert execution log
        docker exec -i $DB_CONTAINER mariadb -u$DB_USER -p$DB_PASS -D $DB_NAME -e \
        "INSERT INTO execution_log (log_id, command, output, exit_code) VALUES ($ID, \"$SAFE_CMD\", \"$SAFE_OUTPUT\", $EXIT_CODE);"

        # Final log entry
        LOG_ENTRY="[$(date)] ID=$ID CMD=$CMD STATUS=$STATUS EXIT=$EXIT_CODE OUTPUT=$OUTPUT"

        echo "$LOG_ENTRY" | tee -a "$LOG_FILE"

    done

    sleep 5
done
