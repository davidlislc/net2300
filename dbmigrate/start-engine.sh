#!/bin/bash

# Database Credentials
DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_NAME="logdb"
DB_USER="logapp"
DB_PASS="logapp123" # Put your MariaDB password here

# Log file path
LOG_FILE="./engine_output.log"

echo "--- Starting Script Engine: $(date) ---" | tee -a "$LOG_FILE"

# 1. Read entries with 'pending' status
# We export the password to the environment so mysql picks it up automatically
export MYSQL_PWD="$DB_PASS"

PENDING_COMMANDS=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" -N -s -e "SELECT id, message FROM logs WHERE status='pending';")

if [ -z "$PENDING_COMMANDS" ]; then
    echo "No pending commands found." | tee -a "$LOG_FILE"
    exit 0
fi

# 2. Loop through and execute
echo "$PENDING_COMMANDS" | while read -r id command; do
    echo "Executing ID $id: $command" | tee -a "$LOG_FILE"
    
    EXEC_OUTPUT=$(eval "$command" 2>&1)
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        NEW_STATUS="done"
        echo "SUCCESS: $id" | tee -a "$LOG_FILE"
    else
        NEW_STATUS="error"
        echo "ERROR: $id (Exit Code: $EXIT_CODE)" | tee -a "$LOG_FILE"
    fi

    # 3. Update the database status
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" -e "UPDATE logs SET status='$NEW_STATUS' WHERE id=$id;"
    
    echo "Output: $EXEC_OUTPUT" >> "$LOG_FILE"
    echo "-----------------------------------" >> "$LOG_FILE"
done

# Clear the password from the environment when done for security
unset MYSQL_PWD

echo "--- Engine Cycle Complete ---" | tee -a "$LOG_FILE"
