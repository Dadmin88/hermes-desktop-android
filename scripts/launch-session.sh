#!/usr/bin/env bash

set -eu

dry_run=false

usage() {
    cat <<'EOF'
Usage: hermes-android-session [--dry-run]

Run inside the Ubuntu PRoot guest. It reuses the X11/Xfce session running in
Termux and launches the source-mode Hermes Desktop wrapper.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run) dry_run=true ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

export DISPLAY="${DISPLAY:-:1}"
export PULSE_SERVER="${PULSE_SERVER:-127.0.0.1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/hermes-runtime-root}"

if [ "$dry_run" = true ]; then
    printf 'DISPLAY=%s\n' "$DISPLAY"
    printf 'PULSE_SERVER=%s\n' "$PULSE_SERVER"
    printf 'hermes-android-desktop\n'
    exit 0
fi

if [ "${HERMES_ANDROID_TEST_LAYER:-}" != "proot" ] \
    && ! uname -r 2>/dev/null | grep -qi 'proot-distro'; then
    printf 'Run hermes-android-session inside the Ubuntu PRoot guest.\n' >&2
    exit 1
fi

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

exec hermes-android-desktop
