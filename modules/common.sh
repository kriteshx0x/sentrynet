#!/bin/bash
# ==========================================================
# modules/common.sh
# Shared helper functions sourced by every SentryNet module.
# Not directly executable — provides functions only.
# ==========================================================

# --- Colors (used consistently across all modules) ---
C_RESET="\e[0m"
C_INFO="\e[36m"    # cyan
C_OK="\e[32m"      # green
C_WARN="\e[33m"    # yellow
C_ERR="\e[31m"     # red

info()  { echo -e "${C_INFO}[*]${C_RESET} $1"; }
ok()    { echo -e "${C_OK}[+]${C_RESET} $1"; }
warn()  { echo -e "${C_WARN}[!]${C_RESET} $1"; }
error() { echo -e "${C_ERR}[x]${C_RESET} $1"; }

# --- Resolve project root regardless of caller's cwd ---
# Every module sources this file with an absolute path built from
# its own location, so SENTRYNET_ROOT is always correct.
SENTRYNET_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$SENTRYNET_ROOT/logs"
mkdir -p "$LOG_DIR"

# --- Dependency check ---
# Usage: check_deps nmap hydra curl
# Exits 1 with a clear message if anything is missing. No silent failures.
check_deps() {
    local missing=()
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    if [ "${#missing[@]}" -gt 0 ]; then
        error "Missing required tool(s): ${missing[*]}"
        error "Install them before running this module. Aborting."
        exit 1
    fi
}

# --- Target validation ---
# Usage: validate_target "$INPUT"
# Accepts IPv4 or a basic hostname/domain. Prints normalized target on stdout.
# On failure, prints error to stderr and returns 1 (caller must handle).
validate_target() {
    local target="$1"
    local ipv4_re='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    local host_re='^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'

    if [ -z "$target" ]; then
        error "Target cannot be empty." >&2
        return 1
    fi

    if [[ "$target" =~ $ipv4_re ]]; then
        # Validate each octet is 0-255
        IFS='.' read -r o1 o2 o3 o4 <<< "$target"
        for octet in "$o1" "$o2" "$o3" "$o4"; do
            if [ "$octet" -gt 255 ]; then
                error "Invalid IPv4 address: $target" >&2
                return 1
            fi
        done
        echo "$target"
        return 0
    elif [[ "$target" =~ $host_re ]]; then
        echo "$target"
        return 0
    else
        error "Target '$target' is not a valid IPv4 address or hostname." >&2
        return 1
    fi
}

# --- Interactive target prompt (for web/network/iot modules) ---
# Usage: TARGET=$(prompt_target)
prompt_target() {
    local input result
    while true; do
        read -rp "Enter target IP/domain: " input >&2
        if result=$(validate_target "$input"); then
            echo "$result"
            return 0
        fi
        warn "Try again." >&2
    done
}

# --- Explicit authorization confirmation ---
# Usage: confirm_authorization "$TARGET" || exit 1
# This is a hard gate. No module should skip it.
confirm_authorization() {
    local target="$1"
    echo ""
    warn "You are about to run a security test against: $target"
    warn "This action must ONLY be performed against systems you own"
    warn "or have explicit written authorization to test."
    echo ""
    read -rp "Type 'yes' to confirm you are authorized: " confirm
    if [ "$confirm" != "yes" ]; then
        error "Authorization not confirmed. Aborting."
        return 1
    fi
    return 0
}

# --- Standardized log file naming ---
# Usage: LOGFILE=$(log_path "web_recon")
# Produces: logs/web_recon_<unix_timestamp>.log
log_path() {
    local label="$1"
    echo "$LOG_DIR/${label}_$(date +%s).log"
}

# --- Timeout wrapper for long-running scans ---
# Usage: run_with_timeout 300 nmap -sV "$TARGET"
run_with_timeout() {
    local seconds="$1"; shift
    timeout "$seconds" "$@"
    local rc=$?
    if [ "$rc" -eq 124 ]; then
        warn "Command timed out after ${seconds}s: $*"
    fi
    return $rc
}
