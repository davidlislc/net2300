#!/bin/bash
set -o pipefail
# Configuration
RULES_FILE="./sanitizer_rules.yar"
TMP_BASE="${SANITIZER_TMP_BASE:-/tmp/sanitizer_engine}"

decode_base64_to_file() {
    local out_file="$1"

    # GNU base64 (Linux)
    if printf '' | base64 -d >/dev/null 2>&1; then
        base64 -d > "$out_file"
        return $?
    fi

    # BSD base64 (macOS)
    if printf '' | base64 -D >/dev/null 2>&1; then
        base64 -D > "$out_file"
        return $?
    fi

    # Fallback
    openssl base64 -d -A > "$out_file"
}

# --- Rocky Linux Optimized Sanitization ---

sanitize_base64() {
    local RAW_PAYLOAD="$1"
    local SAFE_JOB_ID=$2 
    local MIME=$3
    
    # Ensure temp directory exists
    mkdir -p "$TMP_BASE"
    update_job_request_status "$SAFE_JOB_ID" "$STATUS_SANITIZING"

    local JOB_DIR
    JOB_DIR=$(mktemp -d "${TMP_BASE%/}/job_${SAFE_JOB_ID}_XXXXXX") || return 1
    
    local RAW_FILE="$JOB_DIR/raw_input"
    local CLEAN_FILE="$JOB_DIR/cleaned_output"

    # 1. Decode Base64
    if ! printf '%s' "$RAW_PAYLOAD" | base64 -d > "$RAW_FILE" 2>/dev/null; then
        update_job_request_status "$SAFE_JOB_ID" "$STATUS_FAILED_SANITIZATION"
        rm -rf "$JOB_DIR"
        return 1
    fi

    # 2. Antivirus (ClamAV)
    # Using --infected to only output if a virus is found
    if clamscan --infected --no-summary "$RAW_FILE" 2>/dev/null | grep -1 .; then
	    echo "{\"job_id\": \"$SAFE_JOB_ID\", \"status\": \"REJECTED\", \"threat\": \"ClamAV: malware detected\"}"
	    update_job_request_status "$SAFE_JOB_ID" "$STATYS_FAILED_SANITIZATION"
	    rm -rf "$JOB_DIR"
	    return 1
    fi


    # 3. YARA Analysis
    if [ -f "$RULES_FILE" ]; then
        local SCAN_LOG
        SCAN_LOG=$(yara "$RULES_FILE" "$RAW_FILE" 2>/dev/null)
        if [ -n "$SCAN_LOG" ]; then
            echo "{\"job_id\": \"$SAFE_JOB_ID\", \"status\": \"REJECTED\", \"threat\": \"YARA: $SCAN_LOG\"}"
            update_job_request_status "$SAFE_JOB_ID" "$STATUS_FAILED_SANITIZATION"
            rm -rf "$JOB_DIR"
            return 1
        fi
    fi

    # 4. CDR - Media, Logs, Web, and Traffic
    case "$MIME" in
        image/jpeg|image/png|image/webp)
            # Rocky's ImageMagick uses 'magick' command in newer versions, 
            # but 'convert' is usually symlinked.
            convert "$RAW_FILE" -strip "$CLEAN_FILE"
            ;;
        application/pdf)
            qpdf --linearize --replace-input "$RAW_FILE" --output-file "$CLEAN_FILE" >/dev/null 2>&1
            ;;
        text/html|application/json|text/x-log|application/vnd.tcpdump.pcap|text/plain)
            # Call our Python helper for structured/complex data
	    python3 "$(dirname "${BASH_SOURCE[0]}")/complex_sanitizer.py" "$RAW_FILE" "$CLEAN_FILE" "$MIME"	    
            ;;
        *)
            # Fallback: Strip dangerous control characters (Null, ESC, etc.)
            tr -d '\000-\010\013\014\016-\037' < "$RAW_FILE" > "$CLEAN_FILE"
            ;;
    esac

    # 5. Return Clean Base64
    local CLEAN_PAYLOAD
    CLEAN_PAYLOAD=$(base64 -w 0 < "$CLEAN_FILE")
    echo "$CLEAN_PAYLOAD"
    
    update_job_request_status "$SAFE_JOB_ID" "$STATUS_SANITIZED"
    rm -rf "$JOB_DIR"
    return 0
}


sanitize_pcap() {
    local in="$1"
    local out="$OUTPUT_DIR/$(basename "$1")"

    # -s 96 truncates the payload, keeping only headers (Ethernet/IP/TCP)
    # This removes PII/Data while preserving flow for anomaly detection
    tcpdump -r "$in" -w "$out" -s 96 2>/dev/null
    echo "[+] PCAP sanitized (Payloads stripped): $out"
}

sanitize_text() {
    local in="$1"
    local out="$OUTPUT_DIR/$(basename "$1")"

    # 1. Strip CR characters to prevent Log Injection
    # 2. Mask IPv4 addresses (Example: 192.168.x.x -> 192.168.MASK.MASK)
    # 3. Remove known sensitive keywords (case-insensitive)
    sed -E 's/([0-9]{1,3}\.[0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}/\1.XXX.XXX/g' "$in" | \
        sed -E 's/(password|passwd|token|auth|secret)=[^ ]*/\1=REDACTED/gI' | \
        tr -d '\r' > "$out"

    echo "[+] Text log sanitized: $out"
}

sanitize_json() {
    local in="$1"
    local out="$OUTPUT_DIR/$(basename "$1")"

    # Use jq to recursively delete sensitive keys regardless of depth
    jq 'walk(if type == "object" then del(.password, .token, .secret, .sessionID) else . end)' "$in" > "$out"
    echo "[+] JSON sanitized (Keys removed): $out"
}
