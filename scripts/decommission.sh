#!/usr/bin/env bash
# decommission.sh — para todos los daemons UMMANN/nemo de esta mac.
#
# Úsalo ANTES de migrar a una mac nueva para garantizar:
#  - DB Postgres no recibe más escrituras (snapshot consistente)
#  - Cloudflared libera el tunnel para que la mac nueva lo tome
#  - Workers no duplican morning-brief/whatsapp-summary/notes-digest
#
# Modos:
#  ./scripts/decommission.sh           # para todo (con confirmación)
#  ./scripts/decommission.sh --restart # vuelve a cargar todo (rollback)
#  ./scripts/decommission.sh --status  # solo muestra qué está activo

set -uo pipefail

MODE="${1:-stop}"
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
  read -r -p "$1 [y/N]: " r
  [[ "$r" =~ ^[Yy]$ ]]
}

# Plists a controlar (filtra updaters de Google/Microsoft que no nos interesan)
PLISTS_TO_STOP=(
  "com.nemo.api"
  "com.nemo.daemon"
  "com.nemo.workers"
  "ai.ummann.whatsapp-bridge"
  "com.ummann.morning-whatsapp-summary"
  "com.ummann.notes-digest"
  "com.ummann.tt-tracker"
  "com.ummann.tunnel-watchdog"
  "com.cloudflare.cloudflared"
  "com.ummann.nemo-backup"
)

# Patrones de procesos a verificar después
PROCESS_PATTERNS=(
  "apps/nemo-api/src/index.ts"
  "apps/nemo-daemon/src/index.ts"
  "apps/nemo-workers/src/index.ts"
  "whatsapp-bridge"
  "cloudflared.*tunnel"
)

# ====== STATUS ======
show_status() {
  echo
  echo "=== LaunchAgents activos ==="
  for label in "${PLISTS_TO_STOP[@]}"; do
    if launchctl list 2>/dev/null | grep -q "^[0-9-]*.*$label$"; then
      pid=$(launchctl list 2>/dev/null | awk -v l="$label" '$3==l {print $1}')
      if [ "$pid" != "-" ] && [ -n "$pid" ]; then
        echo -e "  ${COLOR_GREEN}●${COLOR_RESET} $label (pid: $pid)"
      else
        echo -e "  ${COLOR_YELLOW}○${COLOR_RESET} $label (loaded, not running)"
      fi
    else
      echo -e "  ${COLOR_RED}✗${COLOR_RESET} $label (no cargado)"
    fi
  done

  echo
  echo "=== Procesos relevantes ==="
  local any=0
  for pattern in "${PROCESS_PATTERNS[@]}"; do
    if pgrep -f "$pattern" >/dev/null 2>&1; then
      pids=$(pgrep -f "$pattern" | tr '\n' ' ')
      echo "  ● $pattern → pids: $pids"
      any=1
    fi
  done
  [ "$any" = "0" ] && echo "  (ninguno)"

  echo
  echo "=== Conexiones a DB nemo ==="
  /opt/homebrew/opt/postgresql@16/bin/psql -d nemo -tAc \
    "SELECT count(*) FROM pg_stat_activity WHERE datname='nemo' AND pid != pg_backend_pid();" 2>/dev/null \
    | xargs -I{} echo "  conexiones activas: {}"
}

if [ "$MODE" = "--status" ]; then
  show_status
  exit 0
fi

# ====== RESTART ======
if [ "$MODE" = "--restart" ]; then
  log "Recargando LaunchAgents (rollback de decommission)..."
  for label in "${PLISTS_TO_STOP[@]}"; do
    plist="$HOME/Library/LaunchAgents/$label.plist"
    if [ -f "$plist" ]; then
      launchctl unload "$plist" 2>/dev/null || true
      if launchctl load "$plist" 2>/dev/null; then
        ok "  loaded $label"
      else
        warn "  fallo $label"
      fi
    fi
  done
  echo
  ok "Rollback completo"
  show_status
  exit 0
