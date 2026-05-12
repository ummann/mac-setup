#!/bin/bash

# =============================================================================
# Setup Desktop Dashboard — symlinks a carpetas reales
# =============================================================================
# El Desktop NO debe quedar vacío. Convertirlo en dashboard con symlinks a:
#   ~/projects/         → Projects
#   /Applications/      → Apps
#   ~/brand-assets/     → Brand
#   ~/Documents/        → Docs
#   ~/Pictures/Capturas → Capturas
#   ~/Downloads/        → Downloads
#
# Los archivos viven en sus carpetas reales. El Desktop solo es ventana de acceso.
# Idempotente: si el symlink ya existe, lo recrea.
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

declare -a LINKS=(
  "Projects:$HOME/projects"
  "Apps:/Applications"
  "Brand:$HOME/brand-assets"
  "Docs:$HOME/Documents"
  "Capturas:$HOME/Pictures/Capturas"
  "Downloads:$HOME/Downloads"
)

echo ""
log_info "Configurando Desktop dashboard..."
echo ""

for entry in "${LINKS[@]}"; do
  name="${entry%%:*}"
  target="${entry#*:}"
  link_path="$HOME/Desktop/$name"

  if [ ! -e "$target" ]; then
    log_warn "Target no existe: $target — skip $name"
    continue
  fi

  if [ -L "$link_path" ]; then
    rm "$link_path"
  elif [ -e "$link_path" ]; then
    log_warn "$link_path existe y NO es symlink — skip (no sobreescribir)"
    continue
  fi

  ln -s "$target" "$link_path"
  log_info "$name → $target"
done

echo ""
log_info "Desktop dashboard listo."
echo ""
