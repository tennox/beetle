#!/bin/bash

set -e

rm -rf third-party/*
rm .cargo/config

rm Cargo.lock

cargo clean
cargo update $@

cargo vendor -- third-party > .cargo/config

echo "" >> .cargo/config
echo "[alias]" >> .cargo/config
echo 'xtask = "run --package xtask --"' >> .cargo/config

echo "Before rm: `du -h -d 0 third-party`"

# Remove large and useless prebuilt components.
rm `find third-party -name "*.lib"`
rm -rf third-party/winapi-x86_64-pc-windows-gnu/lib
rm -rf third-party/winapi-i686-pc-windows-gnu/lib
rm -rf third-party/windows-sys/src/Windows
rm -rf third-party/windows/src/Windows
rm -rf third-party/windows_i686_msvc/lib
rm -rf third-party/windows_i686_gnu/lib
rm -rf third-party/windows_i686_gnu-0.36.1/lib
rm -rf third-party/windows_x86_64_msvc/lib
rm -rf third-party/windows_aarch64_msvc/lib
rm -rf third-party/windows_aarch64_msvc-0.34.0/lib
rm -rf third-party/windows_x86_64_gnu/lib
rm -rf third-party/windows_x86_64_gnu-0.34.0/lib
rm -rf third-party/windows_x86_64_msvc-0.34.0/lib
rm -rf third-party/windows_i686_gnu-0.34.0/lib
rm -rf third-party/windows_i686_msvc-0.34.0/lib
rm -rf third-party/windows-sys-0.36.1/src/Windows

echo "After rm: `du -h -d 0 third-party`"
