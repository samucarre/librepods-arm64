#!/bin/bash
# build-portable.sh — build a PORTABLE binary inside a minimal Debian 12 (bookworm) root created with
# debootstrap and entered with systemd-nspawn, so the result also runs on older distributions (Debian 12+,
# Ubuntu 22.04+, Fedora 36+, Asahi Fedora…: it needs only glibc 2.35). A binary built directly on a new distro only runs on that glibc or newer.
# This is how the release binaries of this repo are made. Needs sudo (debootstrap and nspawn run as root).
#   ./build-portable.sh [rootfs-dir]      → dist/librepods-<arch>-linux-gnu
# Env: ROOTFS, SUITE, UPSTREAM, BRANCH, COMMIT, OUT, JOBS
set -euo pipefail
ROOTFS=${1:-${ROOTFS:-$HOME/src/librepods-build/rootfs-bookworm}}
SUITE=${SUITE:-bookworm}
UPSTREAM=${UPSTREAM:-https://github.com/librepods-org/librepods.git}
BRANCH=${BRANCH:-linux/rust}
COMMIT=${COMMIT:-672e65ad36eebf21ff1c1a508066f9197ee56d17}
OUT=${OUT:-$(pwd)/dist}
JOBS=${JOBS:-$(nproc)}
SUDO="sudo"; [ -n "${SUDO_ASKPASS:-}" ] && SUDO="sudo -A"
msg() { printf '\033[1m==> %s\033[0m\n' "$*"; }

command -v debootstrap >/dev/null || $SUDO apt-get install -y debootstrap
command -v systemd-nspawn >/dev/null || $SUDO apt-get install -y systemd-container
if [ ! -x "$ROOTFS/bin/sh" ]; then
  msg "Creating a minimal Debian $SUITE root in $ROOTFS"
  $SUDO debootstrap --arch="$(dpkg --print-architecture)" --variant=minbase "$SUITE" "$ROOTFS" http://deb.debian.org/debian
fi
NSPAWN="$SUDO systemd-nspawn -q -D $ROOTFS --resolv-conf=replace-host --setenv=DEBIAN_FRONTEND=noninteractive --setenv=PATH=/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
msg "Build tools inside the root (gcc, pkg-config, libdbus-1-dev, libpulse-dev, rustup)"
$NSPAWN bash -c 'apt-get update -q >/dev/null && apt-get install -y -q --no-install-recommends ca-certificates curl git build-essential pkg-config libdbus-1-dev libpulse-dev >/dev/null
  [ -x /root/.cargo/bin/cargo ] || curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal -q'
msg "Building LibrePods ${COMMIT:0:7} ($BRANCH) with $JOBS jobs"
$NSPAWN bash -c "set -e
  if [ -d /build/src/.git ]; then git -C /build/src fetch -q origin $BRANCH; else mkdir -p /build && git clone -q --branch $BRANCH --single-branch $UPSTREAM /build/src; fi
  cd /build/src && { git checkout -q --detach $COMMIT 2>/dev/null || { git fetch -q origin $COMMIT && git checkout -q --detach FETCH_HEAD; }; }
  cd linux-rust && nice -n 10 cargo build --release -j$JOBS"
mkdir -p "$OUT"
ARCH=$(uname -m)
$SUDO install -m 755 -o "$(id -u)" -g "$(id -g)" "$ROOTFS/build/src/linux-rust/target/release/librepods" "$OUT/librepods-$ARCH-linux-gnu"
echo "Needs glibc >= $(objdump -T "$OUT/librepods-$ARCH-linux-gnu" | grep -oE 'GLIBC_[0-9.]+' | sort -t. -k2,2n -k3,3n -u | tail -1 | cut -d_ -f2)"
(cd "$OUT" && sha256sum "librepods-$ARCH-linux-gnu")
