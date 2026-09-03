#!/bin/bash
# ==========================================================
# sentrynet.sh
# SentryNet — Security Testing Framework
# Main interactive controller.
#
# Works from any cwd: resolves its own location so relative
# module paths always work regardless of where it's invoked from.
# ==========================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || { echo "[x] Failed to resolve SentryNet root directory."; exit 1; }

source "$SCRIPT_DIR/modules/common.sh"

# --- Ctrl+C handling: clean exit instead of dumping a raw shell trap ---
trap 'echo -e "\n"; warn "Interrupted. Exiting SentryNet."; exit 130' INT

# --- Core dependency check (tools every category may touch) ---
# Category-specific tools (hydra, msfconsole, nikto, etc.) are checked
# inside their own modules — this is just the baseline every path needs.
check_deps bash figlet

# --- Module existence + executable check ---
# Usage: run_module "modules/web/01_recon.sh"
run_module() {
    local module_path="$1"
    local full_path="$SCRIPT_DIR/$module_path"

    if [ ! -f "$full_path" ]; then
        error "Module not found: $module_path"
        warn "Expected at: $full_path"
        return 1
    fi
    if [ ! -x "$full_path" ]; then
        warn "Module not executable, fixing permissions: $module_path"
        chmod +x "$full_path"
    fi

    info "Starting module: $module_path"
    local start_ts
    start_ts=$(date +%s)

    bash "$full_path"
    local rc=$?

    local end_ts elapsed
    end_ts=$(date +%s)
    elapsed=$((end_ts - start_ts))

    if [ $rc -eq 0 ]; then
        ok "Module finished: $module_path (${elapsed}s)"
    else
        error "Module exited with code $rc: $module_path (${elapsed}s)"
    fi
    return $rc
}

banner() {
    clear
    if command -v figlet >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1; then
        figlet -f slant "SentryNet" | lolcat
    else
        echo "======== SentryNet ========"
    fi
    if command -v pv >/dev/null 2>&1; then
        echo "Modular Security Testing Framework" | pv -qL 30
    else
        echo "Modular Security Testing Framework"
    fi
    echo ""
}

pause() {
    echo ""
    read -rp "Press Enter to return to menu..." _
}

# ==========================================================
# WEB APPLICATION SUBMENU
# ==========================================================
menu_web() {
    while true; do
        banner
        echo "WEB APPLICATION"
        echo ""
        PS3=$'\nSelect: '
        options=(
            "Reconnaissance"
            "Port Scanning"
            "Vulnerability Scanning"
            "XSS Testing"
            "SQL Injection Testing"
            "Authentication Testing"
            "Session Testing"
            "API Testing"
            "Full Web Assessment"
            "Back"
        )
        select opt in "${options[@]}"; do
            case $opt in
                "Reconnaissance") run_module "modules/web/01_recon.sh"; pause; break ;;
                "Port Scanning") run_module "modules/web/02_port_scan.sh"; pause; break ;;
                "Vulnerability Scanning") run_module "modules/web/03_vuln_scan.sh"; pause; break ;;
                "XSS Testing") run_module "modules/web/04_xss.sh"; pause; break ;;
                "SQL Injection Testing") run_module "modules/web/05_sqli.sh"; pause; break ;;
                "Authentication Testing") run_module "modules/web/06_auth_testing.sh"; pause; break ;;
                "Session Testing") run_module "modules/web/07_session_testing.sh"; pause; break ;;
                "API Testing") run_module "modules/web/08_api_testing.sh"; pause; break ;;
                "Full Web Assessment")
                    warn "Full Web Assessment orchestration is not yet implemented (planned: Phase 13)."
                    warn "Run individual stages above for now."
                    pause; break ;;
                "Back") return ;;
                *) echo "Invalid option" ;;
            esac
        done
    done
}

