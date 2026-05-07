#!/usr/bin/env bash
# install-nemo-backup.sh — instala el LaunchAgent que respalda la DB nemo a diario.
#
# Uso: ./scripts/install-nemo-backup.sh
# Requiere: pg_dump + openssl + mac-setup clonado en ~/projects/mac-setup

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_PATH="$REPO_DIR/scripts/backup-nemo-db.sh"
PLIST_TEMPLATE="$REPO_DIR/launchagents/com.ummann.nemo-backup.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.ummann.nemo-backup.plist"
KEYCHAIN_SERVICE="nemo-backup"

COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

ok()   { echo -e "${COLOR_GREEN}✓${COLOR_RESET} $*"; }
warn() { echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $*"; }
err()  { echo -e "${COLOR_RED}✗${COLOR_RESET} $*"; }

# ====== PRE-FLIGHT ======
if [ ! -f "$SCRIPT_PATH" ]; then
  err "No se encontró $SCRIPT_PATH"
  exit 1
fi

if [ ! -f "$PLIST_TEMPLATE" ]; then
  err "No se encontró $PLIST_TEMPLATE"
  exit 1
fi

chmod +x "$SCRIPT_PATH"

# ====== KEYCHAIN ======
echo "Configurando passphrase en macOS Keychain..."
EXISTING=$(security find-generic-password -a "$USER" -s "$KEYCHAIN_SERVICE" -w 2>/dev/null || echo "")

if [ -n "$EXISTING" ]; then
  ok "Passphrase ya existe en Keychain (servicio: $KEYCHAIN_SERVICE)"
else
  echo "  Necesitas elegir una passphrase para cifrar los dumps."
  echo "  ⚠  Anótala en un password manager — sin ella los backups son inservibles."
  echo
  while true; do
    read -r -s -p "Passphrase: " PP1
    echo
    read -r -s -p "Confirma: " PP2
    echo
    if [ "$PP1" = "$PP2" ] && [ -n "$PP1" ]; then
      break
    fi
    warn "  No coinciden o vacía, intenta de nuevo"
  done

  security add-generic-password -a "$USER" -s "$KEYCHAIN_SERVICE" -w "$PP1"
  unset PP1 PP2
  ok "Passphrase guardada en Keychain"
fi

# ====== INSTALAR PLIST ======
echo "Instalando LaunchAgent..."

# Sustituir placeholders en el template
sed -e "s|__SCRIPT_PATH__|$SCRIPT_PATH|g" \
    -e "s|__HOME__|$HOME|g" \
    "$PLIST_TEMPLATE" > "$PLIST_DEST"

ok "Plist instalado en $PLIST_DEST"

# Cargar (o recargar)
if launchctl list | grep -q "com.ummann.nemo-backup"; then
  launchctl unload "$PLIST_DEST" 2>/dev/null || true
fi
launchctl load "$PLIST_DEST"
ok "LaunchAgent cargado — corre cada día a las 05:15"

# ====== TEST RUN ======
echo
read -r -p "¿Ejecutar el backup ahora para validar? [y/N]: " RUN_NOW
if [[ "$RUN_NOW" =~ ^[Yy]$ ]]; then
  echo "Ejecutando $SCRIPT_PATH..."
  if "$SCRIPT_PATH"; then
    ok "Backup de prueba exitoso"
    echo
    ls -la "$HOME/nemo-backups/" 2>/dev/null | tail -3
  else
    err "Backup falló — revisa $HOME/Library/Logs/nemo-backup.log"
  fi
fi

# ====== RESUMEN ======
echo
echo "Verificar:"
echo "  launchctl list | grep nemo-backup"
echo "  tail -f ~/Library/Logs/nemo-backup.log"
echo
echo "Backups locales:   ~/nemo-backups/"
echo "Backups iCloud:    ~/Library/Mobile Documents/com~apple~CloudDocs/Nemo/db-backups/"
echo
echo "Forzar backup ahora: $SCRIPT_PATH"
echo "Desinstalar: launchctl unload $PLIST_DEST && rm $PLIST_DEST"
echo "Borrar passphrase: security delete-generic-password -a \"$USER\" -s \"$KEYCHAIN_SERVICE\""
