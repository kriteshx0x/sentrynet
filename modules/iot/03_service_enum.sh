#!/bin/bash
# ==========================================================
# modules/iot/03_service_enum.sh
# SAFE / PASSIVE to CONTROLLED / ACTIVE
#
# Objective: Enumerate IoT-relevant services found on target (MQTT, CoAP,
# RTSP, web management UI) and pull identifying banners/info.
# Tools: nmap NSE scripts, curl
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_service_enum() {
    local TARGET="$1"
    check_deps nmap curl

    local LOGFILE
    LOGFILE=$(log_path "iot_svcenum")
    info "Logging to $LOGFILE"

    {
        echo "===== SentryNet IoT Service Enumeration: $TARGET ====="
        date

        echo -e "\n--- HTTP management interface check ---"
        for port in 80 8080 8443; do
            code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$TARGET:$port")
            [ "$code" != "000" ] && echo "Port $port -> HTTP $code (possible mgmt UI, check for default creds manually)"
        done

        echo -e "\n--- MQTT probe (port 1883) ---"
        nmap -Pn -p 1883 --script mqtt-subscribe "$TARGET" 2>/dev/null | grep -A5 "1883"

        echo -e "\n--- RTSP probe (port 554) ---"
        nmap -Pn -p 554 --script rtsp-methods "$TARGET" 2>/dev/null | grep -A5 "554"

        echo -e "\n--- SNMP probe (port 161, common default community strings) ---"
        if command -v snmpwalk >/dev/null 2>&1; then
            for community in public private; do
                echo "Trying community: $community"
                timeout 5 snmpwalk -v2c -c "$community" "$TARGET" 2>/dev/null | head -5
            done
        else
            warn "snmpwalk not installed (optional) — skipping SNMP probe."
        fi

        echo -e "\n===== IoT service enumeration complete ====="
    } | tee "$LOGFILE"

    ok "Service enumeration finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_service_enum "$TARGET"
fi