fi

# ====== STOP ======
echo
warn "════════════════════════════════════════════════════"
warn "  DECOMMISSION — vas a parar TODO nemo en esta mac"
warn "════════════════════════════════════════════════════"
echo
echo "Esto va a:"
echo "  1. launchctl unload de todos los daemons UMMANN/nemo"
echo "  2. Esperar 30s para que terminen queries en vuelo"
echo "  3. Verificar que ningún proceso bun/nemo quedó"
echo "  4. Mostrar checkpoint para que corras backup-services.sh"
echo
echo "Consecuencias:"
echo "  - Telegram bot deja de responder (hasta que la mac nueva tome el tunnel)"
echo "  - Mobile app pierde conexión a la API"
echo "  - Workers no procesan morning-brief, notes-digest, etc."
echo "  - DB nemo queda quieta — listo para snapshot"
echo
echo "Rollback: ./scripts/decommission.sh --restart"
echo

show_status
echo

if ! confirm "¿Proceder con el decommission?"; then
  echo "Cancelado."
  exit 0
fi

# ====== UNLOAD ======
log "Descargando LaunchAgents..."
for label in "${PLISTS_TO_STOP[@]}"; do
  plist="$HOME/Library/LaunchAgents/$label.plist"
  if [ ! -f "$plist" ]; then
    continue
  fi
  if launchctl list 2>/dev/null | grep -q "$label"; then
    if launchctl unload "$plist" 2>/dev/null; then
      ok "  unloaded $label"
    else
      warn "  fallo unload $label"
    fi
  else
    echo "  (skip $label — no cargado)"
  fi
done

# ====== ESPERA ======
log "Esperando 30s para que terminen las queries en vuelo..."
for i in 30 25 20 15 10 5; do
  sleep 5
  echo "  ${i}s restantes..."
done

# ====== KILL FORZADO (si quedan procesos) ======
log "Verificando procesos remanentes..."
ANY_REMAINING=0
for pattern in "${PROCESS_PATTERNS[@]}"; do
  pids=$(pgrep -f "$pattern" 2>/dev/null || echo "")
  if [ -n "$pids" ]; then
    warn "  procesos restantes para '$pattern': $pids"
    ANY_REMAINING=1
  fi
done

if [ "$ANY_REMAINING" = "1" ]; then
  echo
  if confirm "Hay procesos colgados. ¿Mandarles SIGTERM?"; then
    for pattern in "${PROCESS_PATTERNS[@]}"; do
      pkill -TERM -f "$pattern" 2>/dev/null && ok "  TERM enviado a '$pattern'" || true
    done
    sleep 3
    # Si siguen vivos, SIGKILL
    for pattern in "${PROCESS_PATTERNS[@]}"; do
      if pgrep -f "$pattern" >/dev/null 2>&1; then
        warn "  '$pattern' aún vivo — SIGKILL"
        pkill -KILL -f "$pattern" 2>/dev/null || true
      fi
    done
  fi
fi

# ====== VERIFICACIÓN FINAL ======
echo
log "Estado final:"
show_status

# ====== CHECKPOINT ======
echo
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_GREEN}✅ Decommission completo${COLOR_RESET}"
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo
echo "Próximos pasos:"
echo "  1. ./scripts/backup-old-mac.sh       (configs + repos + envs)"
echo "  2. ./scripts/backup-services.sh      (DBs + state — DB ya no escribe)"
echo "  3. Copiar ~/mac-migration/ a la mac nueva"
echo "  4. En la mac nueva:"
echo "       ./scripts/restore-new-mac.sh ~/mac-migration/"
echo "       ./scripts/restore-services.sh ~/mac-migration/  (responde 'y' al final)"
echo "  5. Verifica: curl https://nemo-api.ummann.com/health"
echo
warn "Si te arrepientes y quieres reactivar nemo aquí: ./scripts/decommission.sh --restart"
