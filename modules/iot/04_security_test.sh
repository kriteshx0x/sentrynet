#!/bin/bash
# ==========================================================
# modules/iot/04_security_test.sh
# CONTROLLED / ACTIVE
#
# Objective: Check IoT-typical weak-security patterns:
# default credentials on web mgmt UI, unencrypted management access,
# outdated/unsupported service banners.
# Tools: curl
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_security_test() {
    local TARGET="$1"
    check_deps curl

    local LOGFILE
    LOGFILE=$(log_path "iot_sectest")
    info "Logging to $LOGFILE"

    # Small, well-known IoT default credential set — detection only,
    # not a generic brute-force wordlist spray.
    local creds=("admin:admin" "admin:password" "admin:" "root:root" "admin:1234")

    read -rp "Enter web management login path (e.g. /login.cgi), or leave blank to skip: " login_path

    {
        echo "===== SentryNet IoT Security Test: $TARGET ====="
        date

        if [ -n "$login_path" ]; then
            echo -e "\n--- Default credential check (small known-default list only) ---"
            for cred in "${creds[@]}"; do
                user="${cred%%:*}"
                pass="${cred##*:}"
                code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 6 \
                    -d "username=$user&password=$pass" "http://$TARGET$login_path")
                echo "Tried $user:$pass -> HTTP $code"
            done
            echo "Interpretation: a 200/302 differing from failed-attempt baseline may indicate"
            echo "a default credential is accepted. Verify manually before reporting as confirmed."
        else
            warn "Skipping default-credential check (no login path provided)."
        fi

        echo -e "\n--- Unencrypted management access check ---"
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$TARGET")
        https_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://$TARGET" -k)
        if [ "$http_code" != "000" ] && [ "$https_code" == "000" ]; then
            warn "Device management appears reachable over HTTP only — no TLS available (finding)."
        fi

        echo -e "\n===== IoT security test complete ====="
    } | tee "$LOGFILE"

    ok "IoT security test finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_security_test "$TARGET"
fi
