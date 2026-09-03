#!/bin/bash
# ==========================================================
# modules/web/06_auth_testing.sh
# CONTROLLED / ACTIVE
#
# Objective: Authentication security testing per OWASP WSTG-ATHN.
# Covers: rate-limit behavior, account lockout, password policy signals.
# Credential testing here is LAB-ONLY and uses a small controlled
# candidate list — not a full brute-force spray.
# Tools: curl
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_auth_test() {
    local TARGET="$1"
    check_deps curl

    local LOGFILE
    LOGFILE=$(log_path "web_auth")
    info "Logging to $LOGFILE"

    read -rp "Enter login POST path (e.g. /login): " login_path
    read -rp "Enter username field name (e.g. username): " user_field
    read -rp "Enter password field name (e.g. password): " pass_field
    read -rp "Enter a test username (must be authorized for this lab): " test_user

    {
        echo "===== SentryNet Auth Testing: $TARGET$login_path ====="
        date

        echo -e "\n--- Rate-limit / lockout behavior (5 rapid attempts, bogus password) ---"
        for i in 1 2 3 4 5; do
            code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 \
                -d "${user_field}=${test_user}&${pass_field}=wrong_pw_${i}" \
                "http://$TARGET$login_path")
            echo "Attempt $i -> HTTP $code"
        done
        echo "Interpretation: if HTTP codes/response identical across attempts with no"
        echo "delay/CAPTCHA/lockout signal, rate limiting or lockout may be absent (finding)."

        echo -e "\n--- Security headers relevant to auth ---"
        curl -sI --max-time 8 "http://$TARGET$login_path" | grep -Ei "strict-transport-security|set-cookie|x-frame-options"

        echo -e "\n===== Auth test complete ====="
        echo "NOTE: This module observes behavior signals only. Full credential"
        echo "brute-forcing against arbitrary accounts is out of scope here —"
        echo "use modules/win/attack1_brute.sh pattern in an isolated lab if needed."
    } | tee "$LOGFILE"

    ok "Auth test finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_auth_test "$TARGET"
fi
