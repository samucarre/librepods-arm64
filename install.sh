#!/bin/bash
# install.sh — install LibrePods + airpods-modo for the current user (no root), from the unpacked release tarball
# or from this repo after ./build.sh.   Option: --autostart  also creates ~/.config/autostart/librepods.desktop
# (GNOME, KDE, XFCE, …). Hyprland/sway users: add `exec-once = librepods --start-minimized` instead (see README).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
BIN=$HOME/.local/bin
APPS=$HOME/.local/share/applications
ICONS=$HOME/.local/share/icons/hicolor/256x256/apps
ARCH=$(uname -m)
SRC_BIN=""
for c in "$HERE/librepods-$ARCH-linux-gnu" "$HERE/dist/librepods-$ARCH-linux-gnu"; do
  [ -f "$c" ] && SRC_BIN=$c && break
done
[ -n "$SRC_BIN" ] || { echo "No LibrePods binary for $ARCH here. Download the release for your architecture or run ./build.sh first."; exit 1; }

mkdir -p "$BIN" "$APPS" "$ICONS"
install -m 755 "$SRC_BIN" "$BIN/librepods"
install -m 755 "$HERE/airpods-modo" "$BIN/airpods-modo"
install -m 644 "$HERE/assets/librepods.desktop" "$APPS/librepods.desktop"
install -m 644 "$HERE/assets/librepods.png" "$ICONS/librepods.png"

# Runtime libraries the binary needs (PulseAudio client library works with PipeWire too)
missing=$(ldd "$BIN/librepods" 2>/dev/null | awk '/not found/ {print $1}' | tr '\n' ' ')
if [ -n "$missing" ]; then
  echo "Missing libraries: $missing"
  echo "  Debian/Ubuntu: sudo apt install libpulse0 libdbus-1-3      Fedora: sudo dnf install pulseaudio-libs dbus-libs"
fi
python3 -c 'import gi; gi.require_version("Gio", "2.0")' 2>/dev/null \
  || echo "airpods-modo needs PyGObject: Debian/Ubuntu: sudo apt install python3-gi    Fedora: sudo dnf install python3-gobject"

if [ "${1:-}" = --autostart ]; then
  mkdir -p "$HOME/.config/autostart"
  sed 's|^Exec=.*|Exec=librepods --start-minimized|' "$HERE/assets/librepods.desktop" > "$HOME/.config/autostart/librepods.desktop"
  echo "Autostart entry: ~/.config/autostart/librepods.desktop"
fi
case ":$PATH:" in *":$BIN:"*) ;; *) echo "Note: $BIN is not in your PATH (add it, or call $BIN/librepods)";; esac
echo "Installed $BIN/librepods and $BIN/airpods-modo."
echo "Start it with:  librepods --start-minimized      then try:  airpods-modo status"
