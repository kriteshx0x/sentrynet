#!/bin/bash
# ==========================================================
# modules/web/08_api_testing.sh
# SAFE / PASSIVE to CONTROLLED / ACTIVE
#
# Objective: REST API assessment per OWASP API Security Top 10.
# Checks: endpoint/spec discovery, HTTP method behavior, security headers,
# basic authz signal (unauthenticated access to a supposedly protected path).
# Tools: curl
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_api_test() {
    local TARGET="$1"
    check_deps curl

    local LOGFILE
    LOGFILE=$(log_path "web_api")
    info "Logging to $LOGFILE"

    {
        echo "===== SentryNet API Testing: $TARGET ====="
        date

        echo -e "\n--- OpenAPI/Swagger discovery ---"
        for path in /swagger.json /swagger/v1/swagger.json /openapi.json /api-docs /v2/api-docs /api/swagger.json; do
            code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 6 "http://$TARGET$path")
            [ "$code" == "200" ] && ok "Found spec at $path (HTTP 200)"
        done

        read -rp "Enter an API endpoint path to test (e.g. /api/users): " api_path

        echo -e "\n--- HTTP method enumeration on $api_path ---"
        for method in GET POST PUT DELETE PATCH OPTIONS; do
            code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 6 -X "$method" "http://$TARGET$api_path")
            echo "$method -> HTTP $code"
        done
        echo "Interpretation: unexpected 200s on state-changing methods (PUT/DELETE/PATCH)"
        echo "without auth may indicate missing method-level authorization checks."

        echo -e "\n--- Security headers ---"
        curl -sI --max-time 8 "http://$TARGET$api_path" | grep -Ei "content-type|x-content-type-options|access-control-allow-origin"

        echo -e "\n--- Unauthenticated access check ---"
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "http://$TARGET$api_path")
        if [ "$code" == "200" ]; then
            warn "Endpoint returned HTTP 200 with no credentials — verify this is intentionally public."
        else
            info "Endpoint returned HTTP $code without credentials."
        fi

        echo -e "\n===== API test complete ====="
    } | tee "$LOGFILE"

    ok "API test finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_api_test "$TARGET"
fi
