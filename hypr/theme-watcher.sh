#!/bin/bash
# theme-watcher.sh — demonio liviano de auto-tema
# Corre set-theme.sh solo cuando cambia la hora relevante

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SET_THEME="$SCRIPT_DIR/set-theme.sh"

# Aplicar tema inmediatamente al iniciar
bash "$SET_THEME" auto

# Loop: dormir hasta el próximo minuto exacto para sincronizar bien
while true; do
    # Calcular segundos hasta el próximo minuto
    SECS=$(date +%S)
    SLEEP=$((61 - 10#$SECS))  # +1s de margen
    sleep "$SLEEP"
    bash "$SET_THEME" auto
done
