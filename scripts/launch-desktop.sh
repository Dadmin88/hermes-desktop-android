#!/usr/bin/env bash

set -eu

print_command=false

usage() {
    cat <<'EOF'
Usage: launch-desktop.sh [--print-command]

Launch the source-mode Hermes Electron desktop inside the PRoot Linux guest.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --print-command) print_command=true ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

find_hermes_root() {
    local candidate
    for candidate in \
        "${HERMES_DESKTOP_HERMES_ROOT:-}" \
        "${HERMES_INSTALL_DIR:-}" \
        /usr/local/lib/hermes-agent \
        "$HOME/.hermes/hermes-agent"; do
        if [ -n "$candidate" ] && [ -d "$candidate/apps/desktop" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

find_workspace_electron() {
    local root="$1"
    local candidate
    for candidate in \
        "$root/node_modules/electron/dist/electron" \
        "$root/apps/desktop/node_modules/electron/dist/electron"; do
        if [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

if ! hermes_root=$(find_hermes_root); then
    printf 'Hermes source checkout not found. Install Hermes in Ubuntu first.\n' >&2
    exit 1
fi

desktop_dir="$hermes_root/apps/desktop"
source_index="$desktop_dir/dist/index.html"
if [ ! -f "$source_index" ]; then
    printf 'Hermes Desktop source build not found: %s\n' "$source_index" >&2
    printf 'Build it with: hermes desktop --source --build-only\n' >&2
    exit 1
fi

if ! electron=$(find_workspace_electron "$hermes_root"); then
    printf 'Hermes workspace Electron runtime not found under: %s\n' "$hermes_root" >&2
    printf 'Repair it with: hermes desktop --source --build-only --force-build --hermes-root %s\n' \
        "$hermes_root" >&2
    exit 1
fi

export DISPLAY="${DISPLAY:-:1}"
export HERMES_DESKTOP_HERMES_ROOT="$hermes_root"
if command -v hermes >/dev/null 2>&1; then
    HERMES_DESKTOP_HERMES=$(command -v hermes)
    export HERMES_DESKTOP_HERMES
fi
export HERMES_DESKTOP_CWD="${HERMES_DESKTOP_CWD:-$PWD}"
export AGENT_BROWSER_HEADED="${AGENT_BROWSER_HEADED:-1}"
export AGENT_BROWSER_ARGS="${AGENT_BROWSER_ARGS:---no-sandbox,--disable-dev-shm-usage}"

if [ "${HERMES_ANDROID_SKIP_DISPLAY_CHECK:-0}" != "1" ]; then
    display_number=${DISPLAY#:}
    display_number=${display_number%%.*}
    if [ ! -S "/tmp/.X11-unix/X$display_number" ]; then
        printf 'Termux:X11 display %s is not reachable in this PRoot guest.\n' "$DISPLAY" >&2
        printf 'Start Termux:X11 and enter Ubuntu with proot-distro --shared-tmp.\n' >&2
        exit 1
    fi
fi

if [ "$print_command" = true ]; then
    printf '%s --no-sandbox %s\n' "$electron" "$desktop_dir"
    exit 0
fi

exec "$electron" --no-sandbox "$desktop_dir"
