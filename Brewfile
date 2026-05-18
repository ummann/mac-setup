# =============================================================================
# Brewfile — Fuente de verdad de TODO lo instalado via Homebrew
# =============================================================================
# Generado con: brew bundle dump --force --file=Brewfile
# Instalar con:  brew bundle install --file=Brewfile
# Sincronizar:   brew bundle dump --force --file=Brewfile (sobreescribe)
# =============================================================================

# -----------------------------------------------------------------------------
# Taps
# -----------------------------------------------------------------------------
tap "getsentry/tools"
tap "minio/stable"
tap "oven-sh/bun"
tap "schpet/tap"
tap "stripe/stripe-cli"
tap "wix/brew"

# -----------------------------------------------------------------------------
# CLI Tools — core utilities
# -----------------------------------------------------------------------------
brew "bat"               # cat mejorado
brew "coreutils"
brew "curl"
brew "duf"               # df mejorado
brew "dust"              # du mejorado
brew "eza"               # ls mejorado
brew "fd"                # find mejorado
brew "fzf"               # fuzzy finder
brew "htop"
brew "jq"
brew "neovim"
brew "procs"             # ps mejorado
brew "ripgrep"
brew "tldr"
brew "tmux"
brew "tree"
brew "watch"
brew "wget"
brew "yq"
brew "zoxide"            # cd mejorado

# -----------------------------------------------------------------------------
# Dev — git, shell, testing
# -----------------------------------------------------------------------------
brew "direnv"
brew "gh"
brew "git"
brew "git-delta"
brew "git-filter-repo"
brew "gnupg"
brew "httpie"
brew "just"
brew "k6"
brew "lazygit"
brew "shellcheck"
brew "terminal-notifier"

# -----------------------------------------------------------------------------
# Lenguajes / runtimes
# -----------------------------------------------------------------------------
brew "fnm"               # Node version manager
brew "node@20", link: true
brew "node@22"
brew "go"
brew "pipx"
brew "uv"                # Python package manager
brew "oven-sh/bun/bun"

# -----------------------------------------------------------------------------
# Databases / queues
# -----------------------------------------------------------------------------
brew "libpq"
brew "pgvector"
brew "postgresql@16", restart_service: :changed
brew "postgresql@17"
brew "postgresql@18"
brew "redis", restart_service: :changed

# -----------------------------------------------------------------------------
# Cloud / infra
# -----------------------------------------------------------------------------
brew "awscli"
brew "azure-cli"
brew "cloudflared"
brew "colima"            # Docker desktop alternativo
brew "docker"
brew "kubernetes-cli"
brew "ngrok"
brew "podman"
brew "railway"
brew "tor", restart_service: :changed
brew "getsentry/tools/sentry-cli"
brew "minio/stable/mc"
brew "stripe/stripe-cli/stripe"

# -----------------------------------------------------------------------------
# Media / documentos
# -----------------------------------------------------------------------------
brew "ffmpeg"
brew "imagemagick"
brew "libavif"
brew "libpst"
brew "librsvg"
brew "pandoc"
brew "pngquant"
brew "poppler"
brew "potrace"
brew "qrencode"
brew "tectonic"          # LaTeX engine
brew "typst"
brew "whisper-cpp"

# -----------------------------------------------------------------------------
# AI / ML
# -----------------------------------------------------------------------------
brew "ollama", restart_service: :changed

# -----------------------------------------------------------------------------
# iOS / mobile
# -----------------------------------------------------------------------------
brew "cocoapods"
brew "wix/brew/applesimutils"

# -----------------------------------------------------------------------------
# Productividad CLI
# -----------------------------------------------------------------------------
brew "mas"               # Mac App Store CLI
brew "schpet/tap/linear" # Linear CLI

# =============================================================================
# Casks — apps de escritorio
# =============================================================================

# Editores / terminal
cask "cursor"
cask "iterm2"
cask "visual-studio-code"
cask "warp"

# AI / productividad
cask "chatbox"
cask "claude"            # Claude Desktop
cask "hammerspoon"       # Automation
cask "notion"
cask "raycast"
cask "rectangle"

# Comunicación
cask "discord"
cask "slack"

# Desarrollo
cask "android-studio"
cask "gcloud-cli"
cask "podman-desktop"
cask "postman"
cask "tableplus"
cask "zulu@17"           # JDK 17

# Browsers
cask "firefox"

# Diseño
cask "figma"
cask "inkscape"

# Networking / seguridad
cask "ngrok"
cask "tailscale-app"

# Tex / docs
cask "mactex-no-gui"

# Utilidades
cask "appcleaner"
cask "the-unarchiver"

# Entretenimiento
cask "spotify"

# Fuentes nerd font
cask "font-fira-code-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "font-meslo-lg-nerd-font"

# =============================================================================
# Mac App Store
# =============================================================================
mas "Telegram", id: 747648890
mas "WhatsApp", id: 310633997
mas "Windows App", id: 1295203466
mas "Xcode", id: 497799835

# =============================================================================
# VS Code / Cursor extensions
# =============================================================================
# NOTA: estas extensiones también se instalan en Cursor via setup.sh.
# Fuente actualizada: extensions.txt (formato simple por línea).

vscode "aaron-bond.better-comments"
vscode "bierner.markdown-preview-github-styles"
vscode "bradlc.vscode-tailwindcss"
vscode "christian-kohler.npm-intellisense"
vscode "christian-kohler.path-intellisense"
vscode "cweijan.dbclient-jdbc"
vscode "cweijan.vscode-database-client2"
vscode "dbaeumer.vscode-eslint"
vscode "dracula-theme.theme-dracula"
vscode "dsznajder.es7-react-js-snippets"
vscode "eamodio.gitlens"
vscode "ecmel.vscode-html-css"
vscode "editorconfig.editorconfig"
vscode "enkia.tokyo-night"
vscode "esbenp.prettier-vscode"
vscode "expo.vscode-expo-tools"
vscode "formulahendry.auto-close-tag"
vscode "formulahendry.auto-rename-tag"
vscode "github.copilot-chat"
vscode "github.github-vscode-theme"
vscode "gruntfuggly.todo-tree"
vscode "mhutchie.git-graph"
vscode "mikestead.dotenv"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-python.black-formatter"
vscode "ms-python.debugpy"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "ms-toolsai.jupyter"
vscode "ms-toolsai.jupyter-keymap"
vscode "ms-toolsai.jupyter-renderers"
vscode "ms-toolsai.vscode-jupyter-cell-tags"
vscode "ms-toolsai.vscode-jupyter-slideshow"
vscode "ms-vscode-remote.remote-containers"
vscode "ms-vscode-remote.remote-ssh"
vscode "ms-vscode-remote.remote-ssh-edit"
vscode "ms-vscode.remote-explorer"
vscode "msjsdiag.vscode-react-native"
vscode "mtxr.sqltools"
vscode "naumovs.color-highlight"
vscode "pkief.material-icon-theme"
vscode "pranaygp.vscode-css-peek"
vscode "rangav.vscode-thunder-client"
vscode "redhat.vscode-yaml"
vscode "streetsidesoftware.code-spell-checker"
vscode "usernamehw.errorlens"
vscode "vscode-icons-team.vscode-icons"
vscode "wayou.vscode-todo-highlight"
vscode "wix.vscode-import-cost"
vscode "yzhang.markdown-all-in-one"
vscode "zhuangtongfa.material-theme"
