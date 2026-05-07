#!/usr/bin/env bash
# restore-new-mac.sh — restaura el backup generado por backup-old-mac.sh.
# CORRER DESPUÉS de ./setup.sh para que las tools básicas existan.
#
# Uso: ./scripts/restore-new-mac.sh ~/mac-migration/
# Requiere: gpg, gh (GitHub CLI), git

set -euo pipefail

# ====== CONFIG ======
BACKUP_DIR="${1:-$HOME/mac-migration}"
PROJECTS_DIR="$HOME/projects"
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
if [ ! -d "$BACKUP_DIR" ]; then
  err "$BACKUP_DIR no existe. Pasa la ruta del backup como argumento."
  exit 1
fi

for cmd in gpg gh git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "$cmd no está instalado. Corre setup.sh primero."
    exit 1
  fi
done

if [ ! -f "$BACKUP_DIR/MIGRATION-MANIFEST.txt" ]; then
  err "No es un backup válido — falta MIGRATION-MANIFEST.txt"
  exit 1
fi

log "Restaurando desde $BACKUP_DIR"
echo
cat "$BACKUP_DIR/MIGRATION-MANIFEST.txt" | head -20
echo

if ! confirm "¿Continuar?"; then
  exit 0
fi

# ====== VERIFICAR CHECKSUMS ======
if [ -f "$BACKUP_DIR/checksums.sha256" ]; then
  log "Verificando checksums..."
  cd "$BACKUP_DIR"
  if shasum -a 256 -c checksums.sha256 --quiet 2>/dev/null; then
    ok "Checksums OK"
  else
    warn "Algunos checksums no validan — el backup puede estar corrupto"
    confirm "¿Continuar igual?" || exit 1
  fi
  cd - >/dev/null
fi

# ====== PASSPHRASE ======
read -r -s -p "Passphrase del backup: " PASSPHRASE
echo

# ====== DESCIFRAR CONFIGS ======
log "Descifrando configs..."
TMPDIR=$(mktemp -d)
trap "rm -rf '$TMPDIR'; unset PASSPHRASE" EXIT

gpg --batch --yes --passphrase "$PASSPHRASE" \
  --decrypt "$BACKUP_DIR/configs.tar.gz.gpg" 2>/dev/null | \
  tar -xzf - -C "$TMPDIR"

if [ ! -d "$TMPDIR/configs-staging" ]; then
  err "Passphrase incorrecta o archivo corrupto"
  exit 1
fi

CONFIGS="$TMPDIR/configs-staging"
ok "Configs descifrados"

# ====== RESTAURAR CONFIGS UNO POR UNO ======
log "Restaurando configs (te pregunto antes de sobrescribir)..."

restore_config() {
  local rel_path="$1"
  local src="$CONFIGS/$rel_path"
  local dest="$HOME/$rel_path"

  if [ ! -e "$src" ]; then
    return 0
  fi

  if [ -e "$dest" ]; then
    if confirm "  $dest ya existe — ¿sobrescribir?"; then
      rm -rf "$dest"
    else
      warn "  saltado: $dest"
      return 0
    fi
  fi

  mkdir -p "$(dirname "$dest")"
  cp -R "$src" "$dest"
  ok "  $rel_path"
}

