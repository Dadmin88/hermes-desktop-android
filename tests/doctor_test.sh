#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
doctor="$repo_root/scripts/doctor.sh"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

test_proot_report_does_not_claim_termux_packages_are_missing() {
    output=$(HERMES_DOCTOR_LAYER_OVERRIDE=proot bash "$doctor" 2>&1)

    printf '%s\n' "$output" | grep -Fq 'Environment layer      PRoot Linux guest' \
        || fail 'doctor identifies a PRoot Linux guest'
    printf '%s\n' "$output" | grep -Fq 'Termux package check   run doctor from the Termux host' \
        || fail 'doctor defers Termux package inspection to the Termux host'
    if printf '%s\n' "$output" | grep -Eq '^termux-x11-nightly[[:space:]]+<missing>$'; then
        fail 'doctor must not report host-only Termux packages as missing from PRoot'
    fi
    if printf '%s\n' "$output" | grep -Eq '^xfce4(-session)?[[:space:]]+'; then
        fail 'doctor must not look for the Termux-native Xfce desktop inside PRoot'
    fi
    printf '%s\n' "$output" | grep -Eq '^libgtk-3-0t64[[:space:]]+' \
        || fail 'doctor checks the Ubuntu 24.04 GTK runtime package'

    printf 'ok - PRoot report keeps host and guest package checks separate\n'
}

test_process_scan_avoids_process_substitution() {
    if grep -Fq '< <(' "$doctor"; then
        fail 'doctor process scan must work when /dev/fd is unavailable'
    fi

    printf 'ok - process scan does not depend on /dev/fd\n'
}

test_source_mode_artifacts_are_detected() {
    fixture=$(mktemp -d)
    trap 'rm -rf "$fixture"' EXIT HUP INT TERM
    mkdir -p \
        "$fixture/.git" \
        "$fixture/apps/desktop/dist" \
        "$fixture/node_modules/electron/dist"
    : > "$fixture/apps/desktop/dist/index.html"
    : > "$fixture/node_modules/electron/dist/electron"

    output=$(
        HERMES_DOCTOR_LAYER_OVERRIDE=proot \
        HERMES_DESKTOP_HERMES_ROOT="$fixture" \
        bash "$doctor" 2>&1
    )

    printf '%s\n' "$output" | grep -Fq "Desktop source build   $fixture/apps/desktop/dist/index.html" \
        || fail 'doctor detects the source-mode renderer build'
    printf '%s\n' "$output" | grep -Fq "Workspace Electron     $fixture/node_modules/electron/dist/electron" \
        || fail 'doctor detects the workspace Electron runtime'

    rm -rf "$fixture"
    trap - EXIT HUP INT TERM
    printf 'ok - source-mode Hermes Desktop artifacts are detected\n'
}

test_termux_report_checks_native_xfce() {
    output=$(HERMES_DOCTOR_LAYER_OVERRIDE=termux bash "$doctor" 2>&1)

    printf '%s\n' "$output" | grep -Eq '^xfce[[:space:]]+' \
        || fail 'doctor checks the Termux-native Xfce package'

    printf 'ok - Termux report checks the native Xfce desktop\n'
}

test_runtime_reports_python3_command() {
    output=$(HERMES_DOCTOR_LAYER_OVERRIDE=proot bash "$doctor" 2>&1)

    printf '%s\n' "$output" | grep -Eq '^Python 3[[:space:]]+' \
        || fail 'doctor reports python3 separately from the optional python alias'

    printf 'ok - runtime report distinguishes python3 from python\n'
}

test_runtime_reports_playwright_browser_cache() {
    fixture=$(mktemp -d)
    trap 'rm -rf "$fixture"' EXIT HUP INT TERM
    mkdir -p "$fixture/.cache/ms-playwright/chromium-1234"

    output=$(HOME="$fixture" HERMES_DOCTOR_LAYER_OVERRIDE=proot bash "$doctor" 2>&1)

    printf '%s\n' "$output" | grep -Fq \
        "Browser cache          $fixture/.cache/ms-playwright/chromium-1234" \
        || fail 'doctor reports cached Playwright Chromium used by agent-browser'

    rm -rf "$fixture"
    trap - EXIT HUP INT TERM
    printf 'ok - runtime report detects cached headed-browser artifacts\n'
}

test_proot_report_does_not_claim_termux_packages_are_missing
test_process_scan_avoids_process_substitution
test_source_mode_artifacts_are_detected
test_termux_report_checks_native_xfce
test_runtime_reports_python3_command
test_runtime_reports_playwright_browser_cache
