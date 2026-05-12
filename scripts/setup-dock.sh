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

# Lista de apps fijas en el Dock. Cada entrada es un path absoluto a .app.
# Notas:
# - System Settings vive en /System/Applications/ (no /Applications/)
# - cmux y otras apps que corren todo el día NO van fijas: cuando corren ya
#   aparecen en el Dock por sí solas, fijarlas causa duplicación visible.
DOCK_APPS=(
  "/Applications/Raycast.app"
  "/Applications/Google Chrome.app"
  "/Applications/Warp.app"
  "/Applications/Cursor.app"
  "/Applications/Obsidian.app"
  "/Applications/Figma.app"
  "/System/Applications/System Settings.app"
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
for app_path in "${DOCK_APPS[@]}"; do
  if [ -d "$app_path" ]; then
    defaults write com.apple.dock persistent-apps -array-add \
      "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>${app_path}/</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
    log_info "Agregado: $(basename "$app_path" .app)"
  else
    log_skip "$app_path no encontrado"
  fi
done

# Aplicar
killall Dock 2>/dev/null && log_info "Dock reiniciado" || log_warn "No se pudo reiniciar Dock"

echo ""
log_info "Dock listo con ${#DOCK_APPS[@]} apps premium."
log_warn "Si no te gusta, revierte con:"
echo "  cp $BACKUP_PATH $DOCK_PLIST && killall Dock"
echo ""
