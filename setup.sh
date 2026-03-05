#!/bin/bash

# =============================================================================
# Mac Mini Setup Script
# =============================================================================
# Este script configura una Mac Mini nueva con todas las herramientas,
# aplicaciones y configuraciones necesarias para desarrollo.
#
# Uso: chmod +x setup.sh && ./setup.sh
# =============================================================================

set -e

# === PERSONALIZACIÓN ===
GIT_NAME="UMMANN AI"
GIT_EMAIL="angel@ummann.com"

# Activar/desactivar secciones
INSTALL_HOMEBREW=true
INSTALL_CLI_TOOLS=true
INSTALL_NODE=true
INSTALL_PYTHON=true
INSTALL_DOCKER=true
INSTALL_XCODE=true
INSTALL_CASK_APPS=true
INSTALL_VSCODE_EXTENSIONS=true
INSTALL_OHMYZSH=true
CONFIGURE_GIT=true
CONFIGURE_MACOS_DEFAULTS=true

# Apps adicionales (separadas por espacio)
EXTRA_CASK_APPS=""
# EXTRA_CASK_APPS="figma notion zoom"

# === COLORES PARA OUTPUT ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# === FUNCIONES DE LOGGING ===
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}$1${NC}"; echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# === FUNCIONES UTILITARIAS ===

# Verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar si una app está instalada (Cask)
app_installed() {
    [ -d "/Applications/$1.app" ] || [ -d "$HOME/Applications/$1.app" ]
}

# Verificar arquitectura del sistema
get_architecture() {
    if [[ $(uname -m) == "arm64" ]]; then
        echo "arm64"
    else
        echo "x86_64"
    fi
}

# Obtener la ruta de Homebrew según arquitectura
get_brew_path() {
    if [[ $(get_architecture) == "arm64" ]]; then
        echo "/opt/homebrew/bin/brew"
    else
        echo "/usr/local/bin/brew"
    fi
}

# Backup de archivo existente
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warn "Creando backup de $file -> $backup"
        cp "$file" "$backup"
    fi
}

# === VERIFICACIONES INICIALES ===
log_section "🚀 Iniciando Setup de Mac Mini"

echo -e "${BLUE}Arquitectura detectada:${NC} $(get_architecture)"
echo -e "${BLUE}Usuario:${NC} $(whoami)"
echo -e "${BLUE}Directorio home:${NC} $HOME"
echo ""

# Solicitar contraseña de administrador al inicio (opcional)
if [[ -t 0 ]]; then
    log_info "Solicitando credenciales de administrador..."
    if sudo -v 2>/dev/null; then
        # Mantener sudo activo durante el script
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    else
        log_warn "No se pudo obtener acceso sudo. Algunas configuraciones serán omitidas."
    fi
else
    log_warn "Ejecutando sin terminal interactiva. Omitiendo sudo."
fi

