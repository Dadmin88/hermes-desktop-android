#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
installer="$repo_root/scripts/install-ubuntu.sh"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

output=$(HERMES_ANDROID_TEST_LAYER=proot bash "$installer" --dry-run 2>&1) \
    || fail 'Ubuntu installer dry run exits successfully'

for expected in \
    'apt-get install -y ca-certificates curl git build-essential xz-utils procps libnspr4 libnss3 libgl1' \
    'c2ff2e8b17f5dd0460aa020aaa21deb59d7fe15f/scripts/install.sh' \
    '--skip-setup --commit c2ff2e8b17f5dd0460aa020aaa21deb59d7fe15f --force-commit' \
    'hermes desktop --source --build-only --force-build --hermes-root /usr/local/lib/hermes-agent' \
    'hermes-desktop-android/v0.1.1/' \
    '/usr/local/bin/hermes-android-desktop' \
    '/usr/local/bin/hermes-android-session'; do
    printf '%s\n' "$output" | grep -Fq -- "$expected" \
        || fail "Ubuntu installer includes: $expected"
done

if printf '%s\n' "$output" | grep -Eq 'apt-get install.*xfce'; then
    fail 'Ubuntu installer must not duplicate the Termux-native Xfce desktop'
fi

printf 'ok - Ubuntu installer pins and builds the verified Hermes source mode\n'

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
git -C "$fixture" init -q
git -C "$fixture" config user.email test@example.invalid
git -C "$fixture" config user.name 'Installer test'
: > "$fixture/unrelated"
git -C "$fixture" add unrelated
git -C "$fixture" commit -qm 'Existing unrelated checkout'

if HERMES_INSTALL_DIR="$fixture" HERMES_ANDROID_TEST_LAYER=proot \
    bash "$installer" --dry-run >"$fixture/output" 2>&1; then
    fail 'Ubuntu installer must not force-pin an existing different checkout'
fi
grep -Fq 'Refusing to replace existing Hermes checkout' "$fixture/output" \
    || fail 'Ubuntu installer explains how it protects an existing checkout'

rm -rf "$fixture"
trap - EXIT HUP INT TERM
printf 'ok - Ubuntu installer protects existing Hermes checkouts\n'
