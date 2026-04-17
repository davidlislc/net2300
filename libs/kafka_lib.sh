#!/bin/bash

set -o pipefail

KAFKA_BOOTSTRAP_SERVERS="${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}"
INPUT_TOPIC="${INPUT_TOPIC:-aiengine_in}"
MESSAGE_ORIGIN="${MESSAGE_ORIGIN:-$(hostname)}"
MESSAGE_SOURCE="${MESSAGE_SOURCE:-manual}"
MESSAGE_TYPE="${MESSAGE_TYPE:-base64_payload}"
CONTENT_ENCODING="${CONTENT_ENCODING:-base64}"
CONSUME_TIMEOUT="${CONSUME_TIMEOUT:-5000}"
CONSUME_MAX_MESSAGES="${CONSUME_MAX_MESSAGES:-1}"

cleanup() {
  rm -f /dev/shm/tmp_* 2>/dev/null || true
}

trap cleanup EXIT

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

read_payload() {
  if [[ $# -gt 0 ]]; then
    printf '%s' "$1"
  elif [[ ! -t 0 ]]; then
    cat
  else
    return 1
  fi
}

validate_base64() {
  local payload="$1"

  printf '%s' "$payload" | python3 -c '
import sys
import base64
import binascii

data = sys.stdin.read().strip()
if not data:
    sys.exit(1)

try:
    base64.b64decode(data, validate=True)
    sys.exit(0)
except (binascii.Error, ValueError):
    sys.exit(1)
'
}

utc_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

generate_message_id() {
  openssl rand -hex 16
}

build_message() {
  local payload="$1"
  local topic="$2"
  local origin="$3"
  local source="$4"
  local msg_type="$5"
  local job_id="${6:-}"
  local file_type="${7:-}"
  local file_name="${8:-}"
  local timestamp
  local message_id
  local payload_length

  timestamp="$(utc_timestamp)"
  message_id="$(generate_message_id)"
  payload_length="$(printf '%s' "$payload" | wc -c | tr -d ' ')"

  jq -cn \
    --arg id "$message_id" \
    --arg time "$timestamp" \
    --arg topic "$topic" \
    --arg origin "$origin" \
    --arg source "$source" \
    --arg type "$msg_type" \
    --arg job_id "$job_id" \
    --arg file_type "$file_type" \
    --arg file_name "$file_name" \
    --arg encoding "$CONTENT_ENCODING" \
    --arg payload "$payload" \
    --argjson payload_length "$payload_length" \
    '{
      metadata: {
        id: $id,
        time: $time,
        topic: $topic,
        origin: $origin,
        source: $source,
        type: $type,
        job_id: $job_id,
        file_type: $file_type,
        file_name: $file_name,
        encoding: $encoding,
        payload_length: $payload_length
      },
      payload: $payload
    }'
}

publish_message() {
  local topic="$1"
  local json_message="$2"

  printf '%s\n' "$json_message" | docker exec -i dev-kafka-1 /bin/kafka-console-producer --topic "$topic" --bootstrap-server localhost:9092
}

# --- Kafka Consumer ---
consume_messages() {
  local topic="$1"
  local timeout="${2:-$CONSUME_TIMEOUT}"
  local max_messages="${3:-$CONSUME_MAX_MESSAGES}"

  kcat \
    -C \
    -b "$KAFKA_BOOTSTRAP_SERVERS" \
    -t "$topic" \
    -o -1 \
    -e \
    -q \
    -c "$max_messages" \
    2>/dev/null
}

# --- Pretty Print a consumed JSON message ---
pretty_print_message() {
  local raw="$1"

  if ! echo "$raw" | jq . 2>/dev/null; then
    echo "[WARN] Non-JSON message received:" >&2
    echo "$raw"
  fi
}

# --- Decode payload field from a consumed JSON message ---
decode_payload() {
  local json="$1"
  local payload

  payload="$(echo "$json" | jq -r '.payload // empty')"

  if [[ -z "$payload" ]]; then
    echo "[WARN] No payload field found in message" >&2
    return 1
  fi

  printf '%s' "$payload" | base64 -d
}
