#!/usr/bin/env bash
# backup-old-mac.sh — empaqueta todo lo necesario para migrar a una Mac nueva.
# Salida: ~/mac-migration/
#   - configs.tar.gz.gpg  (cifrado con passphrase, contiene .ssh, .gitconfig, .claude, etc.)
#   - envs.tar.gz.gpg     (cifrado, contiene todos los .env de proyectos)
#   - inventories/        (listas de brew, npm, vscode, apps, etc.)
#   - standalone-repos/   (bundles git para repos sin remote)
#   - git-state/          (status snapshot de cada repo)
#   - MIGRATION-MANIFEST.txt
#
# Uso: ./scripts/backup-old-mac.sh
# Requiere: gpg (brew install gnupg)

set -euo pipefail

# ====== CONFIG ======
BACKUP_DIR="$HOME/mac-migration"
PROJECTS_DIR="$HOME/projects"
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

# ====== PRE-FLIGHT ======
if ! command -v gpg >/dev/null 2>&1; then
  err "gpg no está instalado. Corre: brew install gnupg"
  exit 1
fi

if [ -d "$BACKUP_DIR" ]; then
  warn "$BACKUP_DIR ya existe. Renombrando a $BACKUP_DIR.bak-$TIMESTAMP"
  mv "$BACKUP_DIR" "$BACKUP_DIR.bak-$TIMESTAMP"
fi

mkdir -p "$BACKUP_DIR"/{inventories,standalone-repos,git-state,envs-staging,configs-staging}
cd "$BACKUP_DIR"

log "Backup en $BACKUP_DIR"
log "Hostname: $(hostname)  |  User: $USER"

# ====== INVENTARIOS ======
log "Generando inventarios..."

{
  echo "# Brew leaves (paquetes instalados explícitamente)"
  brew leaves 2>/dev/null || echo "brew no disponible"
  echo
  echo "# Brew casks"
  brew list --cask 2>/dev/null || echo "brew no disponible"
  echo
  echo "# Brew taps"
  brew tap 2>/dev/null
} > inventories/brew-installed.txt

{
  echo "# Brewfile"
  brew bundle dump --file=- 2>/dev/null || echo "no se pudo generar"
} > inventories/Brewfile

npm ls -g --depth=0 2>/dev/null > inventories/npm-globals.txt || warn "npm no disponible"
pnpm ls -g --depth=0 2>/dev/null > inventories/pnpm-globals.txt || warn "pnpm no disponible"
yarn global list 2>/dev/null > inventories/yarn-globals.txt || true

if command -v code >/dev/null 2>&1; then
  code --list-extensions > inventories/vscode-extensions.txt
fi
if command -v cursor >/dev/null 2>&1; then
  cursor --list-extensions > inventories/cursor-extensions.txt
fi
if command -v mas >/dev/null 2>&1; then
  mas list > inventories/mas-apps.txt
fi

ls /Applications > inventories/apps-applications.txt
ls "$HOME/Applications" 2>/dev/null > inventories/apps-user.txt || true

if [ -d "$HOME/.nvm" ]; then
  bash -c 'source ~/.nvm/nvm.sh && nvm ls' 2>/dev/null > inventories/node-versions.txt || true
fi

# Configs MCP de Claude
if [ -f "$HOME/.claude.json" ]; then
  cp "$HOME/.claude.json" inventories/claude-config.json
fi

ok "Inventarios generados en inventories/"

# ====== ESTADO DE REPOS ======
log "Snapshotting git state de $PROJECTS_DIR..."

GIT_REPORT="git-state/git-status.txt"
NO_REMOTE="git-state/repos-no-remote.txt"
WIP_REPORT="git-state/wip-summary.txt"
UNPUSHED="git-state/unpushed-commits.txt"

: > "$GIT_REPORT"
: > "$NO_REMOTE"
: > "$WIP_REPORT"
: > "$UNPUSHED"

