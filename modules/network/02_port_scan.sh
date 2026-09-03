#!/bin/bash
# ==========================================================
# modules/network/02_port_scan.sh
# CONTROLLED / ACTIVE
#
# Objective: Full-range TCP port + service/version discovery.
# Tools: nmap
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_port_scan() {
    local TARGET="$1"
    check_deps nmap

    local LOGFILE
    LOGFILE=$(log_path "net_portscan")
    info "Running full TCP port scan on $TARGET (this can take a while)"
    info "Logging to $LOGFILE"

    run_with_timeout 900 nmap -sV -O -p- --max-retries 2 -oN "$LOGFILE" "$TARGET"

    ok "Port scan finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_port_scan "$TARGET"
fi
