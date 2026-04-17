#!/bin/bash

DB_USER="logapp"
DB_PASS="logapp123"
DB_NAME="logdb"

LOG_FILE="dbmigrate.log"

echo "Starting engine..." >> $LOG_FILE

while true
do
    # Get pending commands
    results=$(mysql -h 127.0.0.1 -P 3306 -u$DB_USER -p$DB_PASS -D$DB_NAME -se "SELECT id, message FROM logs WHERE status='pending';")

    while IFS=$'\t' read -r id cmd
    do
        if [ -n "$id" ]; then
            echo "Running command ID $id: $cmd" >> $LOG_FILE

            # Execute command
            output=$(bash -c "$cmd" 2>&1)
            exit_code=$?

            if [ $exit_code -eq 0 ]; then
                status="done"
            else
                status="error"
            fi

            # Update logs table
            mysql -h 127.0.01 -P 3306 -u$DB_USER -p$DB_PASS -D$DB_NAME -e "
                UPDATE logs SET status='$status' WHERE id=$id;
            "

            # Insert into execution_log
            mysql -h 127.0.0.1 -P 3306 -u$DB_USER -p$DB_PASS -D$DB_NAME -e "
                INSERT INTO execution_log (log_id, output, status)
                VALUES ($id, \"$output\", \"$status\");
            "

            # Log to file
            echo "[$status] ID $id: $output" >> $LOG_FILE
        fi
    done <<< "$results"

    sleep 5
done
