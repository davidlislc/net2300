#!/bin/bash

DB_HOST="localhost"
DB_USER="logapp"
DB_PASS="logapp123"
DB_NAME="logdb"
LOG_FILE="dbmigrate.log"

log_message() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_message "Engine started. Checking pending tasks..."

entries=$(mysql -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASS" "$DB_NAME" -N -s -e "SELECT id, command FROM logs WHERE status='pending';")

if [ -z "$entries" ]; then
	log_message "No pending commands to resolve."
	exit 0
fi

echo "$entries" | while read -r id command; do
	log_message "Executing ID $id: $command"
	execution_output=$(eval "$command" 2>&1)
	exit_code=$?

	if [ $exit_code -eq 0 ]; then
		status="done"
		log_message "Success: ID $id"
	else
		status="error"
		log_message "Error: ID $id failed with exit code $exit_code"
	fi

	mysql -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASS" "$DB_NAME" -e "UPDATE logs SET status='$status' WHERE id=$id;"

	clean_output=$(echo "$execution_output" | sed "s/'/''/g")
	mysql -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASS" "$DB_NAME" -e "INSERT INTO execution_log (log_id, output, status) VALUES ($id, '$clean_output', '$status');"
done

log_message "Engine run complete"
	

