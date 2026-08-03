#!/usr/bin/env bash

set -eu

if [ "${HERMES_ANDROID_TEST_LAYER:-}" != "termux" ] \
    && [ "${PREFIX:-}" != "/data/data/com.termux/files/usr" ]; then
    printf 'Run hermes-ubuntu from the Termux host shell.\n' >&2
    exit 1
fi

exec proot-distro login ubuntu --shared-tmp
