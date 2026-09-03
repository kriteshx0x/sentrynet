#!/bin/bash
# ==========================================================
# modules/web/03_vuln_scan.sh
# CONTROLLED / ACTIVE
#
# Objective: Automated vulnerability/misconfiguration discovery.
# Tools: nikto (baseline), nuclei (optional, template-based)
# Prefers detection/evidence over exploitation. Distinguishes
# informational findings from confirmed issues where tools support it.
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_vuln_scan() {
    local TARGET="$1"
    check_deps curl

    local LOGFILE
    LOGFILE=$(log_path "web_vulnscan")
    info "Logging to $LOGFILE"

    {
        echo "===== SentryNet Web Vulnerability Scan: $TARGET ====="
        date

        if command -v nikto >/dev/null 2>&1; then
            echo -e "\n--- Nikto baseline scan ---"
            run_with_timeout 600 nikto -h "$TARGET" -Tuning x
        else
            warn "nikto not installed — skipping baseline scan."
            echo "Install with: sudo apt install nikto"
        fi

        if command -v nuclei >/dev/null 2>&1; then
            echo -e "\n--- Nuclei template scan (known CVEs + misconfigs) ---"
            run_with_timeout 600 nuclei -u "http://$TARGET" -silent -severity low,medium,high,critical
        else
            warn "nuclei not installed (optional) — skipping template-based scan."
            echo "Install: https://github.com/projectdiscovery/nuclei"
        fi

        echo -e "\n===== Vulnerability scan complete ====="
        echo "NOTE: Findings above are informational/candidate until manually verified."
    } | tee "$LOGFILE"

    ok "Vulnerability scan finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_vuln_scan "$TARGET"
fi