# === INSTALACIÓN DE HOMEBREW ===
if [[ "$INSTALL_HOMEBREW" == true ]]; then
    log_section "🍺 Homebrew"
    
    BREW_PATH=$(get_brew_path)
    
    if ! command_exists brew; then
        log_info "Instalando Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Agregar Homebrew al PATH según arquitectura
        if [[ $(get_architecture) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        log_info "Homebrew instalado correctamente"
    else
        log_info "Homebrew ya está instalado"
    fi
    
    # Actualizar Homebrew
    log_info "Actualizando Homebrew..."
    brew update
    
    # Agregar taps adicionales
    log_info "Agregando taps adicionales..."
    brew tap stripe/stripe-cli 2>/dev/null || true
    brew tap homebrew/cask-fonts 2>/dev/null || true
    
    # Instalar mas (Mac App Store CLI) para Xcode
    if ! brew list mas &>/dev/null; then
        log_info "Instalando mas (Mac App Store CLI)..."
        brew install mas
    fi
fi

# === XCODE ===
if [[ "$INSTALL_XCODE" == true ]]; then
    log_section "🍎 Xcode"
    
    if [ -d "/Applications/Xcode.app" ]; then
        log_info "Xcode ya está instalado"
    else
        log_info "Instalando Xcode desde App Store (esto puede tomar mucho tiempo ~12GB)..."
        log_warn "Asegúrate de estar logueado en la App Store"
        mas install 497799835 || log_warn "No se pudo instalar Xcode. Instálalo manualmente desde la App Store."
    fi
    
    # Aceptar licencia y instalar componentes
    if [ -d "/Applications/Xcode.app" ]; then
        log_info "Aceptando licencia de Xcode..."
        sudo xcodebuild -license accept 2>/dev/null || true
        
        log_info "Instalando componentes adicionales de Xcode..."
        xcodebuild -runFirstLaunch 2>/dev/null || true
    fi
fi

# === HERRAMIENTAS CLI ===
if [[ "$INSTALL_CLI_TOOLS" == true ]]; then
    log_section "🛠️  Herramientas CLI"
    
    CLI_TOOLS=(
        # Version Control
        "git"
        "gh"
        "lazygit"
        "delta"
        
        # Core Utils
        "wget"
        "curl"
        "tree"
        "jq"
        "yq"
        "htop"
        "tldr"
        
        # Modern Replacements
        "ripgrep"
        "fd"
        "bat"
        "eza"
        "fzf"
        "zoxide"
        "procs"
        "dust"
        "duf"
        
        # Development
        "tmux"
        "httpie"
        "shellcheck"
        "direnv"
        "gnupg"
        
        # Databases
        "postgresql@16"
        "redis"
        
        # Cloud & Infrastructure
        "awscli"
        "kubectl"
        
        # Stripe
        "stripe/stripe-cli/stripe"

        # Cloud
        "railway"

        # Testing & Performance
        "k6"

        # Utilidades
        "watch"

        # Tunnels
        "ngrok"
    )
    
    for tool in "${CLI_TOOLS[@]}"; do
        if brew list "$tool" &>/dev/null; then
            log_info "$tool ya está instalado"
        else
            log_info "Instalando $tool..."
            brew install "$tool" || log_warn "No se pudo instalar $tool"
        fi
    done
fi

# === NODE.JS VIA NVM ===
if [[ "$INSTALL_NODE" == true ]]; then
    log_section "📦 Node.js (via nvm)"
    
    export NVM_DIR="$HOME/.nvm"
    
    if [[ ! -d "$NVM_DIR" ]]; then
        log_info "Instalando nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        
        # Cargar nvm
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        log_info "nvm instalado correctamente"
    else
        log_info "nvm ya está instalado"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    # Instalar Node.js LTS
    if command_exists nvm; then
        log_info "Instalando Node.js LTS..."
        nvm install --lts
        nvm use --lts
        nvm alias default 'lts/*'
        
        log_info "Node.js $(node -v) instalado"
        
        # Instalar gestores de paquetes globales
        log_info "Instalando yarn y pnpm..."
        npm install -g yarn pnpm
        
        # Instalar CLIs globales para desarrollo móvil y cloud
        log_info "Instalando CLIs globales (eas, firebase, vercel, netlify, expo)..."
        npm install -g eas-cli
        npm install -g firebase-tools
        npm install -g vercel
        npm install -g netlify-cli
        npm install -g expo-cli
        npm install -g @angular/cli
        npm install -g typescript
        npm install -g ts-node

        # Instalar Bun
        if ! command_exists bun; then
            log_info "Instalando Bun..."
            brew tap oven-sh/bun
            brew install bun
        else
            log_info "Bun ya está instalado"
        fi

        # CLIs globales de desarrollo
        log_info "Instalando CLIs de desarrollo (turbo, wrangler, sentry, claude)..."
        npm install -g turbo
        npm install -g wrangler
        npm install -g @sentry/cli
        npm install -g @anthropic-ai/claude-code
    fi
fi

# === PYTHON ===
if [[ "$INSTALL_PYTHON" == true ]]; then
    log_section "🐍 Python"
    
    if brew list python@3 &>/dev/null || brew list python &>/dev/null; then
        log_info "Python ya está instalado via Homebrew"
    else
        log_info "Instalando Python 3..."
        brew install python
    fi
    
    log_info "Python $(python3 --version) disponible"
    
    # Instalar pipx para manejar herramientas Python globales (PEP 668)
    if ! brew list pipx &>/dev/null; then
        log_info "Instalando pipx..."
        brew install pipx
        pipx ensurepath
    fi
    
    # Instalar herramientas Python comunes via pipx
    log_info "Instalando herramientas Python comunes via pipx..."
    pipx install black || true
    pipx install flake8 || true
    pipx install mypy || true
fi

# === APLICACIONES CASK ===
if [[ "$INSTALL_CASK_APPS" == true ]]; then
    log_section "📱 Aplicaciones (Homebrew Cask)"
    
    # Leer apps desde apps.txt si existe
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    APPS_FILE="$SCRIPT_DIR/apps.txt"
    
    if [[ -f "$APPS_FILE" ]]; then
        while IFS= read -r app || [[ -n "$app" ]]; do
            # Ignorar líneas vacías y comentarios
            [[ -z "$app" || "$app" =~ ^# ]] && continue
            
            if brew list --cask "$app" &>/dev/null; then
                log_info "$app ya está instalado"
            else
                log_info "Instalando $app..."
                brew install --cask "$app" || log_warn "No se pudo instalar $app"
            fi
        done < "$APPS_FILE"
    else
        log_warn "No se encontró apps.txt, usando lista por defecto"
        
        DEFAULT_APPS=(
            "google-chrome"
            "visual-studio-code"
            "cursor"
            "iterm2"
            "rectangle"
            "raycast"
            "docker"
            "slack"
            "discord"
            "spotify"
        )
        
        for app in "${DEFAULT_APPS[@]}"; do
            if brew list --cask "$app" &>/dev/null; then
                log_info "$app ya está instalado"
            else
                log_info "Instalando $app..."
                brew install --cask "$app" || log_warn "No se pudo instalar $app"
            fi
        done
    fi
    
    # Instalar apps adicionales
    if [[ -n "$EXTRA_CASK_APPS" ]]; then
        for app in $EXTRA_CASK_APPS; do
            if brew list --cask "$app" &>/dev/null; then
                log_info "$app ya está instalado"
            else
                log_info "Instalando $app..."
                brew install --cask "$app" || log_warn "No se pudo instalar $app"
            fi
        done
    fi
fi

# === DOCKER ===
if [[ "$INSTALL_DOCKER" == true ]]; then
    log_section "🐳 Docker"
    
    if app_installed "Docker"; then
        log_info "Docker Desktop ya está instalado"
    else
        log_info "Docker Desktop se instalará via Cask..."
        brew install --cask docker || log_warn "No se pudo instalar Docker Desktop"
    fi
fi

# === CURSOR & VS CODE CLI ===
log_section "🔗 CLI Commands (cursor, code)"

# Instalar comando 'cursor' en PATH
CURSOR_BIN="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
if [[ -f "$CURSOR_BIN" ]]; then
    if ! command_exists cursor; then
        log_info "Instalando comando 'cursor' en PATH..."
        sudo ln -sf "$CURSOR_BIN" /usr/local/bin/cursor 2>/dev/null || \
        ln -sf "$CURSOR_BIN" "$HOME/.local/bin/cursor" 2>/dev/null || \
        log_warn "No se pudo crear symlink para cursor. Hazlo manualmente desde Cursor: Cmd+Shift+P → 'Shell Command: Install'"
    else
        log_info "Comando 'cursor' ya está disponible"
    fi
else
    log_warn "Cursor no está instalado en /Applications"
fi

# Instalar comando 'code' en PATH
VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if [[ -f "$VSCODE_BIN" ]]; then
    if ! command_exists code; then
        log_info "Instalando comando 'code' en PATH..."
        sudo ln -sf "$VSCODE_BIN" /usr/local/bin/code 2>/dev/null || \
        ln -sf "$VSCODE_BIN" "$HOME/.local/bin/code" 2>/dev/null || \
        log_warn "No se pudo crear symlink para code. Hazlo manualmente desde VS Code: Cmd+Shift+P → 'Shell Command: Install'"
    else
        log_info "Comando 'code' ya está disponible"
    fi
else
    log_warn "VS Code no está instalado en /Applications"
fi

# === EXTENSIONES DE VS CODE Y CURSOR ===
if [[ "$INSTALL_VSCODE_EXTENSIONS" == true ]]; then
    log_section "🧩 Extensiones de VS Code y Cursor"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    EXTENSIONS_FILE="$SCRIPT_DIR/extensions.txt"
    
    # Función para instalar extensiones
    install_extensions() {
        local cmd="$1"
        local name="$2"
        
        if [[ -f "$EXTENSIONS_FILE" ]]; then
            while IFS= read -r ext || [[ -n "$ext" ]]; do
                # Ignorar líneas vacías y comentarios
                [[ -z "$ext" || "$ext" =~ ^# ]] && continue
                
                log_info "[$name] Instalando extensión: $ext"
                $cmd --install-extension "$ext" --force 2>/dev/null || log_warn "No se pudo instalar $ext en $name"
            done < "$EXTENSIONS_FILE"
        else
            log_warn "No se encontró extensions.txt, usando lista por defecto"
            
            DEFAULT_EXTENSIONS=(
                "esbenp.prettier-vscode"
                "dbaeumer.vscode-eslint"
                "bradlc.vscode-tailwindcss"
                "formulahendry.auto-close-tag"
                "formulahendry.auto-rename-tag"
                "eamodio.gitlens"
                "PKief.material-icon-theme"
                "GitHub.copilot"
                "GitHub.copilot-chat"
                "ms-python.python"
            )
            
            for ext in "${DEFAULT_EXTENSIONS[@]}"; do
                log_info "[$name] Instalando extensión: $ext"
                $cmd --install-extension "$ext" --force 2>/dev/null || log_warn "No se pudo instalar $ext en $name"
            done
        fi
    }
    
    # Instalar en VS Code
    if command_exists code; then
        log_info "Instalando extensiones en VS Code..."
        install_extensions "code" "VS Code"
    else
        log_warn "VS Code CLI no disponible"
    fi
    
    # Instalar en Cursor
    if command_exists cursor; then
        log_info "Instalando extensiones en Cursor..."
        install_extensions "cursor" "Cursor"
    else
        log_warn "Cursor CLI no disponible"
    fi
    
    # Configurar tema de iconos y colores automáticamente
    log_info "Configurando temas de iconos y colores..."
    
    # Configuración para VS Code
    VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
    if [[ -d "$VSCODE_SETTINGS_DIR" ]]; then
        VSCODE_SETTINGS="$VSCODE_SETTINGS_DIR/settings.json"
        if [[ ! -f "$VSCODE_SETTINGS" ]]; then
            echo '{}' > "$VSCODE_SETTINGS"
        fi
        # Agregar configuración de temas si no existe
        if ! grep -q "workbench.iconTheme" "$VSCODE_SETTINGS"; then
            log_info "Configurando tema de iconos en VS Code..."
            tmp=$(mktemp)
            jq '. + {"workbench.iconTheme": "vscode-icons", "workbench.colorTheme": "GitHub Dark Default"}' "$VSCODE_SETTINGS" > "$tmp" 2>/dev/null && mv "$tmp" "$VSCODE_SETTINGS" || rm -f "$tmp"
        fi
    fi
    
    # Configuración para Cursor
    CURSOR_SETTINGS_DIR="$HOME/Library/Application Support/Cursor/User"
    if [[ -d "$CURSOR_SETTINGS_DIR" ]]; then
        CURSOR_SETTINGS="$CURSOR_SETTINGS_DIR/settings.json"
        if [[ ! -f "$CURSOR_SETTINGS" ]]; then
            echo '{}' > "$CURSOR_SETTINGS"
        fi
        # Agregar configuración de temas si no existe
        if ! grep -q "workbench.iconTheme" "$CURSOR_SETTINGS"; then
            log_info "Configurando tema de iconos en Cursor..."
            tmp=$(mktemp)
            jq '. + {"workbench.iconTheme": "vscode-icons", "workbench.colorTheme": "GitHub Dark Default"}' "$CURSOR_SETTINGS" > "$tmp" 2>/dev/null && mv "$tmp" "$CURSOR_SETTINGS" || rm -f "$tmp"
        fi
    fi
fi

# === CONFIGURACIÓN DE GIT ===
if [[ "$CONFIGURE_GIT" == true ]]; then
    log_section "🔧 Configuración de Git"
    
    # Configuración básica
    log_info "Configurando Git..."
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global core.editor "code --wait"
    git config --global init.defaultBranch main
    
    # Aliases útiles
    log_info "Configurando aliases de Git..."
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    git config --global alias.lg "log --oneline --graph --decorate --all"
    git config --global alias.df diff
    git config --global alias.dfs 'diff --staged'
    
    # Configuraciones adicionales
    git config --global pull.rebase false
    git config --global push.autoSetupRemote true
    git config --global core.autocrlf input
    
    log_info "Git configurado correctamente"
fi

# === OH MY ZSH ===
if [[ "$INSTALL_OHMYZSH" == true ]]; then
    log_section "💻 Oh My Zsh y Terminal"
    
    # Instalar Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Instalando Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log_info "Oh My Zsh ya está instalado"
    fi
    
    # Instalar Powerlevel10k
    P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ ! -d "$P10K_DIR" ]]; then
        log_info "Instalando Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    else
        log_info "Powerlevel10k ya está instalado"
    fi
    
    # Instalar zsh-autosuggestions
    ZSH_AUTOSUGGESTIONS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [[ ! -d "$ZSH_AUTOSUGGESTIONS_DIR" ]]; then
        log_info "Instalando zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
    else
        log_info "zsh-autosuggestions ya está instalado"
    fi
    
    # Instalar zsh-syntax-highlighting
    ZSH_SYNTAX_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    if [[ ! -d "$ZSH_SYNTAX_DIR" ]]; then
        log_info "Instalando zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_DIR"
    else
        log_info "zsh-syntax-highlighting ya está instalado"
    fi
    
    # Descargar temas de colores para iTerm2
    ITERM_COLORS_DIR="$HOME/.iterm2-colors"
    if [[ ! -d "$ITERM_COLORS_DIR" ]]; then
        log_info "Descargando temas de colores para iTerm2..."
        mkdir -p "$ITERM_COLORS_DIR"
        
        # Descargar temas populares
        curl -sL "https://raw.githubusercontent.com/dracula/iterm/master/Dracula.itermcolors" -o "$ITERM_COLORS_DIR/Dracula.itermcolors" || true
        curl -sL "https://raw.githubusercontent.com/nordtheme/iterm2/develop/src/xml/Nord.itermcolors" -o "$ITERM_COLORS_DIR/Nord.itermcolors" || true
        curl -sL "https://raw.githubusercontent.com/catppuccin/iterm/main/colors/catppuccin-mocha.itermcolors" -o "$ITERM_COLORS_DIR/Catppuccin-Mocha.itermcolors" || true
        curl -sL "https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/schemes/Tokyo%20Night.itermcolors" -o "$ITERM_COLORS_DIR/Tokyo-Night.itermcolors" || true
        curl -sL "https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/schemes/One%20Dark.itermcolors" -o "$ITERM_COLORS_DIR/One-Dark.itermcolors" || true
        
        log_info "Temas descargados en $ITERM_COLORS_DIR"
        log_info "Para importar: iTerm2 → Settings → Profiles → Colors → Color Presets → Import"
    else
        log_info "Temas de iTerm2 ya descargados"
    fi
    
    # Backup y configurar .zshrc
    backup_file "$HOME/.zshrc"
    
    log_info "Configurando .zshrc..."
    
    # Crear .zshrc si no existe
    if [[ ! -f "$HOME/.zshrc" ]]; then
        touch "$HOME/.zshrc"
    fi
    
    # Agregar configuración de Powerlevel10k si no existe
    if ! grep -q "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" "$HOME/.zshrc"; then
        sed -i '' 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc" 2>/dev/null || true
    fi
    
    # Copiar configuraciones custom
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$SCRIPT_DIR/.zshrc.custom" ]]; then
        if ! grep -q "source.*\.zshrc\.custom" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Custom configurations" >> "$HOME/.zshrc"
            echo "[ -f ~/.zshrc.custom ] && source ~/.zshrc.custom" >> "$HOME/.zshrc"
        fi
        cp "$SCRIPT_DIR/.zshrc.custom" "$HOME/.zshrc.custom"
        log_info "Configuraciones custom copiadas"
    fi
    
    log_info "Terminal configurada correctamente"
fi

# === CONFIGURACIÓN DE macOS ===
if [[ "$CONFIGURE_MACOS_DEFAULTS" == true ]]; then
    log_section "⚙️  Configuración de macOS"
    
    # Estas configuraciones no requieren sudo
    log_info "Aplicando configuraciones de macOS..."
    
    # Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    
    # Dock
    defaults write com.apple.dock tilesize -int 36
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock show-recents -bool false
    
    # Teclado
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    
    # Trackpad
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    
    log_info "Reiniciando Finder y Dock..."
    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true
    
    log_info "Configuraciones de macOS aplicadas"
fi

# === RESUMEN FINAL ===
log_section "✅ Setup Completado"

echo -e "${GREEN}El setup se ha completado correctamente.${NC}"
echo ""
echo -e "${YELLOW}Acciones recomendadas:${NC}"
echo "  1. Reinicia la terminal para aplicar cambios de zsh"
echo "  2. Configura Powerlevel10k ejecutando: p10k configure"
echo "  3. Abre VS Code y configura 'Shell Command: Install code command in PATH'"
echo "  4. Inicia Docker Desktop y completa la configuración inicial"
echo "  5. Revisa y personaliza ~/.zshrc.custom según tus preferencias"
echo ""
echo -e "${BLUE}Versiones instaladas:${NC}"
command_exists node && echo "  Node.js: $(node -v)"
command_exists npm && echo "  npm: $(npm -v)"
command_exists python3 && echo "  Python: $(python3 --version)"
command_exists git && echo "  Git: $(git --version)"
echo ""
echo -e "${GREEN}¡Disfruta tu nueva Mac! 🎉${NC}"
