#!/bin/bash

# Database Credentials
DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_NAME="logdb"
DB_USER="logapp"
DB_PASS="logapp123" 

# Log file path
LOG_FILE="./dbmigrate.log"

export MYSQL_PWD="$DB_PASS"

# Infinite loop to keep the engine running
while true; do
    # Fetch entries with 'pending' status
    PENDING_COMMANDS=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" -N -s -e "SELECT id, message FROM logs WHERE status='pending';")

    if [ ! -z "$PENDING_COMMANDS" ]; then
        echo "$PENDING_COMMANDS" | while read -r id command; do
            # Masking password for the log file if present
            LOG_COMMAND=$(echo "$command" | sed 's/-p[^ ]*/-p******** /g')
            echo "[$(date)] Executing ID $id: $LOG_COMMAND" >> "$LOG_FILE"
            
            # Execute the command and capture output
            EXEC_OUTPUT=$(eval "$command" 2>&1)
            EXIT_CODE=$?

            if [ $EXIT_CODE -eq 0 ]; then
                NEW_STATUS="done"
            else
                NEW_STATUS="error"
            fi

            # Update the status in the 'logs' table
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" -e "UPDATE logs SET status='$NEW_STATUS' WHERE id=$id;"
            
            # Log results to the 'execution_log' table
            # Escaping single quotes in output for SQL safety
            ESCAPED_OUTPUT=$(echo "$EXEC_OUTPUT" | sed "s/'/''/g")
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" -e "INSERT INTO execution_log (log_id, output, status) VALUES ($id, '$ESCAPED_OUTPUT', '$NEW_STATUS');"
            
            echo "[$(date)] Result: $NEW_STATUS | Output: $EXEC_OUTPUT" >> "$LOG_FILE"
        done
    fi
    sleep 5 # Wait 5 seconds before checking again
done
