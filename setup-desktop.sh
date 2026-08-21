#!/bin/bash
# setup-desktop.sh — Replica exacta de la laptop CachyOS en un desktop
# Uso: bash setup-desktop.sh
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}==>${NC} $1"; }
warn()  { echo -e "${YELLOW}==>${NC} $1"; }
err()   { echo -e "${RED}==>${NC} $1"; }

REPO_URL="https://github.com/zapatagustin/cachy-config"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$SCRIPT_DIR/.git" ]; then
  REPO_DIR="$SCRIPT_DIR"
else
  REPO_DIR="$HOME/Projects/cachy-config"
fi

# ── Detectar AUR helper ──────────────────────────────────────────────
AUR_HELPER=""
for h in yay paru; do
  command -v "$h" &>/dev/null && { AUR_HELPER="$h"; break; }
done
[ -z "$AUR_HELPER" ] && { err "No AUR helper. Install yay or paru first."; exit 1; }
info "AUR helper: $AUR_HELPER"

# ── Paquetes ─────────────────────────────────────────────────────────
# El inventario completo de esta laptop: 267 oficial + 8 AUR
# Si los .txt están al lado del script, los usa; si no, instala lo esencial.

PKGLIST_OFFICIAL="$SCRIPT_DIR/pkglist-official.txt"
PKGLIST_AUR="$SCRIPT_DIR/pkglist-aur.txt"

if [ -f "$PKGLIST_OFFICIAL" ]; then
  info "Instalando paquetes oficiales desde pkglist-official.txt..."
  sudo pacman -S --needed --noconfirm - < "$PKGLIST_OFFICIAL"
else
  info "Sin pkglist-official.txt — instalando paquetes core..."
  sudo pacman -S --needed --noconfirm \
    hyprland hypridle hyprlock hyprpaper uwsm greetd greetd-tuigreet \
    kitty dolphin gwenview \
    noto-fonts-cjk ttf-nerd-fonts-symbols ttf-meslo-nerd \
    cliphist wl-clipboard brightnessctl grim slurp jq socat playerctl \
    pipewire-pulse wireplumber \
    hyprpolkitagent glib
fi

if [ -f "$PKGLIST_AUR" ]; then
  info "Instalando paquetes AUR desde pkglist-aur.txt..."
  $AUR_HELPER -S --needed --noconfirm - < "$PKGLIST_AUR"
else
  info "Sin pkglist-aur.txt — instalando solo quickshell-git..."
  $AUR_HELPER -S --needed --noconfirm quickshell-git
fi

# ── Flatpak ──────────────────────────────────────────────────────────
if command -v flatpak &>/dev/null; then
  info "Instalando Flatpaks (Slack, sone)..."
  flatpak install -y flathub com.slack.Slack io.github.lullabyX.sone 2>/dev/null || true
fi

# ── Clone / pull repo ────────────────────────────────────────────────
if [ "$SCRIPT_DIR" = "$REPO_DIR" ]; then
  warn "Ya estamos en el repo — no hace falta clone"
elif [ -d "$REPO_DIR" ]; then
  warn "$REPO_DIR ya existe, pull en vez de clone"
  git -C "$REPO_DIR" pull --ff-only
else
  info "Clonando repo..."
  mkdir -p "$HOME/Projects"
  git clone "$REPO_URL" "$REPO_DIR"
fi

# ── Symlinks: configs principales ────────────────────────────────────
info "Creando symlinks de config..."

link_dir() {
  local src="$1" dst="$2"
  [ -L "$dst" ] && rm "$dst"
  [ -d "$dst" ] && ! [ -L "$dst" ] && { warn "$dst existe — moviendo a $dst.bak"; mv "$dst" "$dst.bak"; }
  ln -sfn "$src" "$dst"
}

link_dir "$REPO_DIR/hypr"          "$HOME/.config/hypr"
link_dir "$REPO_DIR/quickshell"    "$HOME/.config/quickshell"
link_dir "$REPO_DIR/systemd/user"  "$HOME/.config/systemd/user"
link_dir "$REPO_DIR/doom"          "$HOME/.doom.d"

# Quadlets (podman rootless). El generador lee ~/.config/containers/systemd,
# y sigue el symlink sin problema. Los secretos NO viven acá: los units usan
# EnvironmentFile=~/.config/immich/db.env, que queda fuera del repo.
mkdir -p "$HOME/.config/containers"
link_dir "$REPO_DIR/containers/systemd" "$HOME/.config/containers/systemd"

mkdir -p "$HOME/.config/uwsm"
[ -L "$HOME/.config/uwsm/env" ] && rm "$HOME/.config/uwsm/env"
[ -f "$HOME/.config/uwsm/env" ] && ! [ -L "$HOME/.config/uwsm/env" ] && \
  { warn "$HOME/.config/uwsm/env existe — backup"; mv "$HOME/.config/uwsm/env" "$HOME/.config/uwsm/env.bak"; }
ln -sfn "$REPO_DIR/uwsm/env" "$HOME/.config/uwsm/env"

# ── Dotfiles sueltos (bashrc, git, gtk) ──────────────────────────────
info "Instalando dotfiles varios..."

cp "$REPO_DIR/dotfiles/bashrc"               "$HOME/.bashrc"
cp "$REPO_DIR/dotfiles/gitconfig"            "$HOME/.gitconfig"
cp "$REPO_DIR/dotfiles/gitconfig-personal"   "$HOME/.gitconfig-personal"
cp "$REPO_DIR/dotfiles/gitconfig-work"       "$HOME/.gitconfig-work"

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
cp "$REPO_DIR/dotfiles/gtk3-settings.ini"    "$HOME/.config/gtk-3.0/settings.ini"
cp "$REPO_DIR/dotfiles/gtk4-settings.ini"    "$HOME/.config/gtk-4.0/settings.ini"

