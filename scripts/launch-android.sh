#!/usr/bin/env bash

set -eu

dry_run=false
display="${HERMES_X11_DISPLAY:-:1}"
dpi="${HERMES_X11_DPI:-120}"
x11_extra_args="${HERMES_X11_EXTRA_ARGS:-}"

usage() {
    cat <<'EOF'
Usage: hermes-android [--dry-run]

Start the Termux audio and X11 services, open the Termux:X11 Android activity,
then enter the Ubuntu PRoot guest and launch Hermes Desktop.

Environment overrides:
  HERMES_X11_DISPLAY=:1
  HERMES_X11_DPI=120
  HERMES_X11_EXTRA_ARGS=-legacy-drawing
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

case "$display" in :[0-9]*) ;; *) printf 'Invalid X11 display: %s\n' "$display" >&2; exit 2 ;; esac
case "$dpi" in ''|*[!0-9]*) printf 'Invalid X11 DPI: %s\n' "$dpi" >&2; exit 2 ;; esac

if [ "$dry_run" = true ]; then
    printf 'pulseaudio --start --exit-idle-time=-1\n'
    printf 'pactl load-module module-native-protocol-tcp listen=127.0.0.1 auth-anonymous=1\n'
    printf 'termux-x11 %s -dpi %s%s%s\n' \
        "$display" "$dpi" "${x11_extra_args:+ }" "$x11_extra_args"
    printf 'am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity\n'
    printf 'env DISPLAY=%s xfwm4 --replace --daemon\n' "$display"
    printf 'proot-distro login ubuntu --shared-tmp -- env DISPLAY=%s PULSE_SERVER=127.0.0.1 hermes-android-session\n' \
        "$display"
    exit 0
fi

if [ "${HERMES_ANDROID_TEST_LAYER:-}" != "termux" ] \
    && [ "${PREFIX:-}" != "/data/data/com.termux/files/usr" ]; then
    printf 'Run hermes-android from the Termux host shell, not inside Ubuntu.\n' >&2
    exit 1
fi

if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock >/dev/null 2>&1 || true
fi

pulseaudio --start --exit-idle-time=-1 >/dev/null 2>&1 || true
if command -v pactl >/dev/null 2>&1 \
    && ! pactl list short modules 2>/dev/null | grep -q 'module-native-protocol-tcp'; then
    pactl load-module module-native-protocol-tcp \
        listen=127.0.0.1 auth-anonymous=1 >/dev/null
fi

if ! pgrep -x termux-x11 >/dev/null 2>&1; then
    # Extra arguments are intentionally word-split so users can pass multiple
    # documented Termux:X11 flags such as "-legacy-drawing -force-bgra".
    # shellcheck disable=SC2086
    termux-x11 "$display" -dpi "$dpi" $x11_extra_args \
        >"${TMPDIR:-/tmp}/hermes-termux-x11.log" 2>&1 &
    sleep 2
fi

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity \
    >/dev/null 2>&1 || true

if command -v xfwm4 >/dev/null 2>&1 \
    && ! pgrep -x xfwm4 >/dev/null 2>&1; then
    env DISPLAY="$display" xfwm4 --replace --daemon \
        >"${TMPDIR:-/tmp}/hermes-termux-xfwm4.log" 2>&1
fi

printf 'Launching Hermes in Termux:X11 with standalone window management.\n'

exec proot-distro login ubuntu --shared-tmp -- \
    env DISPLAY="$display" PULSE_SERVER=127.0.0.1 \
    hermes-android-session
