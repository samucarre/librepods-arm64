# LibrePods para Linux — binarios arm64 (aarch64) ya compilados

*[English version](README.md)*

Compilaciones **no oficiales** de la app de escritorio Linux de [LibrePods](https://github.com/librepods-org/librepods)
para máquinas ARM de 64 bits: Macs con Apple Silicon que arrancan Linux (Asahi Fedora, Debian, WayBian…), Raspberry Pi 4/5
y otras placas arm64. Upstream solo publica APK de Android y artefactos de CI para x86_64, así que si buscabas
«LibrePods arm64» y no encontrabas nada: es esto.

LibrePods habla el protocolo propietario que los AirPods usan con los dispositivos de Apple, y da en Linux lo que BlueZ solo no puede:

| Función (app de Linux) | Estado |
|---|---|
| Modos de escucha: apagado · transparencia · adaptativo · cancelación de ruido | ✅ |
| Detección de conversación (activar/desactivar) | ✅ |
| Detección de oído: pausa y reanuda el reproductor (MPRIS) al quitarte un auricular | ✅ |
| Batería de cada auricular y del estuche (icono de bandeja + tooltip) | ✅ |
| Perfil A2DP automático al ponértelos | ✅ |
| Gestos de cabeza, audífono, ajuste fino de la transparencia, reducción de sonidos fuertes | ❌ no implementado en upstream |

Extras de este repo que no están en upstream: **`airpods-modo`**, un mando de terminal para leer y cambiar el modo
(la app en Rust no trae CLI), y `build.sh` / `install.sh` para instalar con una orden.

## Instalar desde la release

1. Empareja y conecta los AirPods con BlueZ como siempre (`bluetoothctl`, los ajustes Bluetooth de tu escritorio…).
2. Descarga el último `librepods-<commit>-aarch64-linux-gnu.tar.gz` de [Releases](../../releases) y ejecuta:

```sh
tar xzf librepods-*-aarch64-linux-gnu.tar.gz
cd librepods-*-aarch64-linux-gnu
./install.sh              # añade --autostart para el autoarranque de GNOME/KDE/XFCE
librepods --start-minimized
airpods-modo estado
```

`install.sh` deja `librepods` y `airpods-modo` en `~/.local/bin`, más el lanzador `.desktop` y el icono en `~/.local/share`. Sin root.

**Requisitos:** glibc ≥ 2.35 (los binarios se compilan dentro de Debian 12, así que valen en Debian 12+, Ubuntu 22.04+,
Fedora 36+ y Asahi Fedora), `libpulse0` y `libdbus-1-3` (nombres de Debian/Ubuntu; la biblioteca cliente de PulseAudio
también habla con PipeWire), BlueZ, PipeWire o PulseAudio. `airpods-modo` necesita Python 3 con PyGObject (`python3-gi`).
Una bandeja StatusNotifier/AppIndicator (`tray` de waybar, KDE, GNOME con la extensión AppIndicator) enseña el icono con
la batería y un menú; sin bandeja, usa la ventana (`librepods`) o `airpods-modo`.

**Autoarranque en Hyprland / sway:** `exec-once = librepods --start-minimized` (Hyprland) o `exec librepods --start-minimized` (sway).
Registro: con `-d` saca depuración; con `systemd-cat -t librepods librepods --start-minimized` va a `journalctl -t librepods`.

## `airpods-modo` — el modo desde la terminal, un atajo o tu barra

La app en Rust lo expone todo por su menú de bandeja, así que `airpods-modo` maneja ese menú por D-Bus
(StatusNotifierItem + `com.canonical.dbusmenu`). Funciona aunque tu barra no tenga bandeja. LibrePods tiene que estar en marcha.
Acepta las órdenes en español y en inglés; los mensajes siguen el idioma del sistema.

| Orden | Hace |
|---|---|
| `airpods-modo estado` (por defecto) | modo actual, detección de conversación y batería |
| `airpods-modo anc` / `transparencia` / `adaptativo` / `off` | fija ese modo (`off` solo si tu modelo lo ofrece; como iOS, muchos lo ocultan) |
| `airpods-modo siguiente` | pasa al siguiente modo disponible (para un atajo de teclado) |
| `airpods-modo conversacion` | activa/desactiva la detección de conversación |
| `airpods-modo ventana` / `salir` | abre la ventana de LibrePods / cierra LibrePods |
| `airpods-modo estado --json` | `{"text", "tooltip", "class", "modo", "disponibles", "bateria"}` para barras |

Ejemplo de módulo para waybar:

```jsonc
"custom/airpods": {
  "exec": "airpods-modo estado --json", "return-type": "json", "interval": 5,
  "format": "󰋋 {}", "on-click": "airpods-modo siguiente", "on-click-right": "airpods-modo ventana"
}
```

## Compilarlo tú

```sh
./build.sh                  # Debian/Ubuntu: instala las dependencias con apt y Rust con rustup si hace falta; cualquier arquitectura
./install.sh
```

`build.sh` fija el commit de upstream que se probó (rama `linux/rust`, ver el script); `COMMIT=HEAD ./build.sh` compila la
punta de la rama. Otras distros: instala `pkg-config`, las cabeceras de desarrollo de D-Bus y PulseAudio y Rust ≥ 1.85, y lánzalo.
`build-portable.sh` es como se hacen los binarios de las releases: una raíz Debian 12 con `debootstrap` + `systemd-nspawn`,
para que el resultado solo pida glibc 2.35.

## Cosas aprendidas por el camino

- **Emparejar:** los AirPods se anuncian como «AirPods Pro - Find My» incluso en modo emparejamiento (BlueZ cachea ese
  nombre). Abre el estuche, mantén el botón hasta que la luz parpadee en blanco y lanza `bluetoothctl pair <MAC>` con
  `scan on` activo. Emparejarlos con Linux los desvincula del iPhone/Mac hasta que los vuelvas a emparejar allí.
- Nuestra primera conexión A2DP se cortó a los 30 s desde el lado de los AirPods; la segunda fue estable. Si pasa, reconecta.
- El modo «apagado» está oculto en algunos modelos salvo que se active desde un dispositivo Apple (igual que iOS).
  `airpods-modo estado --json` dice cuáles ofrecen los tuyos.
- La línea de arranque `LE monitor error … RegisterMonitor … doesn't exist`: tu BlueZ no tiene soporte de
  AdvertisementMonitor; LibrePods funciona igual, solo pierde los anuncios LE «en el estuche».
- Pulsaciones del tallo: el `stem_control` de upstream viene desactivado; `mpris-proxy` (BlueZ) sigue haciendo
  play/pausa por AVRCP. No actives los dos o tendrás dobles pulsaciones.
- Las funciones de audífono necesitarían que BlueZ se identificase como dispositivo Apple
  (`DeviceID = bluetooth:004C:0000:0000` en `/etc/bluetooth/main.conf`); no se cubre aquí.

Probado en un MacBook Pro 16" M3 Max (Apple T6031) con Debian, Hyprland 0.57, PipeWire 1.6, BlueZ 5.88 y unos
AirPods Pro 2 (modelo A3048). Se agradecen informes de otras placas y modelos en los issues.

## Créditos y licencia

LibrePods es de [Kavish Devar](https://github.com/kavishdevar) y colaboradores, bajo la **GNU AGPL-3.0**. Este repositorio
redistribuye compilaciones sin modificar; cada release incluye el tarball exacto del código del commit con el que se compiló,
como exige la licencia. Los scripts de compilación y `airpods-modo` son de Samuel Carreño
([@samucarre](https://github.com/samucarre)) bajo la misma AGPL-3.0. Sin relación con el proyecto LibrePods
(upstream avisa, además, de que `librepods.org` tampoco es suyo).
