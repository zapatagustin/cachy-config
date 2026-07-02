# cachy-config

Dotfiles personales para CachyOS (Arch-based) con entorno de escritorio Wayland basado en **Hyprland** + **Quickshell**.

## Arquitectura

Login via **greetd + tuigreet**. La sesión arranca con **uwsm** (session file
`Hyprland (uwsm-managed)`), que corre Hyprland dentro de un systemd user session.

```
greetd → tuigreet → uwsm start Hyprland
└── uwsm sourcea ~/.config/uwsm/env (env vars → systemd/dbus)
    └── hyprland.conf (entry point)
        ├── sources: startup.conf, input.conf, monitors.conf, programs.conf,
        │            binds.conf, rules.conf, variables.conf, theme.conf
        ├── exec-once: uwsm finalize HYPRLAND_INSTANCE_SIGNATURE
        │              (propaga env al systemd user session)
        ├── exec-once (one-shots): set-theme.sh dark, setup-monitors.sh,
        │              hyprpolkitagent, cliphist watchers
        └── graphical-session.target → arranca systemd user units:
            ├── hyprpaper.service
            ├── monitor-watcher.service (relanza units en hotplug de monitor)
            └── quickshell.service → quickshell -p ~/.config/quickshell/bar
                └── shell.qml (root)
                    ├── vigila: /tmp/qs-theme, /tmp/qs-launcher, /tmp/qs-notif, /tmp/qs-clipboard
                    └── instancia: Bar.qml (por pantalla)
                        ├── Workspaces.qml + WorkspaceButton.qml (numerales japoneses 一〜九)
                        ├── WindowTitle.qml
                        └── RightSection.qml
                            ├── TrayIcon.qml, Volume.qml, Brightness.qml, Battery.qml, Clock.qml
```

## Estructura de directorios

### `hypr/` — Configuración de Hyprland (modular)

| Archivo | Rol |
|---------|-----|
| `hyprland.conf` | Entry point, sourcea todos los demás |
| `binds.conf` | Keybindings (Super como mod key) |
| `input.conf` | Layout teclado (es/us con Dvorak), touchpad |
| `monitors.conf` | Configuración de displays |
| `startup.conf` | Autostart: `uwsm finalize`, hyprpolkitagent, cliphist, set-theme, setup-monitors. (hyprpaper/quickshell/monitor-watcher son systemd units, ver abajo) |
| `programs.conf` | Variables de programas ($terminal=kitty, $fileManager=dolphin) |
| `rules.conf` | Window rules |
| `theme.conf` | Gaps (3/6px), borders (1px), animaciones deshabilitadas |
| `variables.conf` | Vacía — las env vars se movieron a `~/.config/uwsm/env` |
| `permissions.conf` | Placeholder para permisos futuros |
| `hypridle.conf` | Idle: 4min dim → 5min lock → 6min dpms off → 15min suspend |
| `hyprlock.conf` | Lock screen (Gruvbox, reloj grande, blur) |
| `hyprpaper.conf` | Wallpaper |
| `set-theme.sh` | Cambia tema (dark/light): GTK, gsettings, borders de Hyprland, `/tmp/qs-theme` |
| `setup-monitors.sh` | Detecta y configura displays (one-shot al arranque) |
| `monitor-watcher.sh` | Daemon (systemd unit): escucha socket2, re-corre setup-monitors + relanza hyprpaper/quickshell units en hotplug |
| `screenshot.sh` | Screenshots con grim+slurp (region/window/output/screen), copia a clipboard + guarda en `~/Pictures/Screenshots` |
| `theme-watcher.sh` | Daemon legacy, NO usado (auto-theme deshabilitado) |

### `quickshell/` — Barra de estado custom en QML

Hay dos implementaciones:
- **`quickshell/*.qml`** — Versión legacy (API vieja `HyprlandInfo`), no activa
- **`quickshell/bar/`** — Versión activa (API nueva `Hyprland.*`)

#### `quickshell/bar/` (implementación activa)

