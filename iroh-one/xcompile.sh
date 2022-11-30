#!/bin/bash

set -e

source utils.sh
FEATURES=http-uds-gateway
STRIP=
OPT=
BUILD_TYPE=debug
while [[ $# -gt 0 ]]; do
    case "$1" in
    --release)
        OPT="$OPT --release"
        BUILD_TYPE=release
        ;;
    --strip)
        STRIP=yes
        ;;
    esac
    shift
done

echo "Doing a ${BUILD_TYPE} iroh-one build"

setup_xcompile_envs
xcompile
binary=../target/${TARGET_ARCH}/${BUILD_TYPE}/iroh-one

if [ "${STRIP}" = "yes" ]; then
    xstrip ${binary}
fi
