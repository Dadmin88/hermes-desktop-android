#!/usr/bin/env bash

set -eu

dry_run=false
repo_ref="${HERMES_ANDROID_REPO_REF:-main}"
hermes_commit="${HERMES_AGENT_COMMIT:-c2ff2e8b17f5dd0460aa020aaa21deb59d7fe15f}"
project_raw="https://raw.githubusercontent.com/Dadmin88/hermes-desktop-android/$repo_ref"
upstream_installer="https://raw.githubusercontent.com/NousResearch/hermes-agent/$hermes_commit/scripts/install.sh"
hermes_root="${HERMES_INSTALL_DIR:-/usr/local/lib/hermes-agent}"

usage() {
    cat <<'EOF'
Usage: install-ubuntu.sh [--dry-run]

Run this stage as root inside the Ubuntu PRoot guest. The Termux installer
normally invokes it automatically.
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

if [ "$dry_run" != true ]; then
    if [ "${HERMES_ANDROID_TEST_LAYER:-}" != "proot" ] \
        && ! uname -r 2>/dev/null | grep -qi 'proot-distro'; then
        printf 'This stage is intended for the Ubuntu PRoot guest.\n' >&2
        exit 1
    fi
    if [ "$(id -u)" -ne 0 ]; then
        printf 'Run this Ubuntu guest stage as root.\n' >&2
        exit 1
    fi
fi

if [ -d "$hermes_root/.git" ]; then
    current_commit=$(git -C "$hermes_root" rev-parse HEAD 2>/dev/null || true)
    if [ "$current_commit" != "$hermes_commit" ] \
        && [ "${HERMES_ANDROID_ALLOW_EXISTING_REPLACE:-0}" != "1" ]; then
        printf 'Refusing to replace existing Hermes checkout at %s.\n' "$hermes_root" >&2
        printf 'Current commit: %s\n' "${current_commit:-unknown}" >&2
        printf 'Tested commit:  %s\n' "$hermes_commit" >&2
        printf 'Back up your changes, then explicitly set ' >&2
        printf 'HERMES_ANDROID_ALLOW_EXISTING_REPLACE=1 if replacement is intentional.\n' >&2
        exit 1
    fi
fi

export DEBIAN_FRONTEND=noninteractive
run apt-get update
run apt-get install -y \
    ca-certificates curl git build-essential xz-utils procps

if [ "$dry_run" = true ]; then
    printf 'curl -fsSL %s -o <temporary-file>\n' "$upstream_installer"
    printf 'bash <temporary-file> --skip-setup --commit %s --force-commit\n' \
        "$hermes_commit"
else
    upstream_installer_tmp=$(mktemp)
    desktop_launcher_tmp=$(mktemp)
    session_launcher_tmp=$(mktemp)
    trap 'rm -f "$upstream_installer_tmp" "$desktop_launcher_tmp" "$session_launcher_tmp"' \
        EXIT HUP INT TERM

    curl -fsSL "$upstream_installer" -o "$upstream_installer_tmp"
    bash "$upstream_installer_tmp" \
        --skip-setup --commit "$hermes_commit" --force-commit
fi

run hermes desktop --source --build-only --force-build --hermes-root "$hermes_root"

if [ "$dry_run" = true ]; then
    printf 'curl -fsSL %s/scripts/launch-desktop.sh -o /usr/local/bin/hermes-android-desktop\n' \
        "$project_raw"
    printf 'curl -fsSL %s/scripts/launch-session.sh -o /usr/local/bin/hermes-android-session\n' \
        "$project_raw"
    printf 'chmod +x /usr/local/bin/hermes-android-desktop /usr/local/bin/hermes-android-session\n'
    exit 0
fi

curl -fsSL "$project_raw/scripts/launch-desktop.sh" -o "$desktop_launcher_tmp"
curl -fsSL "$project_raw/scripts/launch-session.sh" -o "$session_launcher_tmp"
install -m 0755 "$desktop_launcher_tmp" /usr/local/bin/hermes-android-desktop
install -m 0755 "$session_launcher_tmp" /usr/local/bin/hermes-android-session

printf '\nUbuntu guest installation complete.\n'
