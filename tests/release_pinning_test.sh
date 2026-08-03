#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
version=$(tr -d '\n' <"$repo_root/VERSION")
tag="v$version"

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
build_repo=$(mktemp -d)
trap 'rm -rf "$fixture" "$second_fixture" "$build_repo"' EXIT HUP INT TERM

cp -a "$repo_root/." "$build_repo"
rm -rf "$build_repo/.git"
git -C "$build_repo" init -q
git -C "$build_repo" config user.email test@example.invalid
git -C "$build_repo" config user.name 'Release asset test'
git -C "$build_repo" add .
git -C "$build_repo" commit -qm 'Clean release source fixture'
release_ref=$(git -C "$build_repo" rev-parse HEAD)

printf '\n' >>"$build_repo/README.md"
if "$build_repo/scripts/build-release-assets.sh" "$fixture" \
    >"$build_repo/dirty-build-output" 2>&1; then
    fail 'release builder must reject a dirty tracked worktree'
fi
grep -Fq 'Refusing to build release assets from a dirty worktree' \
    "$build_repo/dirty-build-output" \
    || fail 'release builder explains the dirty-worktree refusal'
git -C "$build_repo" checkout -q -- README.md
rm -f "$build_repo/dirty-build-output"
printf 'ok - release builder rejects dirty tracked source\n'

mismatched_ref=0000000000000000000000000000000000000000
if HERMES_ANDROID_RELEASE_REF="$mismatched_ref" \
    "$build_repo/scripts/build-release-assets.sh" "$fixture" \
    >"$build_repo/mismatched-ref-output" 2>&1; then
    fail 'release builder must reject a pin that differs from source HEAD'
fi
grep -Fq 'Release ref must match the clean source HEAD' \
    "$build_repo/mismatched-ref-output" \
    || fail 'release builder explains the mismatched-ref refusal'
rm -f "$build_repo/mismatched-ref-output"
printf 'ok - release builder pins the exact clean source commit\n'

"$build_repo/scripts/build-release-assets.sh" "$fixture" >/dev/null
"$build_repo/scripts/build-release-assets.sh" "$second_fixture" >/dev/null

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
git -C "$build_repo" show "$release_ref:scripts/install-ubuntu.sh" \
    | grep -Fq 'libnspr4 libnss3 libgl1' \
    || fail 'pinned release commit contains the Electron runtime dependencies'
cmp -s "$build_repo/scripts/doctor.sh" "$fixture/doctor.sh" \
    || fail 'doctor release asset matches the tracked script'
printf 'ok - release assets are checksummed, deterministic, and commit-pinned\n'

rm -rf "$fixture" "$second_fixture" "$build_repo"
trap - EXIT HUP INT TERM
