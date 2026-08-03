#!/usr/bin/env bash

set -eu

dry_run=false
repo_ref="${HERMES_ANDROID_REPO_REF:-v0.1.1}"
raw_base="https://raw.githubusercontent.com/Dadmin88/hermes-desktop-android/$repo_ref"

usage() {
    cat <<'EOF'
Usage: install-launchers.sh [--dry-run]

Install only this project's Termux and Ubuntu launch wrappers. This does not
install packages, change the Hermes checkout, or rebuild Hermes Desktop.
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

case "$repo_ref" in *[!A-Za-z0-9._/-]*) printf 'Invalid repository ref.\n' >&2; exit 2 ;; esac

termux_prefix="${PREFIX:-/data/data/com.termux/files/usr}"

if [ "$dry_run" = true ]; then
    printf 'curl -fsSL %s/scripts/launch-android.sh -o %s/bin/hermes-android\n' \
        "$raw_base" "$termux_prefix"
    printf 'curl -fsSL %s/scripts/enter-ubuntu.sh -o %s/bin/hermes-ubuntu\n' \
        "$raw_base" "$termux_prefix"
    printf 'proot-distro login ubuntu --shared-tmp -- install launch-desktop.sh as /usr/local/bin/hermes-android-desktop\n'
    printf 'proot-distro login ubuntu --shared-tmp -- install launch-session.sh as /usr/local/bin/hermes-android-session\n'
    exit 0
fi

if [ "${HERMES_ANDROID_TEST_LAYER:-}" != "termux" ] \
    && [ "${PREFIX:-}" != "/data/data/com.termux/files/usr" ]; then
    printf 'Run this launcher installer from the Termux host shell.\n' >&2
    exit 1
fi

host_tmp=$(mktemp)
ubuntu_helper_tmp=$(mktemp)
trap 'rm -f "$host_tmp" "$ubuntu_helper_tmp"' EXIT HUP INT TERM
curl -fsSL "$raw_base/scripts/launch-android.sh" -o "$host_tmp"
curl -fsSL "$raw_base/scripts/enter-ubuntu.sh" -o "$ubuntu_helper_tmp"
install -m 0755 "$host_tmp" "$termux_prefix/bin/hermes-android"
install -m 0755 "$ubuntu_helper_tmp" "$termux_prefix/bin/hermes-ubuntu"

# The variables below intentionally expand inside the guest shell, not here.
# shellcheck disable=SC2016
proot-distro login ubuntu --shared-tmp -- env RAW_BASE="$raw_base" bash -lc '
set -eu
desktop_tmp=$(mktemp)
session_tmp=$(mktemp)
trap '\''rm -f "$desktop_tmp" "$session_tmp"'\'' EXIT HUP INT TERM
curl -fsSL "$RAW_BASE/scripts/launch-desktop.sh" -o "$desktop_tmp"
curl -fsSL "$RAW_BASE/scripts/launch-session.sh" -o "$session_tmp"
install -m 0755 "$desktop_tmp" /usr/local/bin/hermes-android-desktop
install -m 0755 "$session_tmp" /usr/local/bin/hermes-android-session
'

printf 'Launchers installed. Start Hermes Desktop with: hermes-android\n'
printf 'Enter the Ubuntu guest with: hermes-ubuntu\n'
