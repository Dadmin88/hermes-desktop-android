#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
installer="$repo_root/scripts/install-termux.sh"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

output=$(HERMES_ANDROID_TEST_LAYER=termux bash "$installer" --dry-run 2>&1) \
    || fail 'Termux installer dry run exits successfully'

for expected in \
    'pkg install -y x11-repo' \
    'pkg install -y termux-x11-nightly proot-distro pulseaudio curl' \
    'proot-distro install ubuntu' \
    'proot-distro login ubuntu --shared-tmp'; do
    printf '%s\n' "$output" | grep -Fq "$expected" \
        || fail "Termux installer includes: $expected"
done

printf 'ok - Termux installer preserves the verified host/guest boundary\n'

if printf '%s\n' "$output" | grep -Eq 'pkg install .*xfce'; then
    fail 'Termux installer does not require Xfce for the verified direct mode'
fi

printf 'ok - Termux installer keeps Xfce optional\n'
