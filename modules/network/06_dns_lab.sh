#!/bin/bash
# ==========================================================
# modules/network/06_dns_lab.sh
# SAFE / PASSIVE
#
# Objective: DNS enumeration and misconfiguration checks.
# Tools: dig
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_dns_lab() {
    local TARGET="$1"
    check_deps dig

    local LOGFILE
    LOGFILE=$(log_path "net_dns")
    info "Logging to $LOGFILE"

    {
        echo "===== SentryNet DNS Recon: $TARGET ====="
        date

        echo -e "\n--- Standard records ---"
        for rtype in A AAAA MX NS TXT SOA CNAME; do
            echo "-- $rtype --"
            dig +short "$TARGET" "$rtype"
        done

        echo -e "\n--- Zone transfer attempt (should fail on a properly configured DNS server) ---"
        ns_servers=$(dig +short NS "$TARGET")
        for ns in $ns_servers; do
            echo "Trying AXFR against $ns..."
            result=$(dig axfr "$TARGET" "@$ns" 2>&1)
            if echo "$result" | grep -qi "Transfer failed\|connection refused\|communications error"; then
                echo "$ns: zone transfer correctly refused."
            else
                warn "$ns: zone transfer may have SUCCEEDED — potential misconfiguration finding."
                echo "$result"
            fi
        done

        echo -e "\n===== DNS recon complete ====="
    } | tee "$LOGFILE"

    ok "DNS recon finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_dns_lab "$TARGET"
fi
