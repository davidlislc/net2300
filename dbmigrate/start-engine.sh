#!/bin/bash

# Database Credentials
DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_NAME="logdb"
DB_USER="logapp"
DB_PASS="logapp123" 

# New Log file path
LOG_FILE="./dbmigrate.log"

export MYSQL_PWD="$DB_PASS"

# We use an infinite loop so the script keeps checking while running in the background
while true; do
    PENDING_COMMANDS=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" -N -s -e "SELECT id, message FROM logs WHERE status='pending';")

    if [ ! -z "$PENDING_COMMANDS" ]; then
        echo "$PENDING_COMMANDS" | while read -r id command; do
            echo "[$(date)] Executing ID $id: $command" >> "$LOG_FILE"
            
            EXEC_OUTPUT=$(eval "$command" 2>&1)
            EXIT_CODE=$?

            if [ $EXIT_CODE -eq 0 ]; then
                NEW_STATUS="done"
            else
                NEW_STATUS="error"
            fi

            # Update logs table
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" -e "UPDATE logs SET status='$NEW_STATUS' WHERE id=$id;"
            
            # Log to execution_log table (Instruction #5)
            # Note: Ensure the table execution_log exists with columns (log_id, output, status)
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" -e "INSERT INTO execution_log (log_id, output, status) VALUES ($id, '$EXEC_OUTPUT', '$NEW_STATUS');"
            
            echo "[$(date)] Result: $NEW_STATUS | Output: $EXEC_OUTPUT" >> "$LOG_FILE"
        done
    fi
    sleep 5 # Wait 5 seconds before checking again to save CPU
done
