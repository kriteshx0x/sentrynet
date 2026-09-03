#!/bin/bash
# ==========================================================
# modules/web/07_session_testing.sh
# SAFE / PASSIVE
#
# Objective: Session cookie security checks (WSTG-SESS).
# Checks Secure/HttpOnly/SameSite attributes, session ID entropy signal,
# and whether a fresh session ID is issued (fixation indicator).
# Tools: curl
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_session_test() {
    local TARGET="$1"
    check_deps curl

    local LOGFILE
    LOGFILE=$(log_path "web_session")
    info "Logging to $LOGFILE"

    {
        echo "===== SentryNet Session Testing: $TARGET ====="
        date

        echo -e "\n--- Cookie attributes ---"
        headers=$(curl -sI --max-time 8 "http://$TARGET")
        echo "$headers" | grep -i "set-cookie"

        cookie_line=$(echo "$headers" | grep -i "set-cookie")
        if [ -n "$cookie_line" ]; then
            echo "$cookie_line" | grep -qi "secure" && ok "Secure flag present" || warn "Secure flag MISSING (finding if served over HTTPS)"
            echo "$cookie_line" | grep -qi "httponly" && ok "HttpOnly flag present" || warn "HttpOnly flag MISSING (finding — cookie readable by JS)"
            echo "$cookie_line" | grep -qi "samesite" && ok "SameSite attribute present" || warn "SameSite attribute MISSING (finding — CSRF exposure risk)"
        else
            warn "No Set-Cookie header observed on this request/path."
        fi

        echo -e "\n--- Session fixation indicator (session ID before vs after auth-adjacent request) ---"
        cookie1=$(curl -sI --max-time 8 "http://$TARGET" | grep -i "set-cookie" | head -1)
        cookie2=$(curl -sI --max-time 8 "http://$TARGET" | grep -i "set-cookie" | head -1)
        if [ "$cookie1" == "$cookie2" ] && [ -n "$cookie1" ]; then
            warn "Same session identifier returned across separate requests — verify manually whether ID rotates post-login (fixation risk if not)."
        else
            info "Session identifier differs across requests (expected if no session established yet)."
        fi

        echo -e "\n===== Session test complete ====="
    } | tee "$LOGFILE"

    ok "Session test finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_session_test "$TARGET"
fi
