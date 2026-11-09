#!/bin/bash
# build.sh — build LibrePods (Linux, Rust version) from upstream source on this machine (any architecture).
#   ./build.sh                 build the tested commit into dist/
#   COMMIT=HEAD ./build.sh     build the tip of the upstream branch instead
# Env: UPSTREAM, BRANCH, COMMIT, SRC (checkout dir), OUT (output dir), JOBS (parallel jobs, default: all cores)
set -euo pipefail
UPSTREAM=${UPSTREAM:-https://github.com/librepods-org/librepods.git}
BRANCH=${BRANCH:-linux/rust}
COMMIT=${COMMIT:-672e65ad36eebf21ff1c1a508066f9197ee56d17}
SRC=${SRC:-${XDG_CACHE_HOME:-$HOME/.cache}/librepods-arm64/upstream}
OUT=${OUT:-$(pwd)/dist}
JOBS=${JOBS:-$(nproc)}
msg() { printf '\033[1m==> %s\033[0m\n' "$*"; }

# 1. Build dependencies (Debian/Ubuntu through apt; other distros: see README)
if command -v apt-get >/dev/null; then
  need=()
  for p in build-essential pkg-config libdbus-1-dev libpulse-dev git curl ca-certificates; do
    dpkg -s "$p" >/dev/null 2>&1 || need+=("$p")
  done
  if [ ${#need[@]} -gt 0 ]; then msg "Installing build dependencies: ${need[*]}"; sudo apt-get install -y "${need[@]}"; fi
fi

# 2. Rust >= 1.85 (the code uses edition 2024): the distro's cargo if new enough, otherwise rustup in ~/.cargo
rust_ok() { command -v cargo >/dev/null && rustc --version | awk '{split($2, v, "."); exit !(v[1] > 1 || (v[1] == 1 && v[2] >= 85))}'; }
if ! rust_ok; then
  if [ ! -x "$HOME/.cargo/bin/cargo" ]; then
    msg "Installing Rust with rustup (user-local, ~/.cargo)"
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal
  fi
  export PATH="$HOME/.cargo/bin:$PATH"
  rust_ok || { echo "Rust >= 1.85 is required (found: $(rustc --version 2>/dev/null || echo none))"; exit 1; }
fi

# 3. Upstream source at the pinned commit
if [ -d "$SRC/.git" ]; then
  git -C "$SRC" fetch -q origin "$BRANCH"
else
  mkdir -p "$(dirname "$SRC")"
  git clone -q --branch "$BRANCH" --single-branch "$UPSTREAM" "$SRC"
fi
if [ "$COMMIT" = HEAD ]; then
  git -C "$SRC" checkout -q --detach "origin/$BRANCH"
else
  git -C "$SRC" checkout -q --detach "$COMMIT" 2>/dev/null || { git -C "$SRC" fetch -q origin "$COMMIT"; git -C "$SRC" checkout -q --detach FETCH_HEAD; }
fi
REV=$(git -C "$SRC" rev-parse --short HEAD)

# 4. Build and collect
msg "Building LibrePods $REV with $JOBS jobs (a few minutes; ~2 GB in $SRC/linux-rust/target)"
(cd "$SRC/linux-rust" && nice -n 10 cargo build --release -j"$JOBS")
mkdir -p "$OUT"
ARCH=$(uname -m)
install -m 755 "$SRC/linux-rust/target/release/librepods" "$OUT/librepods-$ARCH-linux-gnu"
(cd "$OUT" && sha256sum "librepods-$ARCH-linux-gnu")
msg "Done: $OUT/librepods-$ARCH-linux-gnu — now run ./install.sh to install it for your user"
