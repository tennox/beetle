#!/bin/bash

set -e

rm -rf third-party/*
rm -f .cargo/config.toml

# rm -f Cargo.lock

cargo clean
cargo update $@

cargo vendor -- third-party > .cargo/config.toml

# Keep in sync with the upstream .cargo/config.toml at
# https://github.com/n0-computer/iroh/blob/main/.cargo/config.toml
cat <<EOF >> .cargo/config.toml

[alias]
xtask = "run --package xtask --"

[target.x86_64-pc-windows-gnu]
linker = "x86_64-w64-mingw32-gcc"

[build]
rustflags = ["-Wmissing_debug_implementations"]
EOF

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