| Archivo | Rol |
|---------|-----|
| `shell.qml` | Root ShellRoot; tema, IPC watchers, popups globales |
| `Bar.qml` | PanelWindow (28px alto, zona exclusiva top) |
| `Workspaces.qml` | 9 botones con numerales japoneses |
| `WorkspaceButton.qml` | Botón individual (22×22px, estados: active/occupied/empty) |
| `WindowTitle.qml` | Título de ventana activa |
| `RightSection.qml` | Contenedor derecho |
| `Volume.qml` | Volumen via `pactl` (poll cada 3s) |
| `Brightness.qml` | Brillo via `/sys/class/backlight/intel_backlight/` |
| `Battery.qml` | Batería via `/sys/class/power_supply/BAT1/` (poll cada 30s) |
| `Clock.qml` | Reloj + fecha en español (poll cada 1s) |
| `TrayIcon.qml` | Íconos de system tray con menú contextual |
| `NotificationCenter.qml` | Panel lateral (400×500px), vim keybinds (j/k/d/l/h/g) |
| `NotificationPopup.qml` | Toast de notificación (top-right, auto-expire) |
| `Launcher.qml` | App launcher dmenu-style, resultados horizontales |
| `ClipboardViewer.qml` | Historial clipboard (cliphist), pin/unpin, search, vim keybinds |
| `get-apps.sh` | Parsea `.desktop` files → `Name\tcmd` |

### `doom/` — Configuración de Doom Emacs

Symlink de directorio: `~/.doom.d` → `doom/`. Contiene `config.el` (tema `doom-gruvbox`,
fuente "Terminess Nerd Font" — paquete `ttf-terminus-nerd`), `init.el` y `packages.el`.
Doom Emacs en sí (`~/.emacs.d`) lo clona `setup-desktop.sh`; no vive en este repo.
Cambios en `config.el` solo requieren `doom/reload`, no `doom sync`.

## Comunicación IPC

Hyprland y Quickshell se comunican via named pipes en `/tmp/`:

| Pipe | Propósito | Escribe | Lee |
|------|-----------|---------|-----|
| `/tmp/qs-theme` | Cambio de tema (dark/light) | `set-theme.sh` | `shell.qml` |
| `/tmp/qs-launcher` | Toggle app launcher | `binds.conf` (Super+D) | `shell.qml` |
| `/tmp/qs-notif` | Toggle notification center | `binds.conf` (Super+Shift+P) | `shell.qml` |
| `/tmp/qs-clipboard` | Toggle clipboard viewer | `binds.conf` (Super+P) | `shell.qml` |
| `/tmp/qs-clipboard-pinned` | Clipboard pins persistidos | `ClipboardViewer.qml` | `ClipboardViewer.qml` |
| `/tmp/current-theme-mode` | Cache de tema actual (evita thrashing) | `set-theme.sh` | `set-theme.sh` |

Nota: `theme-watcher.sh` existe pero NO se usa (auto-theme deshabilitado).

Quickshell usa `tail -f` sobre estos archivos para reaccionar a cambios.

## Sesión: greetd + uwsm + systemd units

- **Display manager**: `greetd` con `tuigreet` (TUI). Config en `/etc/greetd/config.toml`. `F3` cicla sesiones; elegir `Hyprland (uwsm-managed)`.
- **uwsm**: lanza Hyprland dentro de un systemd user session. `exec-once = uwsm finalize HYPRLAND_INSTANCE_SIGNATURE` en `startup.conf` propaga env vars (incluida la firma de instancia, necesaria para que los units hablen con el socket de Hyprland) a systemd/dbus.
- **Env vars**: en `uwsm/env` (symlink → `~/.config/uwsm/env`), NO en `variables.conf`. uwsm las sourcea antes de lanzar el compositor.
- **Apps via `uwsm app -- `**: el terminal (`binds.conf`) y todas las apps del launcher (`Launcher.qml` dispatch) se lanzan así → cada una en su propio systemd scope (cleanup ordenado).

### `systemd/user/` — units (symlinks → `~/.config/systemd/user/`)

| Unit | Rol |
|------|-----|
| `hyprpaper.service` | Wallpaper daemon. `Restart=on-failure` |
| `quickshell.service` | Barra. `Restart=on-failure` |
| `monitor-watcher.service` | Watcher de hotplug. `ensure_*` usa `systemctl --user restart` (no `pgrep`+`hyprctl dispatch`) |

Todas: `WantedBy=graphical-session.target`, enabled. uwsm activa el target → arrancan solas. `daemon-reload` + `enable` ya hechos.

## Tema y colores

**Paleta Gruvbox** con modo dual:
- **Dark**: default al iniciar
- **Light/Dark toggle**: click en 🌙/☀ en la barra (RightSection.qml)
- No hay auto-switch por hora (deshabilitado)

Cada tema define: `bg`, `bg1`, `bg2`, `fg`, `fgDim`, `yellow`, `blue`, `aqua`, `accent`, `border`, `borderInactive`.

Colores de acento usan variantes Gruvbox **bright** en dark mode (`#fabd2f`, `#83a598`, `#8ec07c`) y **faded** en light mode (`#b57614`, `#076678`, `#427b58`).

