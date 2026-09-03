#!/bin/bash
# ==========================================================
# modules/network/01_recon.sh
# SAFE / PASSIVE
#
# Objective: Basic host discovery and network-layer info gathering.
# Tools: nmap (ping sweep), arp (local segment only)
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_recon() {
    local TARGET="$1"
    check_deps nmap

    local LOGFILE
    LOGFILE=$(log_path "net_recon")
    info "Logging to $LOGFILE"

    {
        echo "===== SentryNet Network Recon: $TARGET ====="
        date

        echo -e "\n--- Host discovery ---"
        nmap -sn "$TARGET"

        echo -e "\n--- ARP table (local segment visibility only) ---"
        if command -v arp >/dev/null 2>&1; then
            arp -a | grep -F "$TARGET" || echo "No ARP entry cached for $TARGET yet."
        fi

        echo -e "\n--- Traceroute ---"
        if command -v traceroute >/dev/null 2>&1; then
            run_with_timeout 30 traceroute -m 15 "$TARGET" 2>/dev/null
        else
            warn "traceroute not installed — skipping."
        fi

        echo -e "\n===== Network recon complete ====="
    } | tee "$LOGFILE"

    ok "Network recon finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_recon "$TARGET"
fi
