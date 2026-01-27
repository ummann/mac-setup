# 🖥️ Mac Setup Automatizado

Script de configuración automatizada para Mac Mini/MacBook nueva con todas las herramientas, aplicaciones y configuraciones necesarias para desarrollo.

## ✨ Características

- ✅ **Idempotente**: Puede ejecutarse múltiples veces sin problemas
- ✅ **Manejo de errores**: Continúa ejecutándose si algo falla
- ✅ **Detección de arquitectura**: Compatible con Intel y Apple Silicon
- ✅ **Modular**: Activa/desactiva secciones según necesites
- ✅ **Backup automático**: Respalda archivos existentes antes de sobrescribir

## 📦 ¿Qué instala?

### Herramientas CLI
- **Core:** git, gh, wget, curl, tree, jq, yq, htop, tldr
- **Modern Utils:** ripgrep, fd, bat, eza, fzf, zoxide, procs, dust, duf
- **Development:** tmux, httpie, shellcheck, direnv, lazygit, delta, gnupg
- **Databases:** postgresql, redis
- **Cloud:** awscli, kubectl, stripe, gcloud

### Lenguajes y Runtimes
- Node.js (última LTS via nvm)
- npm, yarn, pnpm
- Python 3 con pipx

### CLIs Globales (npm)
- eas-cli, expo-cli (React Native/Expo)
- firebase-tools
- vercel, netlify-cli
- typescript, ts-node
- @angular/cli

### Aplicaciones
- Navegadores: Chrome, Firefox
- Editores: VS Code, Cursor
- Terminal: iTerm2, Warp
- Productividad: Rectangle, Raycast, Notion, Figma
- Desarrollo: Docker, Postman, TablePlus, Android Studio
- Cloud: Google Cloud SDK
- Comunicación: Slack, Discord
- Entretenimiento: Spotify

### Extensiones VS Code
- Prettier, ESLint, Tailwind CSS
- GitLens, GitHub Copilot
- Python, Docker
- Y muchas más...

### Configuraciones
- Oh My Zsh con Powerlevel10k
- Plugins: autosuggestions, syntax-highlighting
- Aliases y funciones útiles
- Configuraciones de macOS optimizadas

## 🚀 Uso Rápido

```bash
# Clonar el repositorio
git clone https://github.com/UMMANNAI/mac-setup.git
cd mac-setup

# Dar permisos de ejecución
chmod +x setup.sh macos-defaults.sh

# Ejecutar
./setup.sh
```

## ⚙️ Personalización

Antes de ejecutar, edita las variables al inicio de `setup.sh`:

```bash
# === PERSONALIZACIÓN ===
GIT_NAME="UMMANN AI"
GIT_EMAIL="angel@ummann.com"

# Activar/desactivar secciones
INSTALL_NODE=true
INSTALL_PYTHON=true
INSTALL_DOCKER=true
INSTALL_OHMYZSH=true
CONFIGURE_MACOS_DEFAULTS=true

# Apps adicionales
EXTRA_CASK_APPS="figma notion zoom"
```

## 📁 Estructura de Archivos

```
mac-setup/
├── setup.sh              # Script principal
├── macos-defaults.sh     # Configuraciones de macOS
├── apps.txt              # Lista de apps Homebrew Cask
├── extensions.txt        # Extensiones de VS Code
├── Brewfile              # Para brew bundle
├── .zshrc.custom         # Configuraciones custom de zsh
└── README.md             # Este archivo
```

## 📝 Archivos de Configuración

### `apps.txt`
Lista de aplicaciones para instalar via Homebrew Cask. Una app por línea, las líneas que comienzan con `#` son ignoradas.

### `extensions.txt`
Lista de extensiones de VS Code. Usa el ID de la extensión (ej: `esbenp.prettier-vscode`).

### `Brewfile`
Archivo para `brew bundle`. Alternativa a ejecutar el script, puedes usar:
```bash
brew bundle install --file=Brewfile
```

### `.zshrc.custom`
Aliases, funciones y configuraciones de zsh. Este archivo se copia a `~/.zshrc.custom` y se incluye en tu `.zshrc`.

### `macos-defaults.sh`
Configuraciones de macOS usando `defaults write`. Incluye:
- Finder: mostrar archivos ocultos, extensiones, barra de ruta
- Dock: tamaño, auto-hide, sin apps recientes
- Teclado: velocidad de repetición
- Screenshots: ubicación y formato
- Y más...

## 🔧 Después de la Instalación

### 1. Reinicia la terminal
Para aplicar los cambios de zsh y Oh My Zsh.

### 2. Configura los colores del terminal (Powerlevel10k)
```bash
p10k configure
```
Esto te guiará para elegir colores, iconos y estilo del prompt.

### 3. Activa los iconos en Cursor/VS Code
1. Abre **Cursor** o **VS Code**
2. Presiona `Cmd + Shift + P`
3. Escribe: **"File Icon Theme"**
4. Selecciona **"Material Icon Theme"**

### 4. Configura colores de iTerm2 (opcional)
Los temas de colores se descargan automáticamente en `~/.iterm2-colors/`. Para activarlos:
1. Abre **iTerm2** → **Settings** (`Cmd + ,`)
2. Ve a **Profiles** → **Colors** → **Color Presets** → **Import**
3. Navega a `~/.iterm2-colors/` y selecciona un tema:
   - `Dracula.itermcolors` (morado oscuro)
   - `Nord.itermcolors` (azul frío)
   - `Catppuccin-Mocha.itermcolors` (pastel cálido)
   - `Tokyo-Night.itermcolors` (azul/morado)
   - `One-Dark.itermcolors` (estilo Atom)
4. Después de importar, selecciónalo del menú desplegable

### 5. Inicia Docker Desktop
Abre Docker Desktop y completa la configuración inicial.

### 6. Personaliza ~/.zshrc.custom
Edita según tus preferencias para aliases y funciones adicionales.

## 🔐 Generación de SSH Key

El script no genera SSH keys por seguridad. Hazlo manualmente:

```bash
# Generar nueva SSH key
ssh-keygen -t ed25519 -C "angel@ummann.com"

# Iniciar ssh-agent
eval "$(ssh-agent -s)"

# Agregar al agent
ssh-add ~/.ssh/id_ed25519

# Copiar clave pública
pbcopy < ~/.ssh/id_ed25519.pub
```

Luego agrégala a [GitHub](https://github.com/settings/keys).

## 🛠️ Solución de Problemas

### Xcode Command Line Tools no se descarga / sin progreso

Durante la instalación de Homebrew, el script descarga Xcode Command Line Tools. Si el terminal se queda en "Downloading Command Line Tools for Xcode" sin mostrar progreso:

1. El comando `softwareupdate` de macOS **no muestra barra de progreso** en terminal - esto es normal
2. La descarga está ocurriendo en segundo plano (~500MB-1GB, puede tomar 5-15 minutos)
3. Para verificar el progreso, abre **System Settings → General → Software Update**
4. Si ves "Command Line Tools for Xcode" bajo "Other Updates", haz clic en **"Update Now"** para iniciar/continuar la descarga
5. Una vez completada la descarga, el script continuará automáticamente

### Homebrew no encontrado después de instalación
```bash
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel
eval "$(/usr/local/bin/brew shellenv)"
```

### nvm no encontrado
```bash
source ~/.zshrc
# o
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### Permisos denegados
```bash
sudo chown -R $(whoami) /usr/local/lib /usr/local/include
```

## 📄 Licencia

MIT - Usa y modifica libremente.

---

¡Disfruta tu nueva Mac! 🎉
