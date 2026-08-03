#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
launcher="$repo_root/scripts/launch-session.sh"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

output=$(env -u DISPLAY -u PULSE_SERVER \
    HERMES_ANDROID_TEST_LAYER=proot bash "$launcher" --dry-run 2>&1) \
    || fail 'Ubuntu session launcher dry run exits successfully'

for expected in \
    'DISPLAY=:1' \
    'PULSE_SERVER=127.0.0.1' \
    'hermes-android-desktop'; do
    printf '%s\n' "$output" | grep -Fq -- "$expected" \
        || fail "Ubuntu session launcher includes: $expected"
done

output=$(DISPLAY=:7 PULSE_SERVER=10.0.0.2 \
    HERMES_ANDROID_TEST_LAYER=proot bash "$launcher" --dry-run 2>&1) \
    || fail 'Ubuntu session launcher accepts explicit display and audio overrides'
printf '%s\n' "$output" | grep -Fq -- 'DISPLAY=:7' \
    || fail 'Ubuntu session launcher preserves an explicit DISPLAY override'
printf '%s\n' "$output" | grep -Fq -- 'PULSE_SERVER=10.0.0.2' \
    || fail 'Ubuntu session launcher preserves an explicit PULSE_SERVER override'


if printf '%s\n' "$output" | grep -Eq 'startxfce4|xfce4-session'; then
    fail 'Ubuntu session must not require a desktop shell'
fi

printf 'ok - Ubuntu session launcher works in direct-X11 mode\n'
