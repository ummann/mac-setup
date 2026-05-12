#!/bin/bash

# =============================================================================
# Setup Dock — apps premium para dev
# =============================================================================
# Limpia las apps fijas del Dock y deja solo el set premium.
# Idempotente: puede correrse múltiples veces.
# Backup automático del plist antes de modificar.
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; }

DOCK_APPS=(
  "Raycast"
  "Google Chrome"
  "Warp"
  "cmux"
  "Cursor"
  "Granola"
  "Obsidian"
  "Figma"
  "Ajustes del Sistema"
)

DOCK_PLIST="$HOME/Library/Preferences/com.apple.dock.plist"
BACKUP_PATH="${DOCK_PLIST}.backup-$(date +%Y-%m-%d)"

echo ""
log_info "Configurando Dock premium..."
echo ""

# Backup
if [ -f "$DOCK_PLIST" ]; then
  cp "$DOCK_PLIST" "$BACKUP_PATH"
  log_info "Backup: $BACKUP_PATH"
fi

# Limpiar apps actuales
defaults delete com.apple.dock persistent-apps 2>/dev/null || true

# Agregar cada app si existe
for app in "${DOCK_APPS[@]}"; do
  app_path="/Applications/${app}.app"
  if [ -d "$app_path" ]; then
    defaults write com.apple.dock persistent-apps -array-add \
      "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>${app_path}/</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
    log_info "Agregado: $app"
  else
    log_skip "$app no instalado en /Applications/"
  fi
done

# Aplicar
killall Dock 2>/dev/null && log_info "Dock reiniciado" || log_warn "No se pudo reiniciar Dock"

echo ""
log_info "Dock listo con ${#DOCK_APPS[@]} apps premium."
log_warn "Si no te gusta, revierte con:"
echo "  cp $BACKUP_PATH $DOCK_PLIST && killall Dock"
echo ""
