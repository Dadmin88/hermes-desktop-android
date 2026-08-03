#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

test_termux_download_failure_preserves_existing_launcher() {
    fixture=$(mktemp -d)
    trap 'rm -rf "$fixture"' EXIT HUP INT TERM
    fake_bin="$fixture/bin"
    prefix="$fixture/prefix"
    mkdir -p "$fake_bin" "$prefix/bin"
    printf 'known-good-launcher\n' >"$prefix/bin/hermes-android"

    cat >"$fake_bin/pkg" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    cat >"$fake_bin/proot-distro" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    cat >"$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
set -eu
output=''
while [ "$#" -gt 0 ]; do
    if [ "$1" = '-o' ]; then
        shift
        output="$1"
    fi
    shift
done
[ -z "$output" ] || printf 'partial-download\n' >"$output"
exit 22
EOF
    chmod +x "$fake_bin/pkg" "$fake_bin/proot-distro" "$fake_bin/curl"

    if PATH="$fake_bin:$PATH" PREFIX="$prefix" HERMES_ANDROID_TEST_LAYER=termux \
        bash "$repo_root/scripts/install-termux.sh" >/dev/null 2>&1; then
        fail 'Termux installer must fail when a launcher download fails'
    fi
    grep -Fqx -- 'known-good-launcher' "$prefix/bin/hermes-android" \
        || fail 'Termux installer preserves an existing launcher after download failure'

    rm -rf "$fixture"
    trap - EXIT HUP INT TERM
}

test_guest_install_failure_preserves_existing_launcher() {
    fixture=$(mktemp -d)
    trap 'rm -rf "$fixture"' EXIT HUP INT TERM
    fake_bin="$fixture/bin"
    prefix="$fixture/prefix"
    mkdir -p "$fake_bin" "$prefix/bin"
    printf 'known-good-launcher\n' >"$prefix/bin/hermes-android"

    cat >"$fake_bin/pkg" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    cat >"$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
set -eu
output=''
while [ "$#" -gt 0 ]; do
    if [ "$1" = '-o' ]; then
        shift
        output="$1"
    fi
    shift
done
printf '#!/usr/bin/env bash\nexit 0\n' >"$output"
EOF
    cat >"$fake_bin/proot-distro" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = 'install' ]; then
    exit 0
fi
exit 1
EOF
    chmod +x "$fake_bin/pkg" "$fake_bin/curl" "$fake_bin/proot-distro"

    if PATH="$fake_bin:$PATH" PREFIX="$prefix" HERMES_ANDROID_TEST_LAYER=termux \
        bash "$repo_root/scripts/install-termux.sh" >/dev/null 2>&1; then
        fail 'Termux installer must fail when the Ubuntu guest stage fails'
    fi
    grep -Fqx -- 'known-good-launcher' "$prefix/bin/hermes-android" \
        || fail 'Termux installer preserves host launchers after guest-stage failure'

    rm -rf "$fixture"
    trap - EXIT HUP INT TERM
}

test_upstream_download_failure_stops_before_build() {
    fixture=$(mktemp -d)
    trap 'rm -rf "$fixture"' EXIT HUP INT TERM
    fake_bin="$fixture/bin"
    marker="$fixture/hermes-called"
    mkdir -p "$fake_bin"

    cat >"$fake_bin/id" <<'EOF'
#!/usr/bin/env bash
printf '0\n'
EOF
    cat >"$fake_bin/apt-get" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    cat >"$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
exit 22
EOF
    cat >"$fake_bin/hermes" <<EOF
#!/usr/bin/env bash
touch "$marker"
exit 1
EOF
    chmod +x "$fake_bin/id" "$fake_bin/apt-get" "$fake_bin/curl" "$fake_bin/hermes"

    if PATH="$fake_bin:$PATH" HERMES_ANDROID_TEST_LAYER=proot \
        HERMES_INSTALL_DIR="$fixture/hermes-root" \
        bash "$repo_root/scripts/install-ubuntu.sh" >/dev/null 2>&1; then
        fail 'Ubuntu installer must fail when the upstream installer download fails'
    fi
    [ ! -e "$marker" ] \
        || fail 'Ubuntu installer must not build after an upstream download failure'

    rm -rf "$fixture"
    trap - EXIT HUP INT TERM
}

test_termux_download_failure_preserves_existing_launcher
printf 'ok - failed Termux downloads preserve installed launchers\n'
test_guest_install_failure_preserves_existing_launcher
printf 'ok - failed guest installs preserve installed host launchers\n'
test_upstream_download_failure_stops_before_build
printf 'ok - failed upstream downloads stop before the Hermes build\n'
