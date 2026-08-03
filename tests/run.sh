#!/usr/bin/env bash

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

for shell_file in "$repo_root"/scripts/*.sh "$repo_root"/tests/*.sh; do
    bash -n "$shell_file"
done

bash "$repo_root/tests/doctor_test.sh"
bash "$repo_root/tests/launch_desktop_test.sh"
bash "$repo_root/tests/install_termux_test.sh"
bash "$repo_root/tests/install_ubuntu_test.sh"
bash "$repo_root/tests/install_launchers_test.sh"
bash "$repo_root/tests/install_download_safety_test.sh"
bash "$repo_root/tests/release_pinning_test.sh"
bash "$repo_root/tests/enter_ubuntu_test.sh"
bash "$repo_root/tests/launch_android_test.sh"
bash "$repo_root/tests/launch_session_test.sh"
bash "$repo_root/tests/test_suite_test.sh"
