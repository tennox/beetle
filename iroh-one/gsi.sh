#!/bin/bash

set -e

export TARGET_ARCH=aarch64-linux-android
export BUILD_WITH_NDK_DIR=$HOME/.mozbuild/android-ndk-r21d
export GONK_DIR=/media/external/dev/capyloon/gsi
export GONK_PRODUCT=phhgsi_arm64_ab

./xcompile.sh --release --strip

adb shell stop ipfsd

adb push ../target/aarch64-linux-android/release/iroh-one /system/bin/ipfsd

# adb push ../target/aarch64-linux-android/debug/iroh-one /data/local/service/ipfsd/ipfsd

adb shell start ipfsd
