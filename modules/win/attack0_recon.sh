#!/bin/bash
# ==========================================================
# modules/win/attack0_recon.sh
# SAFE / PASSIVE to CONTROLLED / ACTIVE
#
# Objective: Reconnaissance/enumeration against an authorized Windows
# lab target (host discovery + service/OS detection).
# Tools: nmap
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_recon() {
    local TARGET="$1"
    check_deps nmap

    local LOGFILE
    LOGFILE=$(log_path "win_recon")

    if command -v figlet >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1; then
        figlet "Recon" | lolcat
    fi
    info "Target: $TARGET"
    info "Phase: Reconnaissance / Enumeration"

    info "Host discovery..."
    nmap -sn "$TARGET"

    echo ""
    info "Port + service scan..."
    nmap -sV -O -A "$TARGET" -oN "$LOGFILE"

    echo ""
    ok "Recon complete. Results saved to $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_recon "$TARGET"
fi
