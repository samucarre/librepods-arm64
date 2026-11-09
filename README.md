# LibrePods for Linux — prebuilt arm64 (aarch64) binaries

*[Versión en español](README.es.md)*

**Unofficial** builds of the Linux desktop app of [LibrePods](https://github.com/librepods-org/librepods) for 64-bit ARM
machines: Apple Silicon Macs running Linux (Asahi Fedora, Debian, WayBian…), Raspberry Pi 4/5 and other arm64 boards.
Upstream only publishes Android APKs and x86_64 CI artifacts, so if you searched for "LibrePods arm64" and found nothing: this is it.

LibrePods speaks the proprietary protocol AirPods use with Apple devices, so on Linux you get what BlueZ alone cannot:

| Feature (Linux app) | Status |
|---|---|
| Listening modes: Off · Transparency · Adaptive · Noise Cancellation | ✅ |
| Conversation Awareness toggle | ✅ |
| Ear detection: pause/resume your player (MPRIS) when you take a bud out | ✅ |
| Battery level of each bud and the case (tray icon + tooltip) | ✅ |
| Automatic A2DP profile when you put them on | ✅ |
| Head gestures, hearing aid, transparency fine-tuning, loud sound reduction | ❌ not implemented upstream |

Extras in this repo, not in upstream: **`airpods-modo`**, a command-line tool to read and change the mode (the Rust
app has no CLI), and `build.sh` / `install.sh` for a one-command install.

## Install from the release

1. Pair and connect your AirPods with BlueZ as usual (`bluetoothctl`, your desktop's Bluetooth settings, …).
2. Download the latest `librepods-<commit>-aarch64-linux-gnu.tar.gz` from [Releases](../../releases) and run:

```sh
tar xzf librepods-*-aarch64-linux-gnu.tar.gz
cd librepods-*-aarch64-linux-gnu
./install.sh              # add --autostart for GNOME/KDE/XFCE autostart
librepods --start-minimized
airpods-modo status
```

`install.sh` puts `librepods` and `airpods-modo` in `~/.local/bin`, plus a `.desktop` entry and icon in `~/.local/share`. No root needed.

**Requirements:** glibc ≥ 2.35 (the binaries are built inside Debian 12, so they run on Debian 12+, Ubuntu 22.04+,
Fedora 36+ and Asahi Fedora), `libpulse0` and `libdbus-1-3` (Debian/Ubuntu names; the PulseAudio client library also
talks to PipeWire), BlueZ, PipeWire or PulseAudio. `airpods-modo` needs Python 3 with PyGObject (`python3-gi`).
A StatusNotifier/AppIndicator tray (waybar `tray`, KDE, GNOME with the AppIndicator extension) shows the icon with
battery and a menu; without a tray, use the window (`librepods`) or `airpods-modo`.

**Autostart on Hyprland / sway:** `exec-once = librepods --start-minimized` (Hyprland) or `exec librepods --start-minimized` (sway).
Logs: run with `-d` for debug output; with `systemd-cat -t librepods librepods --start-minimized` they go to `journalctl -t librepods`.

## `airpods-modo` — the mode from the terminal, a key binding or your bar

The Rust app exposes everything through its tray menu, so `airpods-modo` drives that menu over D-Bus
(StatusNotifierItem + `com.canonical.dbusmenu`). It works even if your bar has no tray. LibrePods must be running.
Commands are accepted in English and Spanish; messages follow your locale.

| Command | Does |
|---|---|
| `airpods-modo status` (default) | current mode, Conversation Awareness, battery |
| `airpods-modo anc` / `transparency` / `adaptive` / `off` | set that mode (`off` only if your model offers it; like iOS, many hide it) |
| `airpods-modo next` | cycle through the available modes (bind it to a key) |
| `airpods-modo conversation` | toggle Conversation Awareness |
| `airpods-modo window` / `quit` | open the LibrePods window / close LibrePods |
| `airpods-modo status --json` | `{"text", "tooltip", "class", "modo", "disponibles", "bateria"}` for bars |

Waybar module example:

```jsonc
"custom/airpods": {
  "exec": "airpods-modo status --json", "return-type": "json", "interval": 5,
  "format": "󰋋 {}", "on-click": "airpods-modo next", "on-click-right": "airpods-modo window"
}
```

## Build it yourself

```sh
./build.sh                  # Debian/Ubuntu: installs build deps with apt, Rust via rustup if needed; any architecture
./install.sh
```

`build.sh` pins the upstream commit that was tested (branch `linux/rust`, see the script); `COMMIT=HEAD ./build.sh`
builds the branch tip. Other distros: install `pkg-config`, the D-Bus and PulseAudio development headers and Rust ≥ 1.85, then run it.
`build-portable.sh` is how the release binaries are made: a Debian 12 root via `debootstrap` + `systemd-nspawn`,
so the result needs only glibc 2.35.

## Things learned on the way

- **Pairing:** AirPods advertise as "AirPods Pro - Find My" even while in pairing mode (BlueZ caches that name). Open
  the case, hold the button until the light blinks white and run `bluetoothctl pair <MAC>` while `scan on` is active.
  Pairing with Linux unlinks them from your iPhone/Mac until you pair them there again.
- Our first A2DP connection dropped after 30 s on the AirPods side; the second one was stable. If it happens, just reconnect.
- The `Off` listening mode is hidden on some models unless enabled from an Apple device (same as iOS). `airpods-modo status --json` lists what yours offer.
- Startup log line `LE monitor error … RegisterMonitor … doesn't exist`: your BlueZ has no AdvertisementMonitor
  support; LibrePods still works, it only loses the LE "in the case" advertisements.
- Stem presses: upstream's `stem_control` is off by default; `mpris-proxy` (BlueZ) keeps handling play/pause over AVRCP.
  Don't enable both or you get double toggles.
- Hearing-aid features would need BlueZ to identify as an Apple device (`DeviceID = bluetooth:004C:0000:0000` in
  `/etc/bluetooth/main.conf`); not covered here.

Tested on a MacBook Pro 16" M3 Max (Apple T6031) running Debian with Hyprland 0.57, PipeWire 1.6, BlueZ 5.88 and
AirPods Pro 2 (model A3048). Reports from other boards and models are welcome in the issues.

## Credits and license

LibrePods is by [Kavish Devar](https://github.com/kavishdevar) and contributors, licensed under the **GNU AGPL-3.0**.
This repository redistributes unmodified builds of it; each release includes the exact source tarball of the commit
it was built from, as the license requires. The build scripts and `airpods-modo` are by Samuel Carreño
([@samucarre](https://github.com/samucarre)) under the same AGPL-3.0. Not affiliated with the LibrePods project
(note that upstream warns `librepods.org` is not their site either).
