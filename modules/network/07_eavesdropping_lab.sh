#!/bin/bash
# ==========================================================
# modules/network/07_eavesdropping_lab.sh
# CONTROLLED / ACTIVE — LAB ONLY (packet capture)
#
# Objective: Demonstrate cleartext-protocol exposure via passive capture.
# Captures traffic to/from the target for a fixed short window and flags
# cleartext credential-bearing protocols (HTTP, FTP, Telnet). Does not
# perform active injection — purely observes traffic already flowing.
# Tools: tcpdump
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_eavesdrop_lab() {
    local TARGET="$1"
    check_deps tcpdump

    warn "This module captures live traffic involving $TARGET."
    warn "Only run this on an isolated lab segment you control and own all traffic on."
    read -rp "Confirm isolated lab capture (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        error "Not confirmed. Aborting."
        return 1
    fi

    local LOGFILE PCAPFILE
    LOGFILE=$(log_path "net_eavesdrop")
    PCAPFILE="${LOGFILE%.log}.pcap"
    local DURATION=20

    info "Capturing traffic to/from $TARGET for ${DURATION}s..."
    info "PCAP: $PCAPFILE | Summary log: $LOGFILE"

    sudo run_with_timeout "$DURATION" tcpdump -i any -w "$PCAPFILE" host "$TARGET" 2>&1 | tail -5

    {
        echo "===== SentryNet Eavesdropping Lab: $TARGET ====="
        date
        echo "Capture duration: ${DURATION}s | PCAP saved to: $PCAPFILE"

        echo -e "\n--- Cleartext protocol exposure check ---"
        for port_proto in "80:HTTP" "21:FTP" "23:Telnet" "110:POP3" "143:IMAP"; do
            port="${port_proto%%:*}"
            proto="${port_proto##*:}"
            count=$(sudo tcpdump -r "$PCAPFILE" "port $port" 2>/dev/null | wc -l)
            if [ "$count" -gt 0 ]; then
                warn "$proto traffic observed ($count packets) — cleartext protocol, credentials/data may be exposed."
            fi
        done

        echo -e "\n===== Eavesdropping lab complete ====="
        echo "Remediation: enforce TLS for all the protocols flagged above."
        echo "Inspect further with: wireshark $PCAPFILE"
    } | tee "$LOGFILE"

    ok "Eavesdropping lab finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_eavesdrop_lab "$TARGET"
fi
