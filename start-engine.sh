#!/bin/bash
# Simple engine to read and execute commands from the DB
DB_CMD="docker exec docker-compose-db-1 mysql -u root -psomewordpress wordpress -N -s -e"

echo "Engine started. Checking for pending commands..."

# Get the oldest pending command
COMMAND=$($DB_CMD "SELECT command FROM pending_commands WHERE status='pending' LIMIT 1;")

if [ -z "$COMMAND" ]; then
    echo "No pending commands found."
else
    echo "Executing: $COMMAND"
    # Run the script
    chmod +x "$COMMAND"
    ./$COMMAND
    
    # Update status to completed
    $DB_CMD "UPDATE pending_commands SET status='completed' WHERE command='$COMMAND';"
    echo "Task finished."
fi
