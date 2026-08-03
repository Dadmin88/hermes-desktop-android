#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
installer="$repo_root/scripts/install-launchers.sh"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

output=$(HERMES_ANDROID_TEST_LAYER=termux bash "$installer" --dry-run 2>&1) \
    || fail 'launcher-only installer dry run exits successfully'

for expected in \
    'hermes-desktop-android/v0.1.1/' \
    '/bin/hermes-android' \
    '/bin/hermes-ubuntu' \
    'proot-distro login ubuntu --shared-tmp' \
    '/usr/local/bin/hermes-android-desktop' \
    '/usr/local/bin/hermes-android-session'; do
    printf '%s\n' "$output" | grep -Fq -- "$expected" \
        || fail "launcher-only installer includes: $expected"
done

if printf '%s\n' "$output" | grep -Eq 'pkg install|apt-get|hermes desktop --source'; then
    fail 'launcher-only installer must not reinstall packages or rebuild Hermes'
fi

printf 'ok - launcher-only installer leaves the working Hermes stack untouched\n'
