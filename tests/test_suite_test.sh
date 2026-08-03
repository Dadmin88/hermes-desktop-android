#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
runner="$repo_root/tests/run.sh"

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/scripts" "$fixture/tests"
cp "$runner" "$fixture/tests/run.sh"

for script_name in \
    doctor.sh \
    launch-desktop.sh; do
    printf '#!/usr/bin/env bash\nexit 0\n' > "$fixture/scripts/$script_name"
done

for test_name in \
    doctor_test.sh \
    launch_desktop_test.sh \
    install_termux_test.sh \
    install_ubuntu_test.sh \
    install_launchers_test.sh \
    enter_ubuntu_test.sh \
    launch_android_test.sh \
    launch_session_test.sh \
    test_suite_test.sh; do
    printf '#!/usr/bin/env bash\nexit 0\n' > "$fixture/tests/$test_name"
done

printf '#!/usr/bin/env bash\nif then\n' > "$fixture/scripts/broken.sh"

if bash "$fixture/tests/run.sh" >/dev/null 2>&1; then
    fail 'test runner must reject a syntax error in any project shell script'
fi

printf 'ok - test runner syntax-checks every project shell script\n'
