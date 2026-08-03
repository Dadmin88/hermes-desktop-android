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
    'am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity' \
    'env DISPLAY=:1 xfwm4 --replace' \
    'proot-distro login ubuntu --shared-tmp -- env DISPLAY=:1 PULSE_SERVER=127.0.0.1 hermes-android-session'; do
    printf '%s\n' "$output" | grep -Fq -- "$expected" \
        || fail "Android launcher includes: $expected"
done

if printf '%s\n' "$output" | grep -Fq -- '--daemon'; then
    fail 'Android launcher does not pass unsupported --daemon to xfwm4'
fi

printf 'ok - Android launcher starts X11 and enters Ubuntu directly\n'

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

cat >"$fake_bin/xfwm4" <<EOF
#!/usr/bin/env bash
case " $* " in
    *' --daemon '*)
        printf 'xfwm4: Unknown option --daemon.\n' >&2
        exit 2
        ;;
esac
printf 'xfwm4 %s\n' "\$*" >>"$call_log"
/bin/sleep 5
EOF
chmod +x "$fake_bin/xfwm4"

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

if ! timeout 2 env PATH="$fake_bin:/usr/bin:/bin" HERMES_ANDROID_TEST_LAYER=termux \
    bash "$launcher" >/dev/null 2>&1; then
    fail 'Android launcher proceeds with the standalone window manager'
fi

attempt=0
while ! grep -Fq -- 'xfwm4 --replace' "$call_log" && [ "$attempt" -lt 50 ]; do
    attempt=$((attempt + 1))
    sleep 0.02
done

grep -Fq -- 'xfwm4 --replace' "$call_log" \
    || fail 'Android launcher starts xfwm4 so Electron windows can maximize and resize'

if grep -Fq -- '--daemon' "$call_log"; then
    fail 'Android launcher never invokes xfwm4 with unsupported --daemon'
fi

grep -Fq -- 'login ubuntu --shared-tmp -- env DISPLAY=:1 PULSE_SERVER=127.0.0.1 hermes-android-session' \
    "$call_log" || fail 'Android launcher enters Ubuntu directly when Xfce is unavailable'

printf 'ok - Android launcher starts a standalone window manager for Electron\n'

cat >"$fake_bin/xfce4-session" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$fake_bin/xfce4-session"

if ! PATH="$fake_bin:/usr/bin:/bin" HERMES_ANDROID_TEST_LAYER=termux \
    bash "$launcher" >/dev/null 2>&1; then
    fail 'Android launcher remains in direct mode when optional Xfce is installed'
fi

grep -Fq -- 'login ubuntu --shared-tmp -- env DISPLAY=:1 PULSE_SERVER=127.0.0.1 hermes-android-session' \
    "$call_log" || fail 'Android launcher enters Ubuntu when optional Xfce is installed'

printf 'ok - Optional Xfce installation cannot block direct Electron mode\n'
