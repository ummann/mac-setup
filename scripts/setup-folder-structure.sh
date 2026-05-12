#!/bin/bash

# =============================================================================
# Setup Folder Structure — estructura estándar de carpetas
# =============================================================================
# Crea las carpetas canónicas donde viven los archivos reales del workspace:
#   ~/projects/                       repos de código
#   ~/brand-assets/{ummove,ummann,    logos y assets por marca
#                   varios,clientes}
#   ~/Pictures/Capturas/              screenshots organizadas
#   ~/Documents/Fiscal/{FIEL,...}     contratos, FIEL SAT, acuses
#
# Idempotente: usa mkdir -p, no sobreescribe.
# =============================================================================

set -e

GREEN='\033[0;32m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

FOLDERS=(
  "$HOME/projects"
  "$HOME/brand-assets/ummove"
  "$HOME/brand-assets/ummann"
  "$HOME/brand-assets/varios"
  "$HOME/brand-assets/clientes"
  "$HOME/Pictures/Capturas/Simulator"
  "$HOME/Documents/Fiscal/FIEL"
)

echo ""
log_info "Creando estructura de carpetas estándar..."
echo ""

# brand-assets puede estar como read-only si fue creado con tar/restore
if [ -d "$HOME/brand-assets" ] && [ ! -w "$HOME/brand-assets" ]; then
  chmod u+w "$HOME/brand-assets"
  log_info "Permiso write agregado a ~/brand-assets/"
fi

for folder in "${FOLDERS[@]}"; do
  if [ -d "$folder" ]; then
    log_info "Ya existe: $folder"
  else
    mkdir -p "$folder"
    log_info "Creado: $folder"
  fi
done

echo ""
log_info "Estructura de carpetas lista."
echo ""
