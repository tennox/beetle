#!/bin/bash

set -e

export OSX_CROSS=/home/capyloon/dev/capyloon/osx-cross

LLVM_STRIP=${HOME}/.mozbuild/clang/bin/llvm-strip

FEATURES="--features=uds-gateway"

cargo clean

function build_target() {
    rm -rf prebuilts/
    mkdir -p prebuilts/${TARGET_ARCH}

    pushd iroh-one
    cargo build --release --target=${TARGET_ARCH} ${FEATURES}
    popd

    cp target/${TARGET_ARCH}/release/iroh-one prebuilts/${TARGET_ARCH}/ipfsd
    ${LLVM_STRIP} prebuilts/${TARGET_ARCH}/ipfsd

    tar cJf ipfsd-${TARGET_ARCH}.tar.xz prebuilts
}

function xc_build() {
    rm -rf prebuilts/
    mkdir -p prebuilts/${TARGET_ARCH}

    pushd iroh-one
    ./xcompile.sh --release --strip
    popd

    cp target/${TARGET_ARCH}/release/iroh-one prebuilts/${TARGET_ARCH}/ipfsd
    ${STRIP} prebuilts/${TARGET_ARCH}/ipfsd

    tar cJf ipfsd-${TARGET_ARCH}.tar.xz prebuilts
}

# x86_64 desktop build
TARGET_ARCH=x86_64-unknown-linux-gnu
build_target

# Apple aarch64 build
export TARGET_ARCH=aarch64-apple-darwin
STRIP=${OSX_CROSS}/cctools/bin/${TARGET_ARCH}-strip
xc_build

# Apple x86_64 build
export TARGET_ARCH=x86_64-apple-darwin
STRIP=${OSX_CROSS}/cctools/bin/${TARGET_ARCH}-strip
xc_build

# Mobian aarch64 build
unset OSX_CROSS
export MOZBUILD=$HOME/.mozbuild
STRIP=${LLVM_STRIP}
export TARGET_ARCH=aarch64-unknown-linux-gnu
xc_build

