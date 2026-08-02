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
value_or_missing "Node" node --version
value_or_missing "npm" npm --version
value_or_missing "Git" git --version
value_or_missing "Hermes command" command_path hermes
value_or_missing "Hermes version" hermes version
value_or_missing "Electron command" command_path electron
value_or_missing "Chromium command" command_path chromium
value_or_missing "Chrome command" command_path google-chrome

section "Termux and X11 packages"
for package in termux-x11-nightly proot-distro xfce4 xfce4-session pulseaudio; do
    value_or_missing "$package" package_version "$package"
done

section "Hermes checkout"
if hermes_root=$(find_hermes_root); then
    printf '%-22s %s\n' "Root" "$hermes_root"
    value_or_missing "Commit" git -C "$hermes_root" rev-parse HEAD
    value_or_missing "Branch" git -C "$hermes_root" branch --show-current
    value_or_missing "Dirty files" git -C "$hermes_root" status --short

    release_dir="$hermes_root/apps/desktop/release"
    if [ -d "$release_dir" ]; then
        printf '%-22s\n' "Desktop artifacts"
        find "$release_dir" -maxdepth 2 -type f \( -name Hermes -o -name hermes -o -name electron \) -print 2>/dev/null
    else
        printf '%-22s %s\n' "Desktop artifacts" "<missing>"
    fi
else
    printf '%-22s %s\n' "Root" "<not found>"
fi

section "Processes"
if command -v pgrep >/dev/null 2>&1; then
    found_process=false
    for pattern in termux-x11 xfce4-session Hermes electron chromium; do
        while IFS= read -r pid; do
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
        done < <(pgrep -f "$pattern" 2>/dev/null || true)
    done
    if [ "$found_process" = false ]; then
        printf '<none found>\n'
    fi
else
    printf '<pgrep missing>\n'
fi

section "Notes"
printf '%s\n' "This report intentionally omits Hermes .env files, API keys, auth files, sessions, and chat data."