`set-theme.sh` aplica el tema a: GTK (gsettings), Hyprland borders (hyprctl), y Quickshell (via `/tmp/qs-theme`). Solo acepta `dark` o `light`.

## Keybindings principales

| Atajo | Acción |
|-------|--------|
| `Super+Return` | Terminal (kitty) |
| `Super+1-9` | Cambiar workspace |
| `Super+Shift+1-9` | Mover ventana a workspace |
| `Super+C` | Cerrar ventana |
| `Super+Space` | Toggle floating |
| `Super+F` | Fullscreen |
| `Super+D` | App launcher |
| `Super+P` | Clipboard viewer |
| `Super+Shift+P` | Notification center |
| `Super+L` | Lock screen |
| `Alt+Tab` | Cycle windows |
| `Print` | Screenshot región (selección con mouse) |
| `Shift+Print` | Screenshot ventana activa |
| `Ctrl+Print` | Screenshot monitor bajo cursor |
| `Super+Print` | Screenshot pantalla completa |

Screenshots copian al clipboard y guardan en `~/Pictures/Screenshots/<timestamp>.png`.

## Dependencias

```
# Core
hyprland hypridle hyprlock hyprpaper quickshell-git

# Sesión / login
greetd greetd-tuigreet uwsm

# Quickshell debe compilarse con módulos:
#   Quickshell.Hyprland, Quickshell.Services.SystemTray, Quickshell.Services.Notifications

# Fonts
noto-fonts-cjk ttf-nerd-fonts-symbols

# Apps
kitty dolphin gwenview   # gwenview = visor de imágenes por defecto

# Utilidades
cliphist wl-clipboard pactl brightnessctl playerctl wpctl
grim slurp jq   # screenshots
socat           # monitor-watcher (lee socket2 de Hyprland)

# Sistema
hyprpolkitagent gsettings
```

## Paths hardcodeados (hardware-specific)

- **Backlight**: `/sys/class/backlight/intel_backlight/` — solo Intel iGPU
- **Batería**: `/sys/class/power_supply/BAT1/` — solo laptops
- **Wallpaper**: `~/Pictures/Wallpapers/coding-2.png` — en hyprlock.conf

## Convenciones de código

- **Idioma**: Comentarios y textos UI en español
- **QML**: Sigue patrones estándar Qt/QML, propiedades `required property` para componentes
- **Modularidad**: Hyprland usa archivos `.conf` separados por concern; Quickshell usa componentes QML separados
- **Vim keybinds**: Notification center y clipboard viewer usan j/k/d/l/h/g
- **Estética**: Numerales japoneses en workspaces, fuente Noto Sans JP
- **Seguridad**: `ClipboardViewer.qml` usa `shellQuote()` para escapar contenido en comandos shell

## Instalación

No hay build step. Los archivos de `~/.config/{hypr,quickshell}/` son **symlinks individuales** a este repo (editar el repo = editar la config live). `~/.config/uwsm/env` y `~/.config/systemd/user/*.service` también son symlinks al repo.

```bash
# Symlinks (ejemplo, si se arma de cero)
ln -s "$PWD/uwsm/env" ~/.config/uwsm/env
for u in hyprpaper quickshell monitor-watcher; do
  ln -s "$PWD/systemd/user/$u.service" ~/.config/systemd/user/$u.service
done

# Habilitar units (arrancan solas via graphical-session.target bajo uwsm)
systemctl --user daemon-reload
systemctl --user enable hyprpaper.service quickshell.service monitor-watcher.service

# Login manager: greetd (config en /etc/greetd/config.toml, requiere root)
sudo systemctl enable greetd.service
```

## Notas para desarrollo

- La versión activa de quickshell está en `quickshell/bar/`, no en `quickshell/` root (esos son legacy)
- hyprpaper/quickshell/monitor-watcher son **systemd user units**, no `exec-once`. Para reiniciarlos: `systemctl --user restart quickshell.service`. Logs: `journalctl --user -u quickshell.service -f`
- Env vars nuevas van en `uwsm/env` (no en `variables.conf`)
- Apps nuevas lanzadas desde binds/launcher: usar `uwsm app -- <cmd>` para que queden en su propio systemd scope
- Los pipes IPC se crean implícitamente; Quickshell hace `tail -f` y reacciona al contenido nuevo
- `theme-watcher.sh` existe pero no se usa (auto-theme deshabilitado)
- `set-theme.sh` solo acepta `dark` o `light` (default: dark); cachea en `/tmp/current-theme-mode`
- Volume.qml parsea output de `pactl get-sink-volume @DEFAULT_SINK@`
- `get-apps.sh` parsea manualmente archivos `.desktop` (sin depender de libs externas)
