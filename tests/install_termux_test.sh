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
    'pkg install -y termux-x11-nightly proot-distro pulseaudio curl xfwm4' \
    'proot-distro install ubuntu' \
    '/bin/hermes-ubuntu' \
    'proot-distro login ubuntu --shared-tmp'; do
    printf '%s\n' "$output" | grep -Fq "$expected" \
        || fail "Termux installer includes: $expected"
done

printf 'ok - Termux installer preserves the verified host/guest boundary\n'

if printf '%s\n' "$output" | grep -Eq 'pkg install .*xfce([^[:alnum:]]|$)'; then
    fail 'Termux installer does not require the full Xfce desktop'
fi

printf 'ok - Termux installer installs only the standalone window manager\n'
