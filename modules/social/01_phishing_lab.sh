#!/bin/bash
# ==========================================================
# modules/social/01_phishing_lab.sh
# CONTROLLED / ACTIVE — LAB ONLY
#
# Objective: Generate an authorized phishing-awareness training email
# template + track link, for use in an internal lab environment with
# a mail server you control (e.g. MailHog/Mailpit) and a landing page
# you control. This does NOT send email to arbitrary addresses or
# stand up infrastructure targeting real third parties.
#
# Note: unlike web/network/iot, this module does not take a scannable
# "target" — it takes a lab campaign name and a local SMTP endpoint.
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

run_phishing_lab() {
    check_deps curl

    warn "=============================================="
    warn " This module generates a phishing-awareness"
    warn " TEMPLATE for use in your own isolated lab mail"
    warn " environment. It will not send mail to real"
    warn " external recipients."
    warn "=============================================="
    read -rp "Confirm this is for an authorized internal lab exercise (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        error "Not confirmed. Aborting."
        return 1
    fi

    read -rp "Campaign name (e.g. password-reset-test): " campaign
    read -rp "Lab landing page URL (must be a host you control): " landing_url

    local LOGFILE OUTFILE
    LOGFILE=$(log_path "social_phishing")
    OUTFILE="$SENTRYNET_ROOT/logs/${campaign}_template.html"

    cat > "$OUTFILE" <<EOF
<!-- SentryNet phishing-awareness training template: $campaign -->
<!-- FOR INTERNAL AUTHORIZED SECURITY AWARENESS TRAINING ONLY -->
<html>
<body style="font-family: sans-serif;">
  <p>Hi,</p>
  <p>We noticed unusual activity on your account. Please verify your details:</p>
  <p><a href="$landing_url">Verify Account</a></p>
  <p>This is a simulated phishing message as part of an internal security
  awareness exercise. If this were real, hovering over the link and checking
  the sender domain would have revealed the deception.</p>
</body>
</html>
EOF

    {
        echo "===== SentryNet Phishing Awareness Template Generated ====="
        date
        echo "Campaign: $campaign"
        echo "Landing page (lab-controlled): $landing_url"
        echo "Template saved to: $OUTFILE"
        echo ""
        echo "Next steps (manual, in your lab):"
        echo "1. Load this template into your lab mail tool (e.g. GoPhish, MailHog)."
        echo "2. Send only to lab/test mailboxes you control."
        echo "3. Track landing-page hits on your own controlled endpoint."
    } | tee "$LOGFILE"

    ok "Phishing awareness template ready: $OUTFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_phishing_lab
fi
