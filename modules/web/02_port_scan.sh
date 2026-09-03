#!/bin/bash
# ==========================================================
# modules/web/02_port_scan.sh
# SAFE / PASSIVE (SYN scan) — CONTROLLED / ACTIVE (service/version detection)
#
# Objective: Identify exposed web-related services on target.
# Tools: nmap
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_port_scan() {
    local TARGET="$1"
    check_deps nmap

    local LOGFILE
    LOGFILE=$(log_path "web_portscan")
    info "Scanning common web-related ports on $TARGET"
    info "Logging to $LOGFILE"

    # -sV: version detection, -Pn: skip host discovery (many web hosts block ping)
    # Focused port list keeps this fast and web-relevant rather than a full 1-65535 sweep.
    run_with_timeout 300 nmap -sV -Pn \
        -p 21,22,25,53,80,110,143,443,445,465,587,993,995,3000,3306,3389,5432,8000,8008,8080,8081,8443,8888,9000 \
        -oN "$LOGFILE" "$TARGET"

    ok "Port scan finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_port_scan "$TARGET"
fi
