#!/bin/bash

DB="logdb"
USER="logapp"
PASS="logapp123"
LOGFILE="dbmigrate.log"

while true; do
	# Fetch pending job
	JOB=$(mysql -h 127.0.0.1 -u$USER -p$PASS $DB -N -e \
		"SELECT id, message FROM logs WHERE status='pending' ORDER BY id ASC LIMIT 1;")

	if [ -z "$JOB" ]; then
		sleep 2
		continue
	fi

	JOB_ID=$(echo "$JOB" | awk '{print $1}')
	CMD=$(echo "$JOB" | awk '{$1=""; print}' | tr -s [:space:] ' ')
	CMD=$(echo "$CMD" | sed 's/^ //')

	echo "[$(date)] Executing job $JOB_ID: $CMD" >> "$LOGFILE"
	
	# Execute command
	OUTPUT=$(bash -c "$CMD" 2>&1)
	EXIT_CODE=$?

	# Update logs table
	if [ $EXIT_CODE -eq 0 ]; then
		STATUS="done"
	else
		STATUS="error"
	fi

	mysql -h 127.0.0.1 -u$USER -p$PASS $DB -e \
		"UPDATE logs SET status='$STATUS' WHERE id=$JOB_ID;"

	# Insert into execution_log table
	mysql -h 127.0.0.1 -u$USER -p$PASS $DB -e \
		"INSERT INTO execution_log (log_id, command, output, exit_code, executed_at)
		 VALUES ($JOB_ID, '$CMD', '$OUTPUT', $EXIT_CODE, NOW());"

	# Log locally
	echo "[$(date)] [$STATUS] CMD: $CMD" >> "$LOGFILE"
	echo "$OUTPUT" >> "$LOGFILE"
	echo "-------------------------------------------------------" >> "$LOGFILE"
done
