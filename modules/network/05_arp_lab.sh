#!/bin/bash
# ==========================================================
# modules/network/05_arp_lab.sh
# SAFE / PASSIVE
#
# Objective: ARP table reconnaissance and spoofing-detection baseline.
# This module only OBSERVES the ARP table — it does not send spoofed
# ARP traffic (see 04_mitm_lab.sh for the active/disruptive version).
# Tools: arp-scan (preferred) or arp
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_arp_lab() {
    local TARGET="$1"

    local LOGFILE
    LOGFILE=$(log_path "net_arp")
    info "Logging to $LOGFILE"

    {
        echo "===== SentryNet ARP Recon: $TARGET ====="
        date

        echo -e "\n--- Current ARP cache ---"
        arp -a

        if command -v arp-scan >/dev/null 2>&1; then
            echo -e "\n--- arp-scan local segment ---"
            sudo arp-scan --localnet 2>/dev/null | grep -F "$TARGET"
        else
            warn "arp-scan not installed (optional). Install: sudo apt install arp-scan"
        fi

        echo -e "\n--- Duplicate MAC check (spoofing indicator) ---"
        arp -a | awk '{print $4}' | sort | uniq -d | while read -r dup_mac; do
            [ -n "$dup_mac" ] && warn "MAC address $dup_mac maps to multiple IPs — possible ARP spoofing."
        done

        echo -e "\n===== ARP recon complete ====="
    } | tee "$LOGFILE"

    ok "ARP recon finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_arp_lab "$TARGET"
fi
