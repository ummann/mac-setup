#!/usr/bin/env bash
# backup-nemo-db.sh — pg_dump diario de la DB nemo, cifrado y copiado a iCloud.
# Pensado para ejecutarse desde un LaunchAgent (com.ummann.nemo-backup.plist).
#
# Uso manual: ./scripts/backup-nemo-db.sh
# Pre-requisito: passphrase guardada en macOS Keychain con servicio "nemo-backup":
#   security add-generic-password -a "$USER" -s "nemo-backup" -w "TU_PASSPHRASE"

set -uo pipefail

# ====== CONFIG ======
DB_NAME="nemo"
LOCAL_DIR="$HOME/nemo-backups"
ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Nemo/db-backups"
LOG_FILE="$HOME/Library/Logs/nemo-backup.log"
KEYCHAIN_SERVICE="nemo-backup"
LOCAL_RETENTION_DAYS=14
ICLOUD_RETENTION_DAYS=90
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$LOCAL_DIR" "$(dirname "$LOG_FILE")"

# Si iCloud Drive no está disponible (offline / sin sesión), seguimos con local-only.
ICLOUD_AVAILABLE=0
if [ -d "$(dirname "$ICLOUD_DIR")" ]; then
  mkdir -p "$ICLOUD_DIR" 2>/dev/null && ICLOUD_AVAILABLE=1
fi

# ====== LOGGING ======
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$msg" | tee -a "$LOG_FILE"
}

log "===== nemo backup start ($TIMESTAMP) ====="

# ====== POSTGRES BIN ======
PG_DUMP=""
for candidate in /opt/homebrew/opt/postgresql@16/bin/pg_dump \
                 /opt/homebrew/opt/postgresql@17/bin/pg_dump \
                 /usr/local/opt/postgresql@16/bin/pg_dump; do
  if [ -x "$candidate" ]; then
    PG_DUMP="$candidate"
    break
  fi
done
[ -z "$PG_DUMP" ] && PG_DUMP=$(command -v pg_dump 2>/dev/null || echo "")

if [ -z "$PG_DUMP" ]; then
  log "ERROR: pg_dump no encontrado"
  exit 1
fi

PSQL="${PG_DUMP%/pg_dump}/psql"

# Verificar que la DB existe y postgres responde
if ! "$PSQL" -d "$DB_NAME" -c "SELECT 1" >/dev/null 2>&1; then
  log "ERROR: no se puede conectar a DB $DB_NAME (¿postgres corriendo?)"
  exit 1
fi

# ====== PASSPHRASE DESDE KEYCHAIN ======
PASSPHRASE=$(security find-generic-password -a "$USER" -s "$KEYCHAIN_SERVICE" -w 2>/dev/null || echo "")

if [ -z "$PASSPHRASE" ]; then
  log "ERROR: passphrase no encontrada en Keychain (servicio: $KEYCHAIN_SERVICE)"
  log "  Configúrala con: security add-generic-password -a \"$USER\" -s \"$KEYCHAIN_SERVICE\" -w \"TU_PASSPHRASE\""
  exit 1
fi

# ====== DUMP + CIFRADO ======
DUMP_FILE="$LOCAL_DIR/nemo-$TIMESTAMP.dump"
ENC_FILE="$DUMP_FILE.enc"

log "pg_dump..."
if ! "$PG_DUMP" -Fc -f "$DUMP_FILE" "$DB_NAME" 2>>"$LOG_FILE"; then
  log "ERROR: pg_dump falló"
  unset PASSPHRASE
  exit 1
fi

DUMP_SIZE=$(du -h "$DUMP_FILE" | awk '{print $1}')
log "  dump generado: $DUMP_SIZE"

log "cifrando..."
if ! openssl enc -aes-256-cbc -pbkdf2 -salt \
  -in "$DUMP_FILE" -out "$ENC_FILE" \
  -pass pass:"$PASSPHRASE" 2>>"$LOG_FILE"; then
  log "ERROR: openssl falló"
  rm -f "$DUMP_FILE"
  unset PASSPHRASE
  exit 1
fi

# Borrar el .dump sin cifrar inmediatamente
rm -f "$DUMP_FILE"
unset PASSPHRASE

ENC_SIZE=$(du -h "$ENC_FILE" | awk '{print $1}')
log "  cifrado: $ENC_SIZE"

# ====== COPIAR A iCLOUD ======
if [ "$ICLOUD_AVAILABLE" = "1" ]; then
  if cp "$ENC_FILE" "$ICLOUD_DIR/" 2>>"$LOG_FILE"; then
    log "  copiado a iCloud: $ICLOUD_DIR"
  else
    log "  WARN: no se pudo copiar a iCloud"
  fi
else
  log "  WARN: iCloud Drive no disponible — solo backup local"
fi

# ====== ROTACIÓN ======
log "rotación local (>$LOCAL_RETENTION_DAYS días)..."
DELETED_LOCAL=$(find "$LOCAL_DIR" -name "nemo-*.dump.enc" -type f -mtime "+$LOCAL_RETENTION_DAYS" -print -delete 2>/dev/null | wc -l | tr -d ' ')
log "  borrados: $DELETED_LOCAL"

if [ "$ICLOUD_AVAILABLE" = "1" ]; then
  log "rotación iCloud (>$ICLOUD_RETENTION_DAYS días)..."
  DELETED_REMOTE=$(find "$ICLOUD_DIR" -name "nemo-*.dump.enc" -type f -mtime "+$ICLOUD_RETENTION_DAYS" -print -delete 2>/dev/null | wc -l | tr -d ' ')
  log "  borrados: $DELETED_REMOTE"
fi

# ====== INVENTARIO ======
LOCAL_COUNT=$(find "$LOCAL_DIR" -name "nemo-*.dump.enc" -type f 2>/dev/null | wc -l | tr -d ' ')
LOCAL_TOTAL=$(du -sh "$LOCAL_DIR" 2>/dev/null | awk '{print $1}')
log "estado: $LOCAL_COUNT backups locales ($LOCAL_TOTAL)"

if [ "$ICLOUD_AVAILABLE" = "1" ]; then
  REMOTE_COUNT=$(find "$ICLOUD_DIR" -name "nemo-*.dump.enc" -type f 2>/dev/null | wc -l | tr -d ' ')
  REMOTE_TOTAL=$(du -sh "$ICLOUD_DIR" 2>/dev/null | awk '{print $1}')
  log "estado: $REMOTE_COUNT backups iCloud ($REMOTE_TOTAL)"
fi

log "===== nemo backup end ====="
log ""
exit 0
