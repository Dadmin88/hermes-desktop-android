#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
launcher="$repo_root/scripts/launch-desktop.sh"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

test_print_command_uses_source_build_and_workspace_electron() {
    fixture=$(mktemp -d)
    trap 'rm -rf "$fixture"' EXIT HUP INT TERM
    hermes_root="$fixture/hermes-agent"
    fake_bin="$fixture/bin"
    mkdir -p \
        "$fake_bin" \
        "$hermes_root/apps/desktop/dist" \
        "$hermes_root/node_modules/electron/dist"
    : > "$hermes_root/apps/desktop/dist/index.html"
    : > "$hermes_root/node_modules/electron/dist/electron"
    ln -s "$(command -v true)" "$fake_bin/hermes"

    output=$(
        PATH="$fake_bin:$PATH" \
        HERMES_DESKTOP_HERMES_ROOT="$hermes_root" \
        HERMES_ANDROID_SKIP_DISPLAY_CHECK=1 \
        bash "$launcher" --print-command
    )

    printf '%s\n' "$output" | grep -Fq \
        "$hermes_root/node_modules/electron/dist/electron --no-sandbox $hermes_root/apps/desktop" \
        || fail 'launcher prints the verified source-mode Electron command'

    rm -rf "$fixture"
    trap - EXIT HUP INT TERM
    printf 'ok - launcher targets the source build and workspace Electron\n'
}

test_print_command_uses_source_build_and_workspace_electron
