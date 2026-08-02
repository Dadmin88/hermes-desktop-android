#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
launcher="$repo_root/scripts/launch-android.sh"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

output=$(HERMES_ANDROID_TEST_LAYER=termux bash "$launcher" --dry-run 2>&1) \
    || fail 'Android launcher dry run exits successfully'

for expected in \
    'pulseaudio --start --exit-idle-time=-1' \
    'pactl load-module module-native-protocol-tcp listen=127.0.0.1 auth-anonymous=1' \
    'termux-x11 :1 -dpi 120' \
    'env DISPLAY=:1 dbus-launch --exit-with-session xfce4-session' \
    'am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity' \
    'proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 PULSE_SERVER=127.0.0.1 hermes-android-session'; do
    printf '%s\n' "$output" | grep -Fq -- "$expected" \
        || fail "Android launcher includes: $expected"
done

printf 'ok - Android launcher starts Termux Xfce and crosses into Ubuntu explicitly\n'
