#!/usr/bin/env bash
# restore-services.sh — restaura el bundle generado por backup-services.sh.
# Corre DESPUÉS de setup.sh + setup-shell.sh + restore-new-mac.sh.
#
# Uso: ./scripts/restore-services.sh ~/mac-migration/

set -euo pipefail

BACKUP_DIR="${1:-$HOME/mac-migration}"
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

log()  { echo -e "${COLOR_BLUE}[$(date +%H:%M:%S)]${COLOR_RESET} $*"; }
ok()   { echo -e "${COLOR_GREEN}✓${COLOR_RESET} $*"; }
warn() { echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $*"; }
err()  { echo -e "${COLOR_RED}✗${COLOR_RESET} $*"; }

confirm() {
  read -r -p "$1 [y/N]: " response
  [[ "$response" =~ ^[Yy]$ ]]
}

# ====== PRE-FLIGHT ======
if [ ! -f "$BACKUP_DIR/services.tar.gz.gpg" ]; then
  err "No se encontró $BACKUP_DIR/services.tar.gz.gpg"
  exit 1
fi

for cmd in gpg rsync; do
  command -v "$cmd" >/dev/null 2>&1 || { err "$cmd no instalado"; exit 1; }
done

# ====== DESCIFRAR ======
read -r -s -p "Passphrase del backup: " PASSPHRASE
echo

TMPDIR=$(mktemp -d)
trap "rm -rf '$TMPDIR'; unset PASSPHRASE" EXIT

log "Descifrando services.tar.gz..."
gpg --batch --yes --passphrase "$PASSPHRASE" \
  --decrypt "$BACKUP_DIR/services.tar.gz.gpg" 2>/dev/null | \
  tar -xzf - -C "$TMPDIR"

if [ ! -d "$TMPDIR/services-staging" ]; then
  err "Passphrase incorrecta o backup corrupto"
  exit 1
fi

STAGING="$TMPDIR/services-staging"
ok "Descifrado"

# ====== 1. LAUNCHAGENTS ======
log "Restaurando LaunchAgents..."

if [ -d "$STAGING/launchagents" ]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  for plist in "$STAGING/launchagents"/*.plist; do
    [ -f "$plist" ] || continue
    base=$(basename "$plist")
    dest="$HOME/Library/LaunchAgents/$base"
    if [ -f "$dest" ]; then
      warn "  $base existe — backup como .pre-migration"
      cp "$dest" "$dest.pre-migration"
    fi
    cp "$plist" "$dest"
    ok "  $base"
  done

  warn "  Los daemons NO se cargan automáticamente — corre al final:"
  warn "    for f in ~/Library/LaunchAgents/com.nemo.*.plist; do launchctl load \"\$f\"; done"
fi

# ====== 2. POSTGRES ======
log "Restaurando bases de datos Postgres..."

PG_RESTORE=""
PSQL=""
for candidate in /opt/homebrew/opt/postgresql@16/bin \
                 /opt/homebrew/opt/postgresql@17/bin \
                 /usr/local/opt/postgresql@16/bin; do
  if [ -x "$candidate/pg_restore" ]; then
    PG_RESTORE="$candidate/pg_restore"
    PSQL="$candidate/psql"
    break
  fi
done
[ -z "$PG_RESTORE" ] && PG_RESTORE=$(command -v pg_restore 2>/dev/null || echo "")
[ -z "$PSQL" ] && PSQL=$(command -v psql 2>/dev/null || echo "")

if [ -z "$PG_RESTORE" ] || [ -z "$PSQL" ]; then
  warn "  pg_restore no disponible — saltando Postgres. Instala con: brew install postgresql@16"
elif ! "$PSQL" -c "SELECT 1" >/dev/null 2>&1; then
  warn "  Postgres no está corriendo. Inicia con: brew services start postgresql@16"
else
  # Restaurar globals (roles)
  if [ -f "$STAGING/postgres/_globals.sql" ] && confirm "  Restaurar roles/globals?"; then
    "$PSQL" -f "$STAGING/postgres/_globals.sql" >/dev/null 2>&1 && ok "  globals" || warn "  fallo globals"
  fi

  # Restaurar cada DB
  for dump in "$STAGING/postgres"/*.dump; do
    [ -f "$dump" ] || continue
    db=$(basename "$dump" .dump)

    # Si la DB ya existe, preguntar
    if "$PSQL" -tAc "SELECT 1 FROM pg_database WHERE datname='$db'" 2>/dev/null | grep -q 1; then
      if ! confirm "  DB '$db' ya existe — sobrescribir?"; then
        warn "    saltado: $db"
        continue
      fi
      "$PSQL" -c "DROP DATABASE \"$db\"" 2>/dev/null
    fi

    log "  pg_restore $db..."
    "$PSQL" -c "CREATE DATABASE \"$db\"" 2>/dev/null
    "$PG_RESTORE" -d "$db" --no-owner --no-privileges "$dump" 2>/dev/null && \
      ok "    $db" || warn "    fallo (parcial?) $db"
  done
fi

# ====== 3. REDIS ======
log "Restaurando Redis dump.rdb..."

REDIS_DEST=""
for candidate in /opt/homebrew/var/db/redis /usr/local/var/db/redis; do
  if [ -d "$candidate" ]; then
    REDIS_DEST="$candidate/dump.rdb"
    break
  fi
done

if [ -f "$STAGING/state/redis-dump.rdb" ] && [ -n "$REDIS_DEST" ]; then
  if pgrep -f redis-server >/dev/null 2>&1; then
    warn "  Redis está corriendo — para restaurar, párenlo primero:"
    warn "    brew services stop redis"
    if confirm "  ¿Pararlo ahora y restaurar?"; then
      brew services stop redis 2>/dev/null
      cp "$STAGING/state/redis-dump.rdb" "$REDIS_DEST"
      brew services start redis 2>/dev/null
      ok "  Redis restaurado y reiniciado"
    fi
  else
    cp "$STAGING/state/redis-dump.rdb" "$REDIS_DEST"
    ok "  Redis dump.rdb"
  fi
fi

# ====== 4. STATE DIRS ======
log "Restaurando state dirs..."

# cmux
if [ -d "$STAGING/state/cmux" ]; then
  dest="$HOME/Library/Application Support/cmux"
  mkdir -p "$dest"
  rsync -a "$STAGING/state/cmux/" "$dest/" 2>/dev/null && ok "  cmux state" || warn "  fallo cmux"
fi

# uwl
if [ -d "$STAGING/state/uwl" ]; then
  rsync -a "$STAGING/state/uwl/" "$HOME/.uwl/" 2>/dev/null && ok "  uwl state" || warn "  fallo uwl"
fi

# whatsapp-mcp
if [ -d "$STAGING/state/whatsapp-mcp" ]; then
  dest="$HOME/projects/whatsapp-mcp/whatsapp-bridge/store"
  if [ -d "$(dirname "$dest")" ]; then
    mkdir -p "$dest"
    cp "$STAGING/state/whatsapp-mcp"/*.db "$dest/" 2>/dev/null && ok "  whatsapp-mcp DBs" || warn "  fallo whatsapp-mcp"
  else
    warn "  ~/projects/whatsapp-mcp no existe — clona el repo primero"
  fi
fi

# ====== 5. CARGAR LAUNCHAGENTS ======
echo
if confirm "Cargar todos los LaunchAgents ahora (arranca los daemons)?"; then
  for f in "$HOME/Library/LaunchAgents"/com.nemo.*.plist \
           "$HOME/Library/LaunchAgents"/com.ummann.*.plist \
           "$HOME/Library/LaunchAgents"/ai.ummann.*.plist; do
    [ -f "$f" ] || continue
    label=$(basename "$f" .plist)
    launchctl unload "$f" 2>/dev/null || true
    launchctl load "$f" 2>/dev/null && ok "  loaded $label" || warn "  fallo $label"
  done
fi

# ====== RESUMEN ======
echo
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_GREEN}✅ Services restaurados${COLOR_RESET}"
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo
echo "Verificar daemons:"
echo "  launchctl list | grep -E 'nemo|ummann'"
echo "  curl http://localhost:3100/health   # nemo-api"
echo
echo "Logs:"
echo "  tail -f ~/Library/Logs/nemo/api.log"
echo
echo "Si un daemon falla, revisa $STAGING/state/_runtime-snapshot.txt para comparar puertos/binarios."
