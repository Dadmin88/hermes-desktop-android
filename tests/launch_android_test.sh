#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
launcher="$repo_root/scripts/launch-android.sh"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

output=$(HERMES_ANDROID_TEST_LAYER=termux bash "$launcher" --dry-run 2>&1) \
    || fail 'Android launcher dry run exits successfully'

for expected in \
    'pulseaudio --start --exit-idle-time=-1' \
    'pactl load-module module-native-protocol-tcp listen=127.0.0.1 auth-anonymous=1' \
    'termux-x11 :1 -dpi 120' \
    'env DISPLAY=:1 dbus-launch --exit-with-session xfce4-session' \
    'am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity' \
    'proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 PULSE_SERVER=127.0.0.1 hermes-android-session'; do
    printf '%s\n' "$output" | grep -Fq -- "$expected" \
        || fail "Android launcher includes: $expected"
done

printf 'ok - Android launcher starts Termux Xfce and crosses into Ubuntu explicitly\n'

fake_bin=$(mktemp -d)
call_log=$(mktemp)
trap 'rm -rf "$fake_bin"; rm -f "$call_log"' EXIT HUP INT TERM

for command_name in pulseaudio pactl am sleep; do
    cat >"$fake_bin/$command_name" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$fake_bin/$command_name"
done

cat >"$fake_bin/pgrep" <<'EOF'
#!/usr/bin/env bash
case "$*" in
    *termux-x11*) exit 0 ;;
    *) exit 1 ;;
esac
EOF
chmod +x "$fake_bin/pgrep"

cat >"$fake_bin/proot-distro" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$call_log"
EOF
chmod +x "$fake_bin/proot-distro"

if ! PATH="$fake_bin:/usr/bin:/bin" HERMES_ANDROID_TEST_LAYER=termux \
    bash "$launcher" >/dev/null 2>&1; then
    fail 'Android launcher proceeds without Xfce when Xfce is not installed'
fi

grep -Fq -- 'login ubuntu --shared-tmp -- env DISPLAY=:1 PULSE_SERVER=127.0.0.1 hermes-android-session' \
    "$call_log" || fail 'Android launcher enters Ubuntu directly when Xfce is unavailable'

printf 'ok - Android launcher does not require Xfce for direct Electron mode\n'
