#!/bin/bash


# If true, run mysql inside docker compose service "db"
: "${DB_USE_DOCKER_COMPOSE:=false}"
: "${DB_SERVICE_NAME:=db}"

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-user}"
DB_PASSWORD="${DB_PASSWORD:-password}"
# Initial States
declare -r STATUS_PENDING="PENDING"
declare -r STATUS_QUEUED="QUEUED"

# Security & Preparation
declare -r STATUS_SANITIZING="SANITIZING"
declare -r STATUS_SANITIZED="SANITIZED"
declare -r STATUS_FAILED_SANITIZATION="FAILED_SANITIZATION"
#AI Engine Processing
declare -r STATUS_AI_PROCESSING_PENDING="AI_PROCESSING_PENDING"

declare -r STATUS_AI_PROCESSING="AI_PROCESSING"
declare -r STATUS_AI_PROCESSED="AI_PROCESSED"

# Execution
declare -r STATUS_IN_PROGRESS="IN_PROGRESS"
declare -r STATUS_RETRYING="RETRYING"

# Final States
declare -r STATUS_COMPLETED="COMPLETED"
declare -r STATUS_COMPLETED_WITH_WARNINGS="COMPLETED_WITH_WARNINGS"
declare -r STATUS_ERROR="ERROR"
declare -r STATUS_CANCELLED="CANCELLED"

# Usage Example:
current_status=$STATUS_PENDING

run_mysql() {
  local sql="$1"
  MYSQL_PWD="$DB_PASSWORD" mysql --protocol=TCP \
    -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" \
    --batch --raw --skip-column-names \
    -e "$sql"
}

insert_job_request() {
  local b64_data="$1"
  run_mysql "
    INSERT INTO job_request (
      file_name,
      file_content,
      file_content_content_type,
      file_type,
      status,
      request_type,
      priority,
      user_id
    ) VALUES (
      '$FILE_NAME',
      FROM_BASE64('$b64_data'),
      'text/csv',
      'LOG',
      'PENDING',
      'SANITIZE',
      '$PRIORITY',
      '$USER_ID'
    );
  "
}

read_latest_job_request() {
  run_mysql  "
      SELECT
        id,
        COALESCE(file_name, ''),
        COALESCE(file_content_content_type, ''),
        REPLACE(TO_BASE64(file_content), '\n', '')
      FROM job_request
      WHERE status='PENDING'
      ORDER BY id DESC
      LIMIT 1;
    "
}

insert_execution_report() {
	local job_request_id="$1"
	local user_id="$2"
	local execution_node="$3"
	local execution_log="$4"
	local status="$5"

	run_mysql "
		INSERT INTO job_execution_report
		(start_time, end_time, execution_node, execution_log, status, job_request_id, user_id)
		VALUES
		(NOW(), NOW(), '$execution_node', '$execution_log', '$status', $job_request_id, $user_id)
		ON DUPLICATE KEY UPDATE
		end_time = NOW(),
		execution_log = VALUES(execution_log),
		status = VALUES(status),
		execution_node = VALUES(execution_node),
		user_id = VALUES(user_id);
		"
	}

delete_job_request_by_id() {
  local job_id="$1"
  run_mysql "
    DELETE FROM job_request
    WHERE id = ${job_id}
    LIMIT 1;
  "
}

update_job_request_status() {
  local job_id="$1"
  local status="$2"
  run_mysql "
    UPDATE job_request
    SET status = '$status'
    WHERE id = ${job_id};
  "
}
