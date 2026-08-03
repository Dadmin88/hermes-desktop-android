#!/usr/bin/env bash

set -u

section() {
    printf '\n## %s\n' "$1"
}

value_or_missing() {
    local label="$1"
    shift
    local output

    if output=$("$@" 2>/dev/null); then
        printf '%-22s %s\n' "$label" "${output:-<empty>}"
    else
        printf '%-22s %s\n' "$label" "<missing>"
    fi
}

command_path() {
    command -v "$1" 2>/dev/null || return 1
}

package_version() {
    local package="$1"

    if command -v dpkg-query >/dev/null 2>&1; then
        dpkg-query -W -f='${Version}' "$package" 2>/dev/null
        return
    fi

    return 1
}

detect_environment_layer() {
    case "${HERMES_DOCTOR_LAYER_OVERRIDE:-}" in
        termux|proot|linux)
            printf '%s\n' "$HERMES_DOCTOR_LAYER_OVERRIDE"
            return 0
            ;;
    esac

    if uname -r 2>/dev/null | grep -qi 'proot-distro'; then
        printf 'proot\n'
    elif [ -n "${TERMUX_VERSION:-}" ] || [ "${PREFIX:-}" = "/data/data/com.termux/files/usr" ]; then
        printf 'termux\n'
    else
        printf 'linux\n'
    fi
}

environment_layer=$(detect_environment_layer)

find_hermes_root() {
    local candidates=(
        "${HERMES_DESKTOP_HERMES_ROOT:-}"
        "${HERMES_INSTALL_DIR:-}"
        "$HOME/.hermes/hermes-agent"
    )
    local candidate

    for candidate in "${candidates[@]}"; do
        if [ -n "$candidate" ] && [ -d "$candidate/.git" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

printf 'Hermes Android Desktop doctor\n'
printf 'Generated: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

section "Host"
value_or_missing "Kernel" uname -srmo
value_or_missing "Architecture" uname -m
value_or_missing "Android release" getprop ro.build.version.release
value_or_missing "Android SDK" getprop ro.build.version.sdk
value_or_missing "Device model" getprop ro.product.model
value_or_missing "Manufacturer" getprop ro.product.manufacturer
case "$environment_layer" in
    termux) printf '%-22s %s\n' "Environment layer" "Termux host" ;;
    proot) printf '%-22s %s\n' "Environment layer" "PRoot Linux guest" ;;
    *) printf '%-22s %s\n' "Environment layer" "Linux host" ;;
esac
printf '%-22s %s\n' "PREFIX" "${PREFIX:-<unset>}"
printf '%-22s %s\n' "DISPLAY" "${DISPLAY:-<unset>}"
printf '%-22s %s\n' "XDG session" "${XDG_SESSION_TYPE:-<unset>}"
if [ -n "${TERMUX_VERSION:-}" ] || [ -d /data/data/com.termux ]; then
    printf '%-22s %s\n' "Termux detected" "yes"
else
    printf '%-22s %s\n' "Termux detected" "no"
fi

if [ -r /etc/os-release ]; then
    section "Linux environment"
    # shellcheck disable=SC1091
    . /etc/os-release
    printf '%-22s %s\n' "Distribution" "${PRETTY_NAME:-${NAME:-unknown}}"
fi

section "Runtime"
value_or_missing "Python" python --version
value_or_missing "Python 3" python3 --version
value_or_missing "Node" node --version
value_or_missing "npm" npm --version
value_or_missing "Git" git --version
value_or_missing "Hermes command" command_path hermes
value_or_missing "Hermes version" hermes version
value_or_missing "Electron command" command_path electron
value_or_missing "Chromium command" command_path chromium
value_or_missing "Chrome command" command_path google-chrome
browser_cache=""
if [ -d "$HOME/.cache/ms-playwright" ]; then
    browser_cache=$(find "$HOME/.cache/ms-playwright" -mindepth 1 -maxdepth 1 \
        -type d \( -name 'chromium-*' -o -name 'chromium_headless_shell-*' \) \
        -print -quit 2>/dev/null || true)
fi
printf '%-22s %s\n' "Browser cache" "${browser_cache:-<missing>}"

case "$environment_layer" in
    termux)
        section "Termux host packages"
        for package in termux-x11-nightly proot-distro pulseaudio; do
            value_or_missing "$package" package_version "$package"
        done
        value_or_missing "xfce (optional)" package_version xfce
        ;;
    proot)
        section "PRoot guest packages"
        for package in libgtk-3-0t64 libnss3 libgbm1; do
            value_or_missing "$package" package_version "$package"
        done
        printf '%-22s %s\n' "Termux package check" "run doctor from the Termux host"
        ;;
    *)
        section "Linux desktop packages"
        for package in xfce4 xfce4-session dbus-x11; do
            value_or_missing "$package" package_version "$package"
        done
        ;;
esac

section "Hermes checkout"
if hermes_root=$(find_hermes_root); then
    printf '%-22s %s\n' "Root" "$hermes_root"
    value_or_missing "Commit" git -C "$hermes_root" rev-parse HEAD
    value_or_missing "Branch" git -C "$hermes_root" branch --show-current
    value_or_missing "Dirty files" git -C "$hermes_root" status --short

    source_index="$hermes_root/apps/desktop/dist/index.html"
    if [ -f "$source_index" ]; then
        printf '%-22s %s\n' "Desktop source build" "$source_index"
    else
        printf '%-22s %s\n' "Desktop source build" "<missing>"
    fi

    workspace_electron=""
    for electron_candidate in \
        "$hermes_root/node_modules/electron/dist/electron" \
        "$hermes_root/apps/desktop/node_modules/electron/dist/electron"; do
        if [ -f "$electron_candidate" ]; then
            workspace_electron="$electron_candidate"
            break
        fi
    done
    printf '%-22s %s\n' "Workspace Electron" "${workspace_electron:-<missing>}"

    release_dir="$hermes_root/apps/desktop/release"
    packaged_artifact=""
    if [ -d "$release_dir" ]; then
        packaged_artifact=$(find "$release_dir" -maxdepth 3 -type f \
            \( -name Hermes -o -name hermes -o -name electron \) \
            -print -quit 2>/dev/null || true)
    fi
    printf '%-22s %s\n' "Desktop package build" "${packaged_artifact:-<missing>}"
else
    printf '%-22s %s\n' "Root" "<not found>"
fi

section "Processes"
if command -v pgrep >/dev/null 2>&1; then
    found_process=false
    for pattern in termux-x11 xfce4-session Hermes electron chromium; do
        matching_pids=$(pgrep -f "$pattern" 2>/dev/null || true)
        for pid in $matching_pids; do
            [ -n "$pid" ] || continue
            [ "$pid" = "$$" ] && continue
            if [ -r "/proc/$pid/comm" ]; then
                process_name=$(cat "/proc/$pid/comm" 2>/dev/null | tr -d '\n')
                [ -n "$process_name" ] || continue
                case "$process_name" in
                    bash|pgrep|codex*|bwrap) continue ;;
                esac
                printf '%-8s %s\n' "$pid" "$process_name"
                found_process=true
            fi
        done
    done
    if [ "$found_process" = false ]; then
        printf '<none found>\n'
    fi
else
    printf '<pgrep missing>\n'
fi

section "Notes"
printf '%s\n' "This report intentionally omits Hermes .env files, API keys, auth files, sessions, and chat data."
