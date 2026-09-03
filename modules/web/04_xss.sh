#!/bin/bash
# ==========================================================
# modules/web/04_xss.sh
# CONTROLLED / ACTIVE
#
# Objective: Test authorized web app for common reflected-XSS conditions.
# Approach: Send a small, non-destructive set of canary payloads to a
# URL parameter and check if they are reflected unescaped. This is a
# DETECTION check, not an exploitation framework — flags candidates
# for manual verification, does not attempt to steal cookies/pivot.
# Tools: curl
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_xss_test() {
    local TARGET="$1"
    check_deps curl

    local LOGFILE
    LOGFILE=$(log_path "web_xss")
    info "Logging to $LOGFILE"

    read -rp "Enter path with parameter to test (e.g. /search?q=FUZZ): " path
    if [[ "$path" != *"FUZZ"* ]]; then
        error "Path must contain the literal string FUZZ marking the injection point."
        return 1
    fi

    # Small, distinct canary set — not a payload-spray. Each is unique enough
    # to positively confirm reflection without collateral effect.
    local canaries=(
        '<sentrynet_xss_test>'
        '"><sentrynet_xss_test>'
        "'><sentrynet_xss_test>"
    )

    {
        echo "===== SentryNet XSS Reflection Test: $TARGET$path ====="
        date
        for c in "${canaries[@]}"; do
            local encoded
            encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$c")
            local url="http://$TARGET${path/FUZZ/$encoded}"
            echo -e "\n--- Testing payload: $c ---"
            echo "URL: $url"
            local body
            body=$(curl -s --max-time 8 "$url")
            if echo "$body" | grep -qF "$c"; then
                echo "[CANDIDATE FINDING] Payload reflected unescaped in response."
            else
                echo "Not reflected (or escaped/filtered)."
            fi
        done
        echo -e "\n===== XSS test complete ====="
        echo "NOTE: All findings are candidates requiring manual verification"
        echo "(context: HTML body vs attribute vs script, actual execution, WAF behavior)."
    } | tee "$LOGFILE"

    ok "XSS test finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_xss_test "$TARGET"
fi
