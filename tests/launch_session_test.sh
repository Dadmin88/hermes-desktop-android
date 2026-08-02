#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
launcher="$repo_root/scripts/launch-session.sh"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

output=$(HERMES_ANDROID_TEST_LAYER=proot bash "$launcher" --dry-run 2>&1) \
    || fail 'Ubuntu session launcher dry run exits successfully'

for expected in \
    'DISPLAY=:1' \
    'PULSE_SERVER=127.0.0.1' \
    'hermes-android-desktop'; do
    printf '%s\n' "$output" | grep -Fq -- "$expected" \
        || fail "Ubuntu session launcher includes: $expected"
done


if printf '%s\n' "$output" | grep -Eq 'startxfce4|xfce4-session'; then
    fail 'Ubuntu session must reuse the Termux-native Xfce session'
fi

printf 'ok - Ubuntu session launcher reuses the Termux-native Xfce desktop\n'