# Críticos (manual confirm)
restore_config ".ssh"
chmod 700 "$HOME/.ssh" 2>/dev/null || true
chmod 600 "$HOME/.ssh"/* 2>/dev/null || true
chmod 644 "$HOME/.ssh"/*.pub 2>/dev/null || true

restore_config ".gitconfig"
restore_config ".gitignore_global"
restore_config ".gnupg"
chmod 700 "$HOME/.gnupg" 2>/dev/null || true

# Cloud
restore_config ".aws"
restore_config ".config/gcloud"
restore_config ".cloudflared"
restore_config ".railway"
restore_config ".docker/config.json"
restore_config ".eas-creds"
restore_config ".expo"
restore_config ".netrc"

# Shell — estos los appendea, no los sobrescribe
for shell_file in .bash_profile .zshrc .zshrc.custom .zprofile .zshenv .p10k.zsh; do
  if [ -f "$CONFIGS/$shell_file" ]; then
    if [ -f "$HOME/$shell_file" ]; then
      warn "  $HOME/$shell_file existe — guardado original como $shell_file.pre-migration"
      cp "$HOME/$shell_file" "$HOME/$shell_file.pre-migration"
    fi
    cp "$CONFIGS/$shell_file" "$HOME/$shell_file"
    ok "  $shell_file"
  fi
done

# Package managers
restore_config ".npmrc"
restore_config ".pnpmrc"
restore_config ".yarnrc"
restore_config ".yarnrc.yml"

# Editores
restore_config ".claude"
restore_config ".claude.json"
restore_config ".cursor"
restore_config ".opencode"
restore_config ".copilot"
restore_config ".gemini"

# Otros
restore_config ".hammerspoon"
restore_config ".iterm2-colors"

ok "Configs restaurados"

# ====== CLONAR REPOS ======
log "Clonando repos..."

mkdir -p "$PROJECTS_DIR"

if [ ! -f "$BACKUP_DIR/git-state/git-status.txt" ]; then
  warn "git-status.txt no encontrado — saltando clonado automático"
else
  while IFS= read -r line; do
    name=$(echo "$line" | awk '{print $1}')
    remote=$(echo "$line" | awk -F'| ' '{print $NF}')

    [ -z "$name" ] && continue
    [ "$remote" = "NO-REMOTE" ] && continue
    [ "$remote" = "NO-GIT" ] && continue

    target="$PROJECTS_DIR/$name"
    if [ -d "$target" ]; then
      warn "  $name ya existe en $target — saltado"
      continue
    fi

    log "  clonando $name desde $remote..."
    if git clone "$remote" "$target" 2>/dev/null; then
      ok "    $name"
    else
      err "    falló — verifica permisos en $remote"
    fi
  done < "$BACKUP_DIR/git-state/git-status.txt"
fi

# ====== RESTAURAR REPOS SIN REMOTE ======
if [ -d "$BACKUP_DIR/standalone-repos" ] && [ "$(ls -A "$BACKUP_DIR/standalone-repos")" ]; then
  log "Restaurando repos sin remote..."

  for f in "$BACKUP_DIR/standalone-repos"/*.bundle; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .bundle)
    target="$PROJECTS_DIR/$name"
    if [ -d "$target" ]; then
      warn "  $name ya existe — saltado"
      continue
    fi
    git clone "$f" "$target" 2>/dev/null && ok "  bundle: $name" || warn "  fallo $name"
  done

  for f in "$BACKUP_DIR/standalone-repos"/*.tar.gz; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .tar.gz)
    target="$PROJECTS_DIR/$name"
    if [ -d "$target" ]; then
      warn "  $name ya existe — saltado"
      continue
    fi
    tar -xzf "$f" -C "$PROJECTS_DIR" && ok "  tarball: $name" || warn "  fallo $name"
  done
fi

# ====== ENVS ======
log "Descifrando .env files..."

gpg --batch --yes --passphrase "$PASSPHRASE" \
  --decrypt "$BACKUP_DIR/envs.tar.gz.gpg" 2>/dev/null | \
  tar -xzf - -C "$TMPDIR"

if [ -d "$TMPDIR/envs-staging" ]; then
  log "Restaurando .env files a sus rutas originales..."
  cd "$TMPDIR/envs-staging"
  find . -type f | while IFS= read -r f; do
    rel="${f#./}"
    dest="$HOME/$rel"
    if [ -e "$dest" ]; then
      warn "  $dest existe — guardado original como .pre-migration"
      cp "$dest" "$dest.pre-migration"
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
  done
  cd - >/dev/null
  ok "Envs restaurados"
fi

# ====== INSTALAR PACKAGES DESDE INVENTARIO ======
log "Restaurando paquetes globales (npm, pnpm)..."

if [ -f "$BACKUP_DIR/inventories/npm-globals.txt" ] && command -v npm >/dev/null 2>&1; then
  pkgs=$(grep -E "^├──|^└──" "$BACKUP_DIR/inventories/npm-globals.txt" 2>/dev/null | \
         awk '{print $2}' | sed 's/@[^@]*$//' | tr '\n' ' ')
  if [ -n "$pkgs" ] && confirm "Instalar npm globals: $pkgs?"; then
    npm install -g $pkgs 2>/dev/null || warn "Algunos paquetes fallaron"
  fi
fi

if [ -f "$BACKUP_DIR/inventories/Brewfile" ] && command -v brew >/dev/null 2>&1; then
  if confirm "Correr brew bundle desde inventories/Brewfile (instala todo lo que tenías)?"; then
    brew bundle install --file="$BACKUP_DIR/inventories/Brewfile"
  fi
fi

# ====== RESUMEN ======
echo
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_GREEN}✅ Restauración completa${COLOR_RESET}"
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo
echo "Próximos pasos manuales (ver MIGRATION.md):"
echo "  - gh auth login (verifica)"
echo "  - railway login, vercel login, firebase login, eas login, gcloud auth login"
echo "  - Reabrir terminal para que tome el .zshrc"
echo "  - p10k configure si quieres ajustar el prompt"
echo "  - Touch ID en sudo: sudo sed -i '' '2i\\
auth       sufficient     pam_tid.so' /etc/pam.d/sudo"
echo
warn "Verifica $PROJECTS_DIR — si falta algo, revisa $BACKUP_DIR/git-state/"
