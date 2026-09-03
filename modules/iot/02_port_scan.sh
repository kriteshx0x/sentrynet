#!/bin/bash
# ==========================================================
# modules/iot/02_port_scan.sh
# CONTROLLED / ACTIVE
#
# Objective: Full TCP/UDP-relevant port scan tuned to IoT protocol range.
# Tools: nmap
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_port_scan() {
    local TARGET="$1"
    check_deps nmap

    local LOGFILE
    LOGFILE=$(log_path "iot_portscan")
    info "Logging to $LOGFILE"

    echo "===== SentryNet IoT Port Scan: $TARGET =====" | tee "$LOGFILE"
    run_with_timeout 600 nmap -sV -sU --top-ports 50 -oN "${LOGFILE}.udp" "$TARGET" | tee -a "$LOGFILE"
    run_with_timeout 600 nmap -sV -p- --max-retries 1 -oN "${LOGFILE}.tcp" "$TARGET" | tee -a "$LOGFILE"

    ok "IoT port scan finished. Results: $LOGFILE (+ .tcp/.udp raw nmap output)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_port_scan "$TARGET"
fi
