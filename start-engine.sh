#!/bin/bash
DB_CMD="docker exec docker-compose-db-1 mysql -u root -psomewordpress wordpress -N -s -e"

echo "Engine started. Checking for pending commands..."

COMMAND=$($DB_CMD "SELECT command FROM pending_commands WHERE status='pending' LIMIT 1;")

if [ -z "$COMMAND" ]; then
    echo "No pending commands found."
else
    echo "Executing: $COMMAND"
    chmod +x "$COMMAND"
    ./$COMMAND
    
    $DB_CMD "UPDATE pending_commands SET status='completed' WHERE command='$COMMAND';"
    echo "Task finished."
fi
