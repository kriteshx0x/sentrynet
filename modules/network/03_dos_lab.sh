#!/bin/bash
# ==========================================================
# modules/network/03_dos_lab.sh
# DISRUPTIVE / LAB ONLY
#
# Objective: Demonstrate DoS impact and detection in an ISOLATED lab.
# This module intentionally does NOT run an unbounded flood. It sends
# a small, rate-limited, time-boxed burst suitable for observing
# detection tooling (e.g. your own DoS Detector project) react safely.
# Tools: hping3 (preferred) or curl-based request burst fallback
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_dos_lab() {
    local TARGET="$1"

    warn "=============================================="
    warn " DISRUPTIVE / LAB-ONLY MODULE"
    warn " This WILL generate a load spike against the target."
    warn " Only run this against a system in an isolated lab"
    warn " network that you own. Never point this at a"
    warn " shared network, cloud host, or third-party system."
    warn "=============================================="

    read -rp "Type the target IP again to confirm isolated-lab use: " confirm_ip
    if [ "$confirm_ip" != "$TARGET" ]; then
        error "Confirmation IP did not match. Aborting."
        return 1
    fi

    local LOGFILE
    LOGFILE=$(log_path "net_dos_lab")
    info "Logging to $LOGFILE"

    # Hard caps: 5 second duration, low rate. This is a detection-tooling
    # demo, not a stress-test framework. Increase only inside your own lab
    # and only if you understand the impact on the target VM.
    local DURATION=5
    local RATE_PPS=20

    {
        echo "===== SentryNet DoS Lab Demo: $TARGET ====="
        echo "Duration: ${DURATION}s | Rate: ${RATE_PPS} packets/sec (capped)"
        date

        if command -v hping3 >/dev/null 2>&1; then
            info "Using hping3 for a controlled SYN burst..."
            run_with_timeout "$DURATION" hping3 -S -p 80 -i "u$((1000000/RATE_PPS))" "$TARGET" 2>&1 | tail -20
        else
            warn "hping3 not installed — falling back to a capped curl request burst."
            end=$((SECONDS + DURATION))
            count=0
            while [ $SECONDS -lt $end ]; do
                curl -s -o /dev/null --max-time 1 "http://$TARGET" &
                count=$((count + 1))
                sleep "$(echo "1/$RATE_PPS" | bc -l)"
            done
            wait
            echo "Sent approximately $count requests."
        fi

        echo -e "\n===== DoS lab demo complete ====="
        echo "This burst is intentionally small — pair it with a detector"
        echo "(e.g. sliding-window log analysis) running on the target to"
        echo "observe alerting behavior, not to actually take the host down."
    } | tee "$LOGFILE"

    ok "DoS lab demo finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_dos_lab "$TARGET"
fi
