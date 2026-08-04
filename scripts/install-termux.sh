#!/usr/bin/env bash

set -eu

dry_run=false
repo_ref="${HERMES_ANDROID_REPO_REF:-v0.1.2}"
hermes_commit="${HERMES_AGENT_COMMIT:-c2ff2e8b17f5dd0460aa020aaa21deb59d7fe15f}"
raw_base="https://raw.githubusercontent.com/Dadmin88/hermes-desktop-android/$repo_ref"

usage() {
    cat <<'EOF'
Usage: install-termux.sh [--dry-run]

Run this stage in Termux, not inside Ubuntu. It installs the Android-side X11
and PRoot packages, creates the Ubuntu guest, and invokes the guest installer.
Hermes launches directly into Termux:X11; a desktop environment is optional.
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
case "$hermes_commit" in *[!A-Fa-f0-9]*) printf 'Invalid Hermes commit.\n' >&2; exit 2 ;; esac

run() {
    if [ "$dry_run" = true ]; then
        printf '%s\n' "$*"
    else
        "$@"
    fi
}

if [ "$dry_run" != true ] && [ "${HERMES_ANDROID_TEST_LAYER:-}" != "termux" ]; then
    if [ "${PREFIX:-}" != "/data/data/com.termux/files/usr" ]; then
        printf 'This stage must run in the Termux host shell, not inside Ubuntu.\n' >&2
        exit 1
    fi
fi

run pkg update -y
run pkg install -y x11-repo
run pkg install -y termux-x11-nightly proot-distro pulseaudio curl xfwm4

termux_prefix="${PREFIX:-/data/data/com.termux/files/usr}"
ubuntu_root="$termux_prefix/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ "$dry_run" = true ] || [ ! -d "$ubuntu_root" ]; then
    run proot-distro install ubuntu
fi

if [ "$dry_run" = true ]; then
    printf 'curl -fsSL %s/scripts/launch-android.sh -o %s/bin/hermes-android\n' \
        "$raw_base" "$termux_prefix"
    printf 'curl -fsSL %s/scripts/enter-ubuntu.sh -o %s/bin/hermes-ubuntu\n' \
        "$raw_base" "$termux_prefix"
    printf 'chmod +x %s/bin/hermes-android\n' "$termux_prefix"
    printf 'chmod +x %s/bin/hermes-ubuntu\n' "$termux_prefix"
    printf 'curl -fsSL %s/scripts/install-ubuntu.sh -o <shared-temporary-file>\n' \
        "$raw_base"
    printf 'proot-distro login ubuntu --shared-tmp -- bash /tmp/<temporary-file>\n'
    exit 0
fi

termux_tmp="$termux_prefix/tmp"
mkdir -p "$termux_tmp"
host_launcher_tmp=$(mktemp "$termux_tmp/hermes-android.XXXXXX")
ubuntu_helper_tmp=$(mktemp "$termux_tmp/hermes-ubuntu.XXXXXX")
guest_installer_tmp=$(mktemp "$termux_tmp/hermes-install-ubuntu.XXXXXX")
trap 'rm -f "$host_launcher_tmp" "$ubuntu_helper_tmp" "$guest_installer_tmp"' \
    EXIT HUP INT TERM

curl -fsSL "$raw_base/scripts/launch-android.sh" -o "$host_launcher_tmp"
curl -fsSL "$raw_base/scripts/enter-ubuntu.sh" -o "$ubuntu_helper_tmp"
curl -fsSL "$raw_base/scripts/install-ubuntu.sh" -o "$guest_installer_tmp"

proot-distro login ubuntu --shared-tmp -- \
    env \
        HERMES_ANDROID_REPO_REF="$repo_ref" \
        HERMES_AGENT_COMMIT="$hermes_commit" \
    bash "/tmp/$(basename "$guest_installer_tmp")"

install -m 0755 "$host_launcher_tmp" "$termux_prefix/bin/hermes-android"
install -m 0755 "$ubuntu_helper_tmp" "$termux_prefix/bin/hermes-ubuntu"

printf '\nInstallation complete. Open the Termux:X11 Android app, then run:\n\n'
printf '  hermes-android\n\n'
