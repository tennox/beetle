#!/bin/bash

set -e

export BUILD_APPSCMD=yes
export OSX_CROSS=/home/capyloon/dev/capyloon/osx-cross

STRIP=${HOME}/.mozbuild/clang/bin/llvm-strip

FEATURES="--features=uds-gateway"

cargo clean

function build_target() {
    rm -rf prebuilts/
    mkdir -p prebuilts/${TARGET_ARCH}

    pushd iroh-one
    cargo build --release --target=${TARGET_ARCH} ${FEATURES}
    popd

    cp target/${TARGET_ARCH}/release/iroh-one prebuilts/${TARGET_ARCH}/ipfsd
    ${STRIP} prebuilts/${TARGET_ARCH}/ipfsd

    tar cJf ipfsd-${TARGET_ARCH}.tar.xz prebuilts
}

function apple_build() {
    rm -rf prebuilts/
    mkdir -p prebuilts/${TARGET_ARCH}

    pushd iroh-one
    ./xcompile.sh --release --strip
    popd

    cp target/${TARGET_ARCH}/release/iroh-one prebuilts/${TARGET_ARCH}/ipfsd
    ${OSX_CROSS}/cctools/bin/${TARGET_ARCH}-strip prebuilts/${TARGET_ARCH}/ipfsd

    tar cJf ipfsd-${TARGET_ARCH}.tar.xz prebuilts
}

# x86_64 desktop build
TARGET_ARCH=x86_64-unknown-linux-gnu
build_target

# Apple aarch64 build
export TARGET_ARCH=aarch64-apple-darwin
apple_build

# Apple x86_64 build
export TARGET_ARCH=x86_64-apple-darwin
apple_build

# Mobian aarch64 build
export MOZBUILD=$HOME/.mozbuild
export TARGET_ARCH=aarch64-unknown-linux-gnu
# TODO: figure our linking issue.
# apple_build

