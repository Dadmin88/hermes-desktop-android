#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
version=$(tr -d '\n' <"$repo_root/VERSION")
tag="v$version"
release_ref=$(git -C "$repo_root" rev-parse HEAD)

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

for installer in install-termux.sh install-ubuntu.sh install-launchers.sh; do
    grep -Fq "repo_ref=\"\${HERMES_ANDROID_REPO_REF:-$tag}\"" \
        "$repo_root/scripts/$installer" \
        || fail "$installer defaults to the release tag"
done
printf 'ok - tracked installers default to the versioned project release\n'

if grep -R -n -E \
    'raw\.githubusercontent\.com/Dadmin88/hermes-desktop-android/main/' \
    "$repo_root/README.md" "$repo_root/docs" "$repo_root/scripts"; then
    fail 'public install paths must not fetch mutable main'
fi
printf 'ok - public install paths avoid mutable main\n'

if grep -R -n -E \
    'raw\.githubusercontent\.com/Dadmin88/hermes-desktop-android/' \
    "$repo_root/README.md" "$repo_root/docs"; then
    fail 'public documentation must use checksummed release assets'
fi
printf 'ok - documented project downloads use release assets\n'

if grep -R -n -E '\|[[:space:]]*bash' \
    "$repo_root/README.md" "$repo_root/docs"; then
    fail 'public documentation must not pipe downloads directly into bash'
fi
printf 'ok - public downloads are staged before execution\n'

fixture=$(mktemp -d)
second_fixture=$(mktemp -d)
trap 'rm -rf "$fixture" "$second_fixture"' EXIT HUP INT TERM
"$repo_root/scripts/build-release-assets.sh" "$fixture" >/dev/null
"$repo_root/scripts/build-release-assets.sh" "$second_fixture" >/dev/null

for asset in install-termux.sh install-launchers.sh doctor.sh; do
    (
        cd "$fixture"
        sha256sum --check "$asset.sha256" >/dev/null
    ) || fail "$asset release checksum verifies"
    cmp -s "$fixture/$asset" "$second_fixture/$asset" \
        || fail "$asset release build is deterministic"
    cmp -s "$fixture/$asset.sha256" "$second_fixture/$asset.sha256" \
        || fail "$asset checksum build is deterministic"
    bash -n "$fixture/$asset" || fail "$asset release asset has valid syntax"
done

for installer in install-termux.sh install-launchers.sh; do
    grep -Fq "repo_ref=\"\${HERMES_ANDROID_REPO_REF:-$release_ref}\"" \
        "$fixture/$installer" \
        || fail "$installer release asset pins nested downloads to the commit SHA"
done
cmp -s "$repo_root/scripts/doctor.sh" "$fixture/doctor.sh" \
    || fail 'doctor release asset matches the tracked script'
printf 'ok - release assets are checksummed, deterministic, and commit-pinned\n'

rm -rf "$fixture" "$second_fixture"
trap - EXIT HUP INT TERM