for d in "$PROJECTS_DIR"/*/; do
  name=$(basename "$d")
  if [ -d "$d/.git" ]; then
    cd "$d"
    remote=$(git remote get-url origin 2>/dev/null || echo "NO-REMOTE")
    branch=$(git branch --show-current 2>/dev/null || echo "?")
    dirty_count=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    unpushed_count=$(git log --oneline @{u}.. 2>/dev/null | wc -l | tr -d ' ' || echo "0")

    echo "$name | $branch | dirty=$dirty_count unpushed=$unpushed_count | $remote" >> "$BACKUP_DIR/$GIT_REPORT"

    if [ "$remote" = "NO-REMOTE" ]; then
      echo "$name -> $d" >> "$BACKUP_DIR/$NO_REMOTE"
    fi

    if [ "$dirty_count" != "0" ]; then
      echo "## $name (branch: $branch)" >> "$BACKUP_DIR/$WIP_REPORT"
      git status --short >> "$BACKUP_DIR/$WIP_REPORT"
      echo >> "$BACKUP_DIR/$WIP_REPORT"
    fi

    if [ "$unpushed_count" != "0" ] && [ "$unpushed_count" != "?" ]; then
      echo "## $name ($unpushed_count commits ahead of $branch upstream)" >> "$BACKUP_DIR/$UNPUSHED"
      git log --oneline @{u}.. 2>/dev/null >> "$BACKUP_DIR/$UNPUSHED" || true
      echo >> "$BACKUP_DIR/$UNPUSHED"
    fi

    cd - >/dev/null
  else
    echo "$name | NO-GIT" >> "$BACKUP_DIR/$GIT_REPORT"
    echo "$name -> $d (no .git directory)" >> "$BACKUP_DIR/$NO_REMOTE"
  fi
done

ok "Git state guardado en git-state/"

# ====== STANDALONE REPOS (sin remote) ======
log "Empaquetando repos sin remote como git bundles..."

while IFS= read -r line; do
  name=$(echo "$line" | awk '{print $1}')
  path=$(echo "$line" | awk -F'-> ' '{print $2}')
  [ -z "$path" ] && continue
  if [ -d "$path/.git" ]; then
    cd "$path"
    git bundle create "$BACKUP_DIR/standalone-repos/$name.bundle" --all 2>/dev/null && \
      ok "  bundle: $name" || warn "  no se pudo bundle $name"
    cd - >/dev/null
  else
    # Sin git → tarball del directorio entero
    tar -czf "$BACKUP_DIR/standalone-repos/$name.tar.gz" -C "$(dirname "$path")" "$(basename "$path")" 2>/dev/null && \
      ok "  tarball: $name" || warn "  no se pudo tar $name"
  fi
done < "$BACKUP_DIR/$NO_REMOTE"

# ====== ENV FILES ======
log "Recolectando .env files..."

ENVS_DIR="$BACKUP_DIR/envs-staging"
ENV_INDEX="$BACKUP_DIR/git-state/envs-index.txt"
: > "$ENV_INDEX"

# Find es safe — excluye node_modules, .next, .turbo
find "$PROJECTS_DIR" -maxdepth 4 -type f \
  \( -name ".env" -o -name ".env.*" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/.next/*" \
  -not -path "*/.turbo/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  2>/dev/null | while IFS= read -r envfile; do
  rel="${envfile#$HOME/}"
  target="$ENVS_DIR/$rel"
  mkdir -p "$(dirname "$target")"
  cp "$envfile" "$target"
  echo "$rel" >> "$ENV_INDEX"
done

env_count=$(wc -l < "$ENV_INDEX" | tr -d ' ')
ok "  $env_count archivos .env recolectados"

# ====== CONFIGS SENSIBLES ======
log "Recolectando configs sensibles..."

CONFIG_STAGING="$BACKUP_DIR/configs-staging"

copy_if_exists() {
  local src="$1"
  local dest="$CONFIG_STAGING/${src#$HOME/}"
  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -R "$src" "$dest" 2>/dev/null && ok "  $src" || warn "  fallo $src"
  fi
}

# SSH y git
copy_if_exists "$HOME/.ssh"
copy_if_exists "$HOME/.gitconfig"
copy_if_exists "$HOME/.gitignore_global"
copy_if_exists "$HOME/.gnupg"

# Cloud / deploy CLIs
copy_if_exists "$HOME/.aws"
copy_if_exists "$HOME/.config/gcloud"
copy_if_exists "$HOME/.cloudflared"
copy_if_exists "$HOME/.railway"
copy_if_exists "$HOME/.docker/config.json"
copy_if_exists "$HOME/.eas-creds"
copy_if_exists "$HOME/.expo"
copy_if_exists "$HOME/.netrc"

# Shell
copy_if_exists "$HOME/.bash_profile"
copy_if_exists "$HOME/.zshrc"
copy_if_exists "$HOME/.zshrc.custom"
copy_if_exists "$HOME/.zprofile"
copy_if_exists "$HOME/.zshenv"
copy_if_exists "$HOME/.p10k.zsh"

