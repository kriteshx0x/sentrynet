#!/bin/bash
# ==========================================================
# modules/social/03_waterhole_lab.sh
# CONTROLLED / ACTIVE — LAB ONLY
#
# Objective: Demonstrate watering-hole attack concept for awareness
# training: how a legitimate-looking internal lab page could be used
# to serve a benign "payload" (harmless marker file) to illustrate the
# technique to trainees. Runs a local HTTP server only — never targets
# an external/real website.
# Tools: python3 (http.server)
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_waterhole_lab() {
    check_deps python3

    warn "=============================================="
    warn " This module stands up a LOCAL demo web server"
    warn " only, to illustrate watering-hole concepts for"
    warn " training. It does not compromise any real site."
    warn "=============================================="
    read -rp "Confirm this is for an authorized internal lab exercise (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        error "Not confirmed. Aborting."
        return 1
    fi

    read -rp "Local port to serve demo page on (e.g. 8090): " port
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
        error "Invalid port. Use a value between 1024-65535."
        return 1
    fi

    local DEMO_DIR="$SENTRYNET_ROOT/logs/waterhole_demo"
    mkdir -p "$DEMO_DIR"

    cat > "$DEMO_DIR/index.html" <<'EOF'
<!DOCTYPE html>
<html>
<head><title>Internal Resource Portal</title></head>
<body style="font-family: sans-serif;">
  <h2>Internal Resource Portal (SentryNet Watering-Hole Demo)</h2>
  <p>This page simulates a compromised commonly-visited internal site.</p>
  <p>In a real watering-hole attack, this page would silently attempt to
  exploit a visitor's browser or prompt a fake update download.</p>
  <p>Marker file for lab detection: <a href="marker.txt">marker.txt</a></p>
</body>
</html>
EOF
    echo "SentryNet watering-hole lab marker — harmless, for detection-tooling demo only." \
        > "$DEMO_DIR/marker.txt"

    local LOGFILE
    LOGFILE=$(log_path "social_waterhole")
    {
        echo "===== SentryNet Watering-Hole Lab Demo ====="
        date
        echo "Serving $DEMO_DIR on http://0.0.0.0:$port"
        echo "Visit from a lab client VM to demonstrate the concept."
        echo "Press Ctrl+C to stop the server."
    } | tee "$LOGFILE"

    cd "$DEMO_DIR" && python3 -m http.server "$port"

    ok "Waterhole lab demo server stopped. Log: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_waterhole_lab
fi
