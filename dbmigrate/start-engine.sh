#!/bin/bash

DB_CONTAINER="logapp-mariadb"
DB_USER="root"
DB_PASS="rootpassword"
DB_NAME="logdb"

LOG_FILE="engine.log"

echo "Starting script engine..." >> $LOG_FILE

while true; do

    # Get pending jobs (IMPORTANT: using 'message')
    RESULTS=$(docker exec -i $DB_CONTAINER mariadb -u$DB_USER -p$DB_PASS -D $DB_NAME -se \
    "SELECT id, message FROM logs WHERE status='pending';")

    # If nothing found, wait and retry
    if [ -z "$RESULTS" ]; then
        sleep 5
        continue
    fi

    # Process each job
    echo "$RESULTS" | while read -r ID CMD; do

        echo "Executing ID=$ID CMD=$CMD" >> $LOG_FILE

        # Mark as processing
        docker exec -i $DB_CONTAINER mariadb -u$DB_USER -p$DB_PASS -D $DB_NAME -e \
        "UPDATE logs SET status='processing' WHERE id=$ID;"

        # Execute command
        OUTPUT=$(bash -c "$CMD" 2>&1)
        EXIT_CODE=$?

        # Determine status
        if [ $EXIT_CODE -eq 0 ]; then
            STATUS="done"
        else
            STATUS="error"
        fi

        # Update final status in logs table
        docker exec -i $DB_CONTAINER mariadb -u$DB_USER -p$DB_PASS -D $DB_NAME -e \
        "UPDATE logs SET status='$STATUS' WHERE id=$ID;"

        # Escape quotes to avoid SQL breaking
        SAFE_CMD=$(echo "$CMD" | sed 's/"/\\"/g')
        SAFE_OUTPUT=$(echo "$OUTPUT" | sed 's/"/\\"/g')

        # Insert into execution_log (matches your schema)
        docker exec -i $DB_CONTAINER mariadb -u$DB_USER -p$DB_PASS -D $DB_NAME -e \
        "INSERT INTO execution_log (log_id, command, output, exit_code) VALUES ($ID, \"$SAFE_CMD\", \"$SAFE_OUTPUT\", $EXIT_CODE);"

        # Log to file
        echo "[$(date)] ID=$ID CMD=$CMD STATUS=$STATUS EXIT=$EXIT_CODE OUTPUT=$OUTPUT" >> $LOG_FILE

    done

    sleep 5
done
