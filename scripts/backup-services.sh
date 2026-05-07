#!/usr/bin/env bash
# backup-services.sh — empaqueta LaunchAgents, DBs (Postgres/Redis/SQLite) y
# state runtime (cmux, uwl). Complementa backup-old-mac.sh.
#
# Uso: ./scripts/backup-services.sh [BACKUP_DIR]
# Default BACKUP_DIR: ~/mac-migration

set -euo pipefail

BACKUP_DIR="${1:-$HOME/mac-migration}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

log()  { echo -e "${COLOR_BLUE}[$(date +%H:%M:%S)]${COLOR_RESET} $*"; }
ok()   { echo -e "${COLOR_GREEN}✓${COLOR_RESET} $*"; }
warn() { echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $*"; }
err()  { echo -e "${COLOR_RED}✗${COLOR_RESET} $*"; }

if ! command -v gpg >/dev/null 2>&1; then
  err "gpg no instalado: brew install gnupg"
  exit 1
fi

mkdir -p "$BACKUP_DIR"/{services-staging,services-staging/launchagents,services-staging/postgres,services-staging/state}
STAGING="$BACKUP_DIR/services-staging"

log "Backup de services en $BACKUP_DIR"

# ====== 1. LAUNCHAGENTS (.plist) ======
log "Copiando ~/Library/LaunchAgents/*.plist relevantes..."

# Filtros: lo de UMMANN, nemo, brew services y cloudflare. Excluye Google/Microsoft updaters.
PLIST_PATTERNS=(
  "ai.ummann.*"
  "com.nemo.*"
  "com.ummann.*"
  "com.cloudflare.*"
  "homebrew.mxcl.*"
  "com.lwouis.alt-tab-macos.plist"
)

for pattern in "${PLIST_PATTERNS[@]}"; do
  for f in "$HOME/Library/LaunchAgents"/$pattern; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    # Saltar .bak files
    [[ "$base" == *.bak ]] && continue
    cp "$f" "$STAGING/launchagents/$base"
    ok "  $base"
  done
done

# Manifest de servicios activos
brew services list 2>/dev/null > "$STAGING/launchagents/_brew-services-state.txt" || true

# ====== 2. POSTGRES — pg_dump por DB ======
log "Dumpeando bases de datos Postgres..."

# Detectar binarios postgres (Apple Silicon vs Intel)
PG_DUMP=""
for candidate in /opt/homebrew/opt/postgresql@16/bin/pg_dump \
                 /opt/homebrew/opt/postgresql@17/bin/pg_dump \
                 /usr/local/opt/postgresql@16/bin/pg_dump \
                 $(command -v pg_dump 2>/dev/null); do
  if [ -x "$candidate" ]; then
    PG_DUMP="$candidate"
    break
  fi
done

if [ -z "$PG_DUMP" ]; then
  warn "  pg_dump no encontrado — saltando Postgres"
else
  PSQL="${PG_DUMP%/pg_dump}/psql"
  # Listar DBs (excluir templates y postgres default)
  DBS=$("$PSQL" -tAc "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';" 2>/dev/null || echo "")
  for db in $DBS; do
    [ -z "$db" ] && continue
    log "  pg_dump $db..."
    if "$PG_DUMP" -Fc -f "$STAGING/postgres/$db.dump" "$db" 2>/dev/null; then
      size=$(du -h "$STAGING/postgres/$db.dump" | awk '{print $1}')
      ok "    $db ($size)"
    else
      warn "    fallo $db"
    fi
  done

  # Globals (roles, tablespaces) — útil para restore
  PG_DUMPALL="${PG_DUMP%/pg_dump}/pg_dumpall"
  if [ -x "$PG_DUMPALL" ]; then
    "$PG_DUMPALL" --globals-only -f "$STAGING/postgres/_globals.sql" 2>/dev/null && \
      ok "  globals (roles)" || warn "  fallo globals"
  fi
fi

# ====== 3. REDIS dump.rdb ======
log "Copiando Redis dump.rdb..."

REDIS_DUMP=""
for candidate in /opt/homebrew/var/db/redis/dump.rdb \
                 /usr/local/var/db/redis/dump.rdb; do
  if [ -f "$candidate" ]; then
    REDIS_DUMP="$candidate"
    break
  fi
done

if [ -n "$REDIS_DUMP" ]; then
  cp "$REDIS_DUMP" "$STAGING/state/redis-dump.rdb"
  ok "  redis dump.rdb"
else
  warn "  Redis dump.rdb no encontrado"
fi

# Trigger BGSAVE para asegurar dump fresco (no destructivo)
if command -v redis-cli >/dev/null 2>&1; then
  redis-cli BGSAVE 2>/dev/null > "$STAGING/state/_redis-bgsave.log" || true
fi

# ====== 4. STATE DIRECTORIES ======
log "Copiando state dirs (cmux, uwl, whatsapp-mcp)..."

# cmux
if [ -d "$HOME/Library/Application Support/cmux" ]; then
  # Excluir el socket (no transferible)
  rsync -a --exclude='cmux.sock' \
    "$HOME/Library/Application Support/cmux/" \
    "$STAGING/state/cmux/" 2>/dev/null && ok "  cmux state" || warn "  fallo cmux"
fi

# uwl
if [ -d "$HOME/.uwl" ]; then
  rsync -a "$HOME/.uwl/" "$STAGING/state/uwl/" 2>/dev/null && ok "  uwl state" || warn "  fallo uwl"
fi

# whatsapp-mcp DBs
if [ -d "$HOME/projects/whatsapp-mcp/whatsapp-bridge/store" ]; then
  mkdir -p "$STAGING/state/whatsapp-mcp"
  cp "$HOME/projects/whatsapp-mcp/whatsapp-bridge/store"/*.db \
    "$STAGING/state/whatsapp-mcp/" 2>/dev/null && \
    ok "  whatsapp-mcp DBs" || warn "  fallo whatsapp-mcp"
fi

# ====== 5. MANIFEST DE SYMLINKS Y BINARIOS ======
log "Listando symlinks y binarios custom..."

{
  echo "# Custom binaries en /usr/local/bin (probablemente symlinks al monorepo)"
  ls -la /usr/local/bin/ 2>/dev/null | grep -E "ummann|nemo|cmux" || echo "ninguno"
  echo
  echo "# Procesos activos relevantes (al momento del backup)"
  ps aux | grep -iE "nemo|whatsapp-bridge|cloudflared" | grep -v grep | awk '{print $11, $12, $13}'
  echo
  echo "# Puertos en uso"
  lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk '{print $1, $9}' | sort -u | grep -vE "COMMAND|^$"
} > "$STAGING/state/_runtime-snapshot.txt"

ok "  snapshot generado"

# ====== 6. CIFRAR ======
log "Cifrando services.tar.gz..."
echo
read -r -s -p "Passphrase para cifrar (usa la misma del backup principal): " PASSPHRASE
echo

tar -czf - -C "$BACKUP_DIR" services-staging | \
  gpg --batch --yes --passphrase "$PASSPHRASE" --symmetric --cipher-algo AES256 \
  -o "$BACKUP_DIR/services.tar.gz.gpg"

rm -rf "$STAGING"
unset PASSPHRASE

# Append checksum
shasum -a 256 "$BACKUP_DIR/services.tar.gz.gpg" >> "$BACKUP_DIR/checksums.sha256" 2>/dev/null || \
  shasum -a 256 "$BACKUP_DIR/services.tar.gz.gpg" > "$BACKUP_DIR/checksums.sha256"

# ====== RESUMEN ======
echo
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_GREEN}✅ Services backup en $BACKUP_DIR/services.tar.gz.gpg${COLOR_RESET}"
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo
du -h "$BACKUP_DIR/services.tar.gz.gpg"
echo
echo "Contenido: LaunchAgents, pg_dumps, redis dump.rdb, cmux + uwl state, whatsapp-mcp DBs"
echo "Restaurar con: ./scripts/restore-services.sh $BACKUP_DIR/"
