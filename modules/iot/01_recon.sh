#!/bin/bash
# ==========================================================
# modules/iot/01_recon.sh
# SAFE / PASSIVE
#
# Objective: IoT device fingerprinting basics (many principles overlap
# with network recon, but framed around embedded-device banners/behavior).
# Works against any target incl. lab VMs — useful for demonstrating the
# methodology even without real IoT hardware present.
# Tools: nmap
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_recon() {
    local TARGET="$1"
    check_deps nmap

    local LOGFILE
    LOGFILE=$(log_path "iot_recon")
    info "Logging to $LOGFILE"

    {
        echo "===== SentryNet IoT Recon: $TARGET ====="
        date

        echo -e "\n--- Host discovery ---"
        nmap -sn "$TARGET"

        echo -e "\n--- Common IoT/embedded ports ---"
        # 23 telnet, 80/8080 http mgmt UI, 1883 MQTT, 5683 CoAP, 554 RTSP, 502 Modbus
        nmap -Pn -sV -p 21,22,23,80,443,502,554,1883,5683,8080,8443,49152 "$TARGET"

        echo -e "\n--- Banner grab on management/telnet ports ---"
        for port in 23 80; do
            echo "-- Port $port --"
            timeout 5 bash -c "echo | nc -w 3 $TARGET $port" 2>/dev/null | head -5
        done

        echo -e "\n===== IoT recon complete ====="
    } | tee "$LOGFILE"

    ok "IoT recon finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_recon "$TARGET"
fi
