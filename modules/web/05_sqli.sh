#!/bin/bash
# ==========================================================
# modules/web/05_sqli.sh
# CONTROLLED / ACTIVE
#
# Objective: Detect SQL injection indicators via boolean/error-based probes.
# Does NOT dump databases or automate exploitation — detection + evidence
# collection only, consistent with the project's ethical scope.
# Tools: curl (built-in probes), sqlmap (optional, detection-only flags)
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_sqli_test() {
    local TARGET="$1"
    check_deps curl

    local LOGFILE
    LOGFILE=$(log_path "web_sqli")
    info "Logging to $LOGFILE"

    read -rp "Enter path with parameter to test (e.g. /product?id=FUZZ): " path
    if [[ "$path" != *"FUZZ"* ]]; then
        error "Path must contain the literal string FUZZ marking the injection point."
        return 1
    fi

    {
        echo "===== SentryNet SQLi Indicator Test: $TARGET$path ====="
        date

        echo -e "\n--- Error-based probe ---"
        local err_url="http://$TARGET${path/FUZZ/%27}"   # single quote
        local base_url="http://$TARGET${path/FUZZ/1}"
        base_len=$(curl -s --max-time 8 "$base_url" | wc -c)
        err_len=$(curl -s --max-time 8 "$err_url" | wc -c)
        echo "Baseline response length: $base_len"
        echo "Single-quote response length: $err_len"
        if [ "$base_len" != "$err_len" ]; then
            echo "[CANDIDATE FINDING] Response length changed with unescaped quote — possible SQL error/behavior change."
        fi
        curl -s --max-time 8 "$err_url" | grep -Eio "sql syntax|mysql_fetch|ORA-[0-9]+|SQLite3?::|PostgreSQL.*ERROR" \
            && echo "[CANDIDATE FINDING] Database error string leaked in response."

        echo -e "\n--- Boolean-based probe ---"
        local true_url="http://$TARGET${path/FUZZ/1%20AND%201=1}"
        local false_url="http://$TARGET${path/FUZZ/1%20AND%201=2}"
        true_len=$(curl -s --max-time 8 "$true_url" | wc -c)
        false_len=$(curl -s --max-time 8 "$false_url" | wc -c)
        echo "TRUE condition length: $true_len | FALSE condition length: $false_len"
        if [ "$true_len" != "$false_len" ]; then
            echo "[CANDIDATE FINDING] Boolean condition changes response — possible boolean-based SQLi."
        fi

        if command -v sqlmap >/dev/null 2>&1; then
            echo -e "\n--- sqlmap detection-only pass (--batch, no dump) ---"
            run_with_timeout 300 sqlmap -u "http://$TARGET${path/FUZZ/1}" --batch --level 1 --risk 1 --dbms= 2>&1 \
                | grep -Ei "parameter.*is vulnerable|back-end DBMS|not injectable"
        else
            warn "sqlmap not installed (optional) — skipping automated confirmation pass."
        fi

        echo -e "\n===== SQLi test complete ====="
        echo "NOTE: All findings are candidates. No data extraction performed."
    } | tee "$LOGFILE"

    ok "SQLi test finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_sqli_test "$TARGET"
fi