# Node / package managers
copy_if_exists "$HOME/.npmrc"
copy_if_exists "$HOME/.pnpmrc"
copy_if_exists "$HOME/.yarnrc"
copy_if_exists "$HOME/.yarnrc.yml"

# Editores / asistentes
copy_if_exists "$HOME/.claude"
copy_if_exists "$HOME/.claude.json"
copy_if_exists "$HOME/.cursor"
copy_if_exists "$HOME/.opencode"
copy_if_exists "$HOME/.copilot"
copy_if_exists "$HOME/.gemini"

# Otros
copy_if_exists "$HOME/.hammerspoon"
copy_if_exists "$HOME/.iterm2-colors"
copy_if_exists "$HOME/.config"

ok "Configs en configs-staging/"

# ====== CIFRADO ======
log "Cifrando tarballs (te va a pedir passphrase 2 veces)..."
echo
warn "IMPORTANTE: usa la misma passphrase para configs y envs."
warn "Anótala en un password manager — sin ella el backup es inservible."
echo

read -r -s -p "Passphrase para cifrar: " PASSPHRASE
echo
read -r -s -p "Confirma passphrase: " PASSPHRASE2
echo
if [ "$PASSPHRASE" != "$PASSPHRASE2" ]; then
  err "Passphrases no coinciden"
  exit 1
fi

log "Cifrando configs.tar.gz..."
tar -czf - -C "$BACKUP_DIR" configs-staging | \
  gpg --batch --yes --passphrase "$PASSPHRASE" --symmetric --cipher-algo AES256 \
  -o "$BACKUP_DIR/configs.tar.gz.gpg"

log "Cifrando envs.tar.gz..."
tar -czf - -C "$BACKUP_DIR" envs-staging | \
  gpg --batch --yes --passphrase "$PASSPHRASE" --symmetric --cipher-algo AES256 \
  -o "$BACKUP_DIR/envs.tar.gz.gpg"

# Limpiar staging (quedan solo los .gpg)
rm -rf "$BACKUP_DIR/configs-staging" "$BACKUP_DIR/envs-staging"
unset PASSPHRASE PASSPHRASE2

# ====== CHECKSUMS ======
log "Generando checksums..."
cd "$BACKUP_DIR"
shasum -a 256 configs.tar.gz.gpg envs.tar.gz.gpg > checksums.sha256
shasum -a 256 standalone-repos/* >> checksums.sha256 2>/dev/null || true

# ====== MANIFEST ======
cat > MIGRATION-MANIFEST.txt <<EOF
=== MAC MIGRATION MANIFEST ===
Generated: $(date)
Hostname: $(hostname)
User: $USER

Contenido:
- configs.tar.gz.gpg          configs sensibles cifrados (.ssh, .claude, .gitconfig, etc.)
- envs.tar.gz.gpg             archivos .env de cada proyecto cifrados
- inventories/                listas: brew, npm, pnpm, vscode, apps, mas, node
- standalone-repos/           bundles git para repos sin remote
- git-state/                  snapshot de status, wip, unpushed, no-remote
- checksums.sha256            verificación de integridad
- MIGRATION-MANIFEST.txt      este archivo

Restauración: ./scripts/restore-new-mac.sh ~/mac-migration/

Repos sin remote (CRÍTICOS — bundle en standalone-repos/):
$(cat git-state/repos-no-remote.txt 2>/dev/null || echo "ninguno")

Repos con WIP sin commitear:
$(grep -c "^## " git-state/wip-summary.txt 2>/dev/null || echo "0") repos con cambios

Repos con commits sin pushear:
$(grep -c "^## " git-state/unpushed-commits.txt 2>/dev/null || echo "0") repos
EOF

# ====== RESUMEN FINAL ======
echo
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_GREEN}✅ Backup completo en $BACKUP_DIR${COLOR_RESET}"
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo
du -sh "$BACKUP_DIR"/*.gpg "$BACKUP_DIR/standalone-repos" 2>/dev/null || true
echo
echo "Próximos pasos:"
echo "  1. Lee $BACKUP_DIR/git-state/repos-no-remote.txt y crea repos en GitHub si quieres preservarlos online"
echo "  2. Lee $BACKUP_DIR/git-state/wip-summary.txt y decide qué commitear antes de migrar"
echo "  3. Copia $BACKUP_DIR/ a la mac nueva (AirDrop, USB, iCloud, rsync)"
echo "  4. En la mac nueva: ejecuta setup.sh y luego scripts/restore-new-mac.sh"
echo
warn "NO subas mac-migration/ a Dropbox/iCloud Drive sin pensarlo — está cifrado pero contiene credenciales"