# ── Doom Emacs ───────────────────────────────────────────────────────
if [ ! -d "$HOME/.emacs.d" ]; then
  info "Instalando Doom Emacs..."
  git clone --depth 1 https://github.com/doomemacs/doomemacs "$HOME/.emacs.d"
  "$HOME/.emacs.d/bin/doom" install --no-env --fonts
else
  warn "~/.emacs.d ya existe — corré 'doom sync' manual si hace falta"
fi

# ── Temas GTK Gruvbox ────────────────────────────────────────────────
info "Instalando temas Gruvbox..."
mkdir -p "$HOME/.themes"
cp -r "$REPO_DIR/themes/Gruvbox-Dark"  "$HOME/.themes/"
cp -r "$REPO_DIR/themes/Gruvbox-Light" "$HOME/.themes/"

# ── Wallpapers activos ───────────────────────────────────────────────
info "Copiando wallpapers activos..."
mkdir -p "$HOME/Pictures/Wallpapers"
cp "$REPO_DIR/wallpapers/"* "$HOME/Pictures/Wallpapers/"

# ── Systemd user units ───────────────────────────────────────────────
info "Habilitando systemd user units..."
systemctl --user daemon-reload
for u in hyprpaper quickshell monitor-watcher; do
  systemctl --user enable "$u.service"
done
# syncthing runs headless (password vault sync) — enable-linger keeps the
# user manager, and with it the unit, alive without a login session.
systemctl --user enable syncthing.service
sudo loginctl enable-linger "$USER"


# ── Grupos ───────────────────────────────────────────────────────────
info "Agregando usuario a grupos..."
sudo usermod -aG video,input "$USER"

# ── Greetd ───────────────────────────────────────────────────────────
if [ ! -f /etc/greetd/config.toml ]; then
  info "Configurando greetd..."
  sudo tee /etc/greetd/config.toml >/dev/null <<'GREETD'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --asterisks --greeting 'gruvbox' --theme 'border=yellow;text=white;prompt=yellow;time=cyan;greet=yellow;action=magenta;button=yellow;container=black;input=white' --cmd 'uwsm start -e -D Hyprland hyprland.desktop'"
user = "greeter"
GREETD
  sudo systemctl enable greetd.service
fi

# ── Kernel cmdline: Gruvbox TTY colors ───────────────────────────────
info "Agregando colores Gruvbox a la TTY (kernel cmdline)..."
GRUVBOX_RED="vt.default_red=0x28,0xcc,0x98,0xd7,0x45,0xb1,0x68,0xa8,0x92,0xfb,0xb8,0xfa,0x83,0xd3,0x8e,0xeb"
GRUVBOX_GRN="vt.default_grn=0x28,0x24,0x97,0x99,0x85,0x62,0x9d,0x99,0x83,0x49,0xbb,0xbd,0xa5,0x86,0xc0,0xdb"
GRUVBOX_BLU="vt.default_blu=0x28,0x1d,0x1a,0x21,0x88,0x86,0x6a,0x84,0x74,0x34,0x26,0x2f,0x98,0x9b,0x7c,0xb2"
CURRENT=$(cat /proc/cmdline 2>/dev/null || echo "")
if echo "$CURRENT" | grep -q "vt.default_red"; then
  warn "vt.default_red ya está en cmdline — skipeando (revisá manual si querés actualizar)"
else
  if [ -f /etc/default/grub ]; then
    sudo sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"/&$GRUVBOX_RED $GRUVBOX_GRN $GRUVBOX_BLU /" /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || warn "No se pudo regenerar grub.cfg"
  elif command -v sdboot-manage &>/dev/null; then
    warn "systemd-boot detectado — agregá los vt.default_* manualmente"
    echo "  $GRUVBOX_RED"
    echo "  $GRUVBOX_GRN"
    echo "  $GRUVBOX_BLU"
  else
    warn "No se detectó grub ni systemd-boot — agregá manual:"
    echo "  $GRUVBOX_RED"
    echo "  $GRUVBOX_GRN"
    echo "  $GRUVBOX_BLU"
  fi
fi

# ── Post-install ─────────────────────────────────────────────────────
echo ""
info "┌──────────────────────────────────────────────────────────────┐"
info "│  Instalación completada                                      │"
info "├──────────────────────────────────────────────────────────────┤"
info "│  ✓ Paquetes (267 oficial + 8 AUR)                           │"
info "│  ✓ Symlinks: hypr / quickshell / systemd / uwsm             │"
info "│  ✓ Dotfiles: bashrc, gitconfig, gtk                         │"
info "│  ✓ Temas Gruvbox + wallpapers activos                       │"
info "│  ✓ Systemd units habilitados                                │"
info "│  ✓ greetd configurado                                       │"
info "├──────────────────────────────────────────────────────────────┤"
info "│  Pendiente manual:                                          │"
info "│  • editá hypr/monitors.conf para tus monitores              │"
info "│  • ajustá /etc/greetd/config.toml si es necesario           │"
info "│  • si usás systemd-boot, agregá vt.default_* al cmdline     │"
info "│  • para desktops: ignorá warnings de Battery/Brightness     │"
info "│  • copiá el resto de wallpapers si tenés backup             │"
info "│    (~/Pictures/Wallpapers/ completo)                        │"
info "└──────────────────────────────────────────────────────────────┘"
info "Reiniciá con: sudo systemctl reboot"
