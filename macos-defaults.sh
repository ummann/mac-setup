#!/bin/bash

# =============================================================================
# Configuraciones de macOS (defaults write)
# =============================================================================
# Este script configura diversas preferencias del sistema macOS
# Algunas configuraciones requieren reiniciar para aplicarse
# =============================================================================

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
log_info "Aplicando configuraciones de macOS..."
echo ""

# =============================================================================
# FINDER
# =============================================================================

log_info "Configurando Finder..."

# Mostrar archivos ocultos
defaults write com.apple.finder AppleShowAllFiles -bool true

# Mostrar todas las extensiones de archivo
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Mostrar barra de ruta
defaults write com.apple.finder ShowPathbar -bool true

# Mostrar barra de estado
defaults write com.apple.finder ShowStatusBar -bool true

# Mostrar ruta completa en título de ventana
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Buscar en carpeta actual por defecto
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Desactivar advertencia al cambiar extensión de archivo
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Evitar crear archivos .DS_Store en volúmenes de red y USB
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Vista de lista por defecto
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Mostrar iconos de discos duros, servidores y medios extraíbles en el escritorio
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# =============================================================================
# DOCK
# =============================================================================

log_info "Configurando Dock..."

# Tamaño del dock (16-128)
defaults write com.apple.dock tilesize -int 36

# Magnificación al pasar el mouse
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 48

# Auto-hide del dock
defaults write com.apple.dock autohide -bool true

# Tiempo de delay para auto-hide (0 = instantáneo)
defaults write com.apple.dock autohide-delay -float 0

# Velocidad de la animación de auto-hide
defaults write com.apple.dock autohide-time-modifier -float 0.3

# No mostrar apps recientes en el dock
defaults write com.apple.dock show-recents -bool false

# Minimizar ventanas en el icono de la app
defaults write com.apple.dock minimize-to-application -bool true

# Efecto de minimización: genie, scale, suck
defaults write com.apple.dock mineffect -string "scale"

# Posición del dock: left, bottom, right
defaults write com.apple.dock orientation -string "bottom"

# =============================================================================
# MISSION CONTROL & ESPACIOS
# =============================================================================

log_info "Configurando Mission Control..."

# No reordenar espacios basado en uso reciente
defaults write com.apple.dock mru-spaces -bool false

# Agrupar ventanas por aplicación en Mission Control
defaults write com.apple.dock expose-group-by-app -bool true

# Hot corners (esquinas activas)
# Valores posibles:
#  0: Sin acción
#  2: Mission Control
#  3: Mostrar ventanas de la aplicación
#  4: Escritorio
#  5: Iniciar protector de pantalla
#  6: Desactivar protector de pantalla
#  7: Dashboard
# 10: Poner pantalla en reposo
# 11: Launchpad
# 12: Centro de notificaciones
# 13: Lock Screen

# Esquina inferior derecha → Escritorio
defaults write com.apple.dock wvous-br-corner -int 4
defaults write com.apple.dock wvous-br-modifier -int 0

# Esquina inferior izquierda → Mission Control
defaults write com.apple.dock wvous-bl-corner -int 2
defaults write com.apple.dock wvous-bl-modifier -int 0

# =============================================================================
# TECLADO
# =============================================================================

log_info "Configurando Teclado..."

# Velocidad de repetición de teclas (menor = más rápido)
defaults write NSGlobalDomain KeyRepeat -int 2

# Delay antes de que comience la repetición (menor = más rápido)
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Desactivar auto-corrección
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Desactivar capitalización automática
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Desactivar puntos dobles como punto
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Desactivar comillas inteligentes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Desactivar guiones inteligentes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Habilitar acceso completo por teclado en diálogos
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# =============================================================================
# TRACKPAD & MOUSE
# =============================================================================

log_info "Configurando Trackpad..."

# Habilitar tap para click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Scroll natural (comentar para desactivar)
# defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# =============================================================================
# PANTALLA & SCREENSHOTS
# =============================================================================

log_info "Configurando Screenshots..."

# Guardar screenshots en ~/Desktop/Screenshots
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"

# Formato de screenshots: png, jpg, gif, pdf
defaults write com.apple.screencapture type -string "png"

# Desactivar sombra en screenshots de ventanas
defaults write com.apple.screencapture disable-shadow -bool true

# =============================================================================
# SAFARI (si lo usas)
# =============================================================================

log_info "Configurando Safari..."

# Mostrar URL completa
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Mostrar barra de estado
defaults write com.apple.Safari ShowStatusBar -bool true

# Habilitar menú Develop
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# Deshabilitar apertura automática de descargas "seguras"
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# =============================================================================
# MAIL (si lo usas)
# =============================================================================

# Copiar direcciones de email sin nombre
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# =============================================================================
# ACTIVIY MONITOR
# =============================================================================

log_info "Configurando Activity Monitor..."

# Mostrar todos los procesos
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Ordenar por CPU
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# =============================================================================
# TERMINAL
# =============================================================================

log_info "Configurando Terminal..."

# Solo usar UTF-8 en Terminal
defaults write com.apple.terminal StringEncodings -array 4

# =============================================================================
# TIME MACHINE
# =============================================================================

# No preguntar para usar nuevos discos como backup
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# =============================================================================
# APP STORE
# =============================================================================

log_info "Configurando App Store..."

# Buscar actualizaciones automáticamente
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Descargar actualizaciones en background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Instalar actualizaciones del sistema automáticamente
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

# =============================================================================
# OTROS
# =============================================================================

log_info "Aplicando otras configuraciones..."

# Expandir panel de guardar por defecto
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expandir panel de impresión por defecto
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Guardar en disco (no en iCloud) por defecto
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Cerrar siempre ventana de "descargar"
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Crash reporter como notificación en vez de ventana
defaults write com.apple.CrashReporter DialogType -string "notification"

# =============================================================================
# REINICIAR APLICACIONES AFECTADAS
# =============================================================================

echo ""
log_warn "Reiniciando aplicaciones afectadas..."

for app in "Finder" "Dock" "Safari" "SystemUIServer"; do
    killall "${app}" &> /dev/null || true
done

echo ""
log_info "✅ Configuraciones de macOS aplicadas"
log_warn "Algunas configuraciones pueden requerir reiniciar el sistema"
echo ""
