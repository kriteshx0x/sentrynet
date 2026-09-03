#!/bin/bash
# ==========================================================
# modules/social/02_url_obfuscation.sh
# SAFE / PASSIVE (Educational/Defensive)
#
# Objective: Given a URL, DETECT and EXPLAIN common obfuscation/deception
# techniques attackers use (homograph-like lookalikes, @ tricks, IP-as-
# hostname, excessive subdomains) — a defensive/awareness lens, not a
# tool for generating deceptive links against real targets.
# Tools: none required (pure bash/python parsing)
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_url_check() {
    local LOGFILE
    LOGFILE=$(log_path "social_url_obfuscation")

    read -rp "Enter a URL to analyze for deception indicators: " url

    {
        echo "===== SentryNet URL Deception Analysis ====="
        date
        echo "URL: $url"
        echo ""

        if [[ "$url" == *"@"* ]]; then
            warn "Contains '@' — text before '@' in a URL is ignored by browsers;"
            echo "  attackers use this to make a URL look like it points to a trusted"
            echo "  domain while actually navigating elsewhere (e.g. trusted.com@evil.com)."
        fi

        host=$(python3 -c "import sys,urllib.parse; print(urllib.parse.urlparse(sys.argv[1]).hostname or '')" "$url" 2>/dev/null)
        if [[ "$host" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
            warn "Hostname is a raw IP address ($host) — legitimate services rarely"
            echo "  link directly to an IP; often used to bypass domain reputation checks."
        fi

        dot_count=$(echo "$host" | tr -cd '.' | wc -c)
        if [ "$dot_count" -ge 4 ]; then
            warn "Excessive subdomain depth ($dot_count dots) — can be used to bury the"
            echo "  real domain and make the URL look longer/more 'official'."
        fi

        if [[ "$url" == *"xn--"* ]]; then
            warn "Contains punycode (xn--) — may indicate an internationalized domain"
            echo "  being used for a homograph/lookalike attack. Verify the real script/characters."
        fi

        if command -v curl >/dev/null 2>&1; then
            final=$(curl -sL -o /dev/null -w "%{url_effective}" --max-time 8 "$url" 2>/dev/null)
            if [ "$final" != "$url" ] && [ -n "$final" ]; then
                warn "URL redirects to a different final destination: $final"
            fi
        fi

        echo -e "\n===== Analysis complete ====="
        echo "This is an awareness tool: teach users to check these signals"
        echo "before clicking, not a substitute for URL-reputation services."
    } | tee "$LOGFILE"

    ok "URL analysis finished. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_url_check
fi
