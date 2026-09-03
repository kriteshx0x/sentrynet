#!/bin/bash
# ==========================================================
# modules/web/01_recon.sh
# SAFE / PASSIVE
#
# Objective: Passive-to-light-active web reconnaissance.
# Attack surface: DNS, HTTP/HTTPS presence, headers, TLS, tech stack.
# Tools: dig/host, curl, openssl, whatweb (optional)
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_recon() {
    local TARGET="$1"
    check_deps curl dig

    local LOGFILE
    LOGFILE=$(log_path "web_recon")
    info "Logging to $LOGFILE"

    {
        echo "===== SentryNet Web Recon: $TARGET ====="
        date

        echo -e "\n--- DNS ---"
        dig +short "$TARGET" A
        dig +short "$TARGET" AAAA
        host "$TARGET" 2>/dev/null

        echo -e "\n--- HTTP/HTTPS reachability ---"
        for scheme in http https; do
            code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$scheme://$TARGET")
            echo "$scheme://$TARGET -> HTTP $code"
        done

        echo -e "\n--- HTTP headers ---"
        curl -sI --max-time 8 "https://$TARGET" 2>/dev/null || curl -sI --max-time 8 "http://$TARGET"

        echo -e "\n--- TLS certificate info ---"
        echo | openssl s_client -connect "$TARGET:443" -servername "$TARGET" 2>/dev/null \
            | openssl x509 -noout -subject -issuer -dates 2>/dev/null \
            || echo "No TLS on 443 or connection failed."

        echo -e "\n--- Technology fingerprinting ---"
        if command -v whatweb >/dev/null 2>&1; then
            whatweb --no-errors "$TARGET"
        else
            warn "whatweb not installed — skipping tech fingerprinting (optional dependency)."
        fi

        echo -e "\n===== Recon complete ====="
    } | tee "$LOGFILE"

    ok "Web recon finished. Results: $LOGFILE"
}

# Standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_recon "$TARGET"
fi
