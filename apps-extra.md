# Apps fuera de Homebrew

La mayoría de apps están en el `Brewfile`. Las siguientes se instalan manualmente
o requieren pasos adicionales.

## cmux (terminal multiplexer GUI)

Versión actual instalada: **0.63.2**

cmux NO está en Homebrew (al menos no como cask oficial al momento). Se instala
descargando el `.dmg` desde su sitio o se compila desde fuente.

```bash
# Verificar versión instalada
plutil -extract CFBundleShortVersionString raw /Applications/cmux.app/Contents/Info.plist

# Config local
ls ~/.config/cmux/
```

Helper script en `~/dotfiles/dev-tools/op-cmux.sh` que conecta cmux con el vault
de 1Password.

## Claude Desktop

Cask `claude` (incluido en `Brewfile`). Login con cuenta `angel@ummann.com`.

## Higgsfield.ai

Login manual en browser. La sesión persistente se guarda en
`~/.claude/higgsfield-session.json` para reutilizarla con Playwright MCP.

Guía: `~/.claude/memory/reference_higgsfield.md` (si existe).

## ChatGPT Desktop / Chatbox

`chatbox` está en el `Brewfile`. ChatGPT Desktop puede instalarse desde
chat.openai.com si se prefiere.

## Hammerspoon scripts

Cask `hammerspoon` (en Brewfile). Los scripts viven en `~/dotfiles/.hammerspoon/`
y se cargan automáticamente al levantar la app.

## Xcode

Vía MAS (`mas install 497799835`). Después:

```bash
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
```

## Android Studio

Cask `android-studio` (en Brewfile). Configurar SDK manualmente la primera vez.

## Apps móviles instaladas vía MAS

- Telegram (`747648890`)
- WhatsApp (`310633997`)
- Windows App (`1295203466`)
- Xcode (`497799835`)
