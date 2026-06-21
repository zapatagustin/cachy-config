#!/bin/bash
# set-theme.sh — cambia el tema del sistema
# Uso: set-theme.sh dark|light

GTK_DARK="Gruvbox-Dark"
GTK_LIGHT="Gruvbox-Light"
ICON_DARK="Papirus-Dark"
ICON_LIGHT="Papirus-Light"
CURSOR_THEME="Adwaita"

# ── Detectar modo ──────────────────────────────────────────────────────────
MODE="${1:-dark}"
if [ "$MODE" != "dark" ] && [ "$MODE" != "light" ]; then
    MODE="dark"
fi

# ── Cache: si no cambió nada, solo re-notificar a Quickshell y salir ───────
# (Quickshell resetea isDark al reiniciar, así que siempre debe recibir el modo
#  actual aunque el resto del sistema ya lo tenga aplicado)
CACHE="/tmp/current-theme-mode"
if [ "$(cat "$CACHE" 2>/dev/null)" = "$MODE" ]; then
    echo "$MODE" > /tmp/qs-theme
    exit 0
fi
echo "$MODE" > "$CACHE"

# ── Seleccionar valores ────────────────────────────────────────────────────
if [ "$MODE" = "dark" ]; then
    GTK_THEME="$GTK_DARK"
    ICON_THEME="$ICON_DARK"
    COLOR_SCHEME="prefer-dark"
    PREFER_DARK=1
    BORDER_ACTIVE="rgba(fabd2fff)"
    BORDER_INACTIVE="rgba(504945ff)"
else
    GTK_THEME="$GTK_LIGHT"
    ICON_THEME="$ICON_LIGHT"
    COLOR_SCHEME="prefer-light"
    PREFER_DARK=0
    BORDER_ACTIVE="rgba(b57614ff)"
    BORDER_INACTIVE="rgba(d5c4a1ff)"
fi

# ── GTK 3 + 4 (un solo write por archivo) ─────────────────────────────────
GTK_SETTINGS="[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=$PREFER_DARK"

mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
echo "$GTK_SETTINGS" > ~/.config/gtk-3.0/settings.ini
echo "$GTK_SETTINGS" > ~/.config/gtk-4.0/settings.ini

# ── gsettings (apps GTK vivas) ────────────────────────────────────────────
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme        "$GTK_THEME"    2>/dev/null
    gsettings set org.gnome.desktop.interface icon-theme       "$ICON_THEME"   2>/dev/null
    gsettings set org.gnome.desktop.interface color-scheme     "$COLOR_SCHEME" 2>/dev/null
fi

# ── Hyprland ──────────────────────────────────────────────────────────────
if command -v hyprctl &>/dev/null; then
    hyprctl setcursor "$CURSOR_THEME" 24 2>/dev/null
    hyprctl keyword general:col.active_border   "$BORDER_ACTIVE"   2>/dev/null
    hyprctl keyword general:col.inactive_border "$BORDER_INACTIVE" 2>/dev/null
fi

# ── Notificar a Quickshell ─────────────────────────────────────────────────
echo "$MODE" > /tmp/qs-theme
