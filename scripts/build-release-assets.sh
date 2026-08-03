#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
out_dir="${1:-$repo_root/dist}"

if ! git -C "$repo_root" diff --quiet HEAD --; then
    printf 'Refusing to build release assets from a dirty worktree.\n' >&2
    exit 1
fi

version=$(tr -d '\n' <"$repo_root/VERSION")
tag="v$version"
head_ref=$(git -C "$repo_root" rev-parse HEAD)
release_ref="${HERMES_ANDROID_RELEASE_REF:-$head_ref}"

case "$version" in
    ''|*[!0-9.]*)
        printf 'Invalid VERSION value: %s\n' "$version" >&2
        exit 1
        ;;
esac
case "$release_ref" in
    *[!0-9a-fA-F]*|'')
        printf 'Release ref must be a 40-character commit SHA: %s\n' "$release_ref" >&2
        exit 1
        ;;
esac
if [ "${#release_ref}" -ne 40 ]; then
    printf 'Release ref must be a 40-character commit SHA: %s\n' "$release_ref" >&2
    exit 1
fi
release_ref=$(printf '%s' "$release_ref" | tr 'A-F' 'a-f')
if [ "$release_ref" != "$head_ref" ]; then
    printf 'Release ref must match the clean source HEAD: %s\n' "$head_ref" >&2
    exit 1
fi

for installer in install-termux.sh install-ubuntu.sh install-launchers.sh; do
    grep -Fq "repo_ref=\"\${HERMES_ANDROID_REPO_REF:-$tag}\"" \
        "$repo_root/scripts/$installer" || {
        printf '%s does not default to release tag %s\n' "$installer" "$tag" >&2
        exit 1
    }
done

mkdir -p "$out_dir"
for asset in install-termux.sh install-launchers.sh; do
    sed \
        "s|repo_ref=\"\${HERMES_ANDROID_REPO_REF:-$tag}\"|repo_ref=\"\${HERMES_ANDROID_REPO_REF:-$release_ref}\"|" \
        "$repo_root/scripts/$asset" >"$out_dir/$asset"
    chmod 0755 "$out_dir/$asset"
done
install -m 0755 "$repo_root/scripts/doctor.sh" "$out_dir/doctor.sh"

for asset in install-termux.sh install-launchers.sh doctor.sh; do
    (
        cd "$out_dir"
        sha256sum "$asset" >"$asset.sha256"
    )
done

printf 'Built %s release assets pinned to %s in %s\n' \
    "$tag" "$release_ref" "$out_dir"
