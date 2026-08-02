#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

bash -n "$repo_root/scripts/doctor.sh"
bash -n "$repo_root/scripts/launch-desktop.sh" 2>/dev/null || true
bash "$repo_root/tests/doctor_test.sh"
bash "$repo_root/tests/launch_desktop_test.sh"
bash "$repo_root/tests/install_termux_test.sh"
bash "$repo_root/tests/install_ubuntu_test.sh"
bash "$repo_root/tests/install_launchers_test.sh"
bash "$repo_root/tests/launch_android_test.sh"
bash "$repo_root/tests/launch_session_test.sh"
