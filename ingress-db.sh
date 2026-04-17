#!/bin/bash
set -euo pipefail
set -o pipefail

FILE="samplescript/2-csv-20260316221533.csv"
DB_NAME="sanitizer_db"
PRIORITY="1"
USER_ID="2"
FILE_NAME="$(basename "$FILE")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../libs/db_lib.sh
source "${SCRIPT_DIR}/libs/db_lib.sh"
source "${SCRIPT_DIR}/libs/kafka_lib.sh"
source "${SCRIPT_DIR}/libs/san_lib.sh"

## the following line are for testing purposes, it should be removed once the test is over
## or it should be moved to a separate test script
# Encode file once
B64_DATA="$(base64 < "$FILE" | tr -d '\n')"

# there should be echo statement here to log the progress to the logs
insert_job_request "$B64_DATA"
#end of testing code, the following lines should be in the main script to continuously read from the database and process the job requests

# Read the latest job request. In final product, it should only reading pending requests.

ROW="$(read_latest_job_request)"

if [[ -z "$ROW" ]]; then
  echo "No rows found in job_request" >&2
  exit 1
fi

# at this line, the status should be updated to SANITIZING

IFS=$'\t' read -r JOB_ID FILE_NAME CONTENT_TYPE FILE_CONTENT_B64 <<< "$ROW"
#added by maggie
echo "Picked latest PENDING job request id=$JOB_ID"
insert_execution_report "$JOB_ID" "$USER_ID" "$(hostname)" "Picked latest PENDING job_request id=$JOB_ID" "SANITIZING" 

if [[ -z "${FILE_CONTENT_B64:-}" ]]; then
  echo "Empty blob content for job_request.id=${JOB_ID}" >&2
  # The job request should be updated to COMPLETED_WITH_WARNINGS if the blob content is empty.
  insert_execution_report "$JOB_ID" "$USER_ID" "$(hostname)" "Empty blob content for job_request.id=${JOB_ID}" "COMPLETED_WITH_WARNINGS"
  update_job_request_status "$JOB_ID" "$STATUS_COMPLETED_WITH_WARNINGS"
  exit 1
  # the job execution log should be updated to include the warning message about empty blob content.
fi

echo "Sanitizing payload for job_request id=$JOB_ID"
insert_execution_report "$JOB_ID" "$USER_ID" "$(hostname)" "Sanitizing payload for job_request id=$JOB_ID" "SANITIZING"
echo "job_id=${JOB_ID} file_name=${FILE_NAME} content_type=${CONTENT_TYPE}"
sanitized_msg="$(sanitize_base64 "$FILE_CONTENT_B64" "$JOB_ID" "$CONTENT_TYPE")"
echo "Sanitized message: $sanitized_msg"
#maggie added vvv
insert_execution_report "$JOB_ID" "$USER_ID" "$(hostname)" "Sanitized payload for job_request id=$JOB_ID" "SANITIZED"

# Build the message and publish to Kafka Sanitizer Input Topic

json_message="$(build_message \
  "$sanitized_msg" \
  "$INPUT_TOPIC" \
  "$MESSAGE_ORIGIN" \
  "$MESSAGE_SOURCE" \
  "$MESSAGE_TYPE" \
  "$JOB_ID" \
  "$CONTENT_TYPE" \
  "$FILE_NAME")"

publish_message "$INPUT_TOPIC" "$json_message"

echo "Published message to topic: $INPUT_TOPIC"
# also log the message meta information such as timestamp, origin,  etc.
echo "Message meta: origin=$MESSAGE_ORIGIN, source=$MESSAGE_SOURCE, type=$CONTENT_TYPE"
echo "Pretty-printed message:"
pretty_print_message "$json_message"
#maggie added vvv
insert_execution_report "$JOB_ID" "$USER_ID" "$(hostname)" "Published message to topic $INPUT_TOPIC for job_request id=$JOB_ID" "PUBLISHED"
update_job_request_status "$JOB_ID" "$STATUS_AI_PROCESSING_PENDING"
echo "Updated job_request.id=${JOB_ID} status to $STATUS_AI_PROCESSING_PENDING"
insert_execution_report "$JOB_ID" "$USER_ID" "$(hostname)" "Updated job_request id=$JOB_ID to AI_PROCESSING_PENDING" "COMPLETED"