# ==========================================================
# NETWORK SUBMENU
# ==========================================================
menu_network() {
    while true; do
        banner
        echo "NETWORK"
        echo ""
        PS3=$'\nSelect: '
        options=(
            "Reconnaissance"
            "Port Scanning"
            "DoS Lab (disruptive, lab only)"
            "MITM Lab (disruptive, lab only)"
            "ARP Lab"
            "DNS Lab"
            "Eavesdropping Lab"
            "Back"
        )
        select opt in "${options[@]}"; do
            case $opt in
                "Reconnaissance") run_module "modules/network/01_recon.sh"; pause; break ;;
                "Port Scanning") run_module "modules/network/02_port_scan.sh"; pause; break ;;
                "DoS Lab (disruptive, lab only)") run_module "modules/network/03_dos_lab.sh"; pause; break ;;
                "MITM Lab (disruptive, lab only)") run_module "modules/network/04_mitm_lab.sh"; pause; break ;;
                "ARP Lab") run_module "modules/network/05_arp_lab.sh"; pause; break ;;
                "DNS Lab") run_module "modules/network/06_dns_lab.sh"; pause; break ;;
                "Eavesdropping Lab") run_module "modules/network/07_eavesdropping_lab.sh"; pause; break ;;
                "Back") return ;;
                *) echo "Invalid option" ;;
            esac
        done
    done
}

# ==========================================================
# WINDOWS SUBMENU
# (win/ modules keep hardcoded lab-target IP by design — Phase 1 decision)
# ==========================================================
menu_win() {
    while true; do
        banner
        echo "WINDOWS"
        echo ""
        PS3=$'\nSelect: '
        options=(
            "Reconnaissance"
            "RDP Brute Force"
            "Reverse Shell (Metasploit)"
            "Mimikatz Credential Dumping"
            "Back"
        )
        select opt in "${options[@]}"; do
            case $opt in
                "Reconnaissance") run_module "modules/win/attack0_recon.sh"; pause; break ;;
                "RDP Brute Force") run_module "modules/win/attack1_brute.sh"; pause; break ;;
                "Reverse Shell (Metasploit)") run_module "modules/win/attack2_shell.sh"; pause; break ;;
                "Mimikatz Credential Dumping") run_module "modules/win/attack3_mimikatz.sh"; pause; break ;;
                "Back") return ;;
                *) echo "Invalid option" ;;
            esac
        done
    done
}

# ==========================================================
# SOCIAL ENGINEERING SUBMENU
# (social/ modules take no target — see module headers)
# ==========================================================
menu_social() {
    while true; do
        banner
        echo "SOCIAL ENGINEERING"
        echo ""
        PS3=$'\nSelect: '
        options=(
            "Phishing Awareness Lab"
            "URL Obfuscation Analyzer"
            "Watering-Hole Lab"
            "Back"
        )
        select opt in "${options[@]}"; do
            case $opt in
                "Phishing Awareness Lab") run_module "modules/social/01_phishing_lab.sh"; pause; break ;;
                "URL Obfuscation Analyzer") run_module "modules/social/02_url_obfuscation.sh"; pause; break ;;
                "Watering-Hole Lab") run_module "modules/social/03_waterhole_lab.sh"; pause; break ;;
                "Back") return ;;
                *) echo "Invalid option" ;;
            esac
        done
    done
}

# ==========================================================
# IOT SUBMENU
# ==========================================================
menu_iot() {
    while true; do
        banner
        echo "IOT"
        echo ""
        PS3=$'\nSelect: '
        options=(
            "Reconnaissance"
            "Port Scanning"
            "Service Enumeration"
            "Security Test"
            "Back"
        )
        select opt in "${options[@]}"; do
            case $opt in
                "Reconnaissance") run_module "modules/iot/01_recon.sh"; pause; break ;;
                "Port Scanning") run_module "modules/iot/02_port_scan.sh"; pause; break ;;
                "Service Enumeration") run_module "modules/iot/03_service_enum.sh"; pause; break ;;
                "Security Test") run_module "modules/iot/04_security_test.sh"; pause; break ;;
                "Back") return ;;
                *) echo "Invalid option" ;;
            esac
        done
    done
}

# ==========================================================
# MAIN MENU
# ==========================================================
main_menu() {
    while true; do
        banner
        echo "[1] Web Application"
        echo "[2] Network"
        echo "[3] Windows"
        echo "[4] Social Engineering"
        echo "[5] IoT"
        echo "[6] Exit"
        echo ""
        read -rp "Select: " choice
        case "$choice" in
            1) menu_web ;;
            2) menu_network ;;
            3) menu_win ;;
            4) menu_social ;;
            5) menu_iot ;;
            6) info "Exiting SentryNet."; exit 0 ;;
            *) warn "Invalid option: $choice" ;;
        esac
    done
}

main_menu
