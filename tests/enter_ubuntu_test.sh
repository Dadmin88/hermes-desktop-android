#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
helper="$repo_root/scripts/enter-ubuntu.sh"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
call_log="$fixture/calls.log"

cat >"$fixture/proot-distro" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >"$call_log"
EOF
chmod +x "$fixture/proot-distro"

PATH="$fixture:/usr/bin:/bin" HERMES_ANDROID_TEST_LAYER=termux \
    bash "$helper" || fail 'Ubuntu helper exits successfully'

grep -Fxq -- 'login ubuntu --shared-tmp' "$call_log" \
    || fail 'Ubuntu helper enters the guest with shared temporary storage'

printf 'ok - hermes-ubuntu enters the Ubuntu guest with shared temporary storage\n'
