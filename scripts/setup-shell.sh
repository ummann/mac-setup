#!/usr/bin/env bash
# setup-shell.sh — clona dotfiles + claude-config y los enlaza.
#
# Esto es lo MÁS IMPORTANTE en una mac nueva: shell, aliases, plugins, oh-my-zsh.
# Corre DESPUÉS de setup.sh (que instala brew, oh-my-zsh, etc.).
#
# Uso: ./scripts/setup-shell.sh

set -euo pipefail

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
for cmd in git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "$cmd no está instalado. Corre setup.sh primero."
    exit 1
  fi
done

# Verificar que SSH/HTTPS auth a GitHub funciona
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated\|does not provide"; then
  warn "SSH a GitHub no autenticado. Usaremos HTTPS via gh."
  if ! command -v gh >/dev/null 2>&1; then
    err "gh CLI no instalado. Instala con: brew install gh"
    exit 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    warn "gh no autenticado. Corre: gh auth login"
    read -r -p "¿Correr 'gh auth login' ahora? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && gh auth login || exit 1
  fi
  USE_HTTPS=1
else
  USE_HTTPS=0
fi

# ====== 1. OH-MY-ZSH PLUGINS CUSTOM ======
log "Instalando plugins custom de oh-my-zsh..."

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null && \
    ok "  zsh-autosuggestions" || warn "  fallo zsh-autosuggestions"
else
  ok "  zsh-autosuggestions (ya existe)"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null && \
    ok "  zsh-syntax-highlighting" || warn "  fallo zsh-syntax-highlighting"
else
  ok "  zsh-syntax-highlighting (ya existe)"
fi

# Powerlevel10k theme
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k" 2>/dev/null && \
    ok "  powerlevel10k theme" || warn "  fallo powerlevel10k"
else
  ok "  powerlevel10k (ya existe)"
fi

# ====== 2. CLONAR DOTFILES ======
log "Clonando ~/dotfiles desde ummann-technologies/dotfiles..."

if [ -d "$HOME/dotfiles" ]; then
  warn "  ~/dotfiles ya existe — solo hago pull"
  cd "$HOME/dotfiles" && git pull && cd - >/dev/null
else
  if [ "$USE_HTTPS" = "1" ]; then
    git clone https://github.com/ummann-technologies/dotfiles.git "$HOME/dotfiles"
  else
    git clone git@github.com:ummann-technologies/dotfiles.git "$HOME/dotfiles"
  fi
  ok "  ~/dotfiles clonado"
fi

# Correr install.sh de dotfiles (crea symlinks)
log "Ejecutando ~/dotfiles/install.sh (crea symlinks)..."
chmod +x "$HOME/dotfiles/install.sh"
"$HOME/dotfiles/install.sh"

# ====== 3. CLONAR UMMANN-CLAUDE-CONFIG ======
log "Configurando ~/.claude desde ummann-claude-config..."

CLAUDE_REPO_HTTPS="https://github.com/ummann-technologies/ummann-claude-config.git"
CLAUDE_REPO_SSH="git@github.com:ummann-technologies/ummann-claude-config.git"
CLAUDE_REPO=$([ "$USE_HTTPS" = "1" ] && echo "$CLAUDE_REPO_HTTPS" || echo "$CLAUDE_REPO_SSH")

if [ ! -d "$HOME/.claude" ]; then
  git clone "$CLAUDE_REPO" "$HOME/.claude"
  ok "  ~/.claude clonado limpio"
else
  warn "  ~/.claude ya existe (Claude Code instalado) — convirtiendo a repo"
  cd "$HOME/.claude"
  if [ ! -d ".git" ]; then
    git init
    git remote add origin "$CLAUDE_REPO"
    git fetch origin
    git reset origin/main
    git checkout -- .gitignore 2>/dev/null || true
    git branch --set-upstream-to=origin/main 2>/dev/null || true
    ok "  ~/.claude vinculado al repo"
  else
    git pull
    ok "  ~/.claude pulled"
  fi
  cd - >/dev/null
fi

# ====== 4. iTerm2 COLORS ======
log "Descargando colores de iTerm2 si no existen..."
ITERM_DIR="$HOME/.iterm2-colors"
mkdir -p "$ITERM_DIR"
for theme in Dracula Nord Catppuccin-Mocha Tokyo-Night One-Dark; do
  if [ ! -f "$ITERM_DIR/$theme.itermcolors" ]; then
    case $theme in
      Dracula)
        url="https://raw.githubusercontent.com/dracula/iterm/master/Dracula.itermcolors";;
      Nord)
        url="https://raw.githubusercontent.com/arcticicestudio/nord-iterm2/develop/src/xml/Nord.itermcolors";;
      Catppuccin-Mocha)
        url="https://raw.githubusercontent.com/catppuccin/iterm/main/colors/catppuccin-mocha.itermcolors";;
      Tokyo-Night)
        url="https://raw.githubusercontent.com/enkia/tokyo-night-vscode-theme/master/Tokyo%20Night.itermcolors";;
      One-Dark)
        url="https://raw.githubusercontent.com/nathanbuchar/atom-one-dark-terminal/master/scheme/iterm/One%20Dark.itermcolors";;
    esac
    curl -fsSL "$url" -o "$ITERM_DIR/$theme.itermcolors" 2>/dev/null && ok "  $theme" || warn "  fallo $theme"
  fi
done

# ====== 5. RESUMEN ======
echo
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo -e "${COLOR_GREEN}✅ Shell + configs listos${COLOR_RESET}"
echo -e "${COLOR_GREEN}══════════════════════════════════════════════════${COLOR_RESET}"
echo
echo "Próximos pasos:"
echo "  1. Abre una NUEVA terminal (o: source ~/.zshrc)"
echo "  2. p10k configure  (para personalizar el prompt)"
echo "  3. iTerm2 → Settings → Profiles → Colors → Color Presets → Import"
echo "     y elige uno de ~/.iterm2-colors/"
echo
echo "Para Cursor/VS Code icon theme:"
echo "  Cmd+Shift+P → 'File Icon Theme' → 'Material Icon Theme'"
