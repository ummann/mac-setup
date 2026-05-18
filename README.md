# Mac Setup — UMMANN

Setup automatizado completo para Mac Mini / MacBook nueva. Replica una máquina
de desarrollo idéntica: brew packages, apps, extensions VS Code/Cursor, dotfiles,
config de Claude Code (subagents, skills, rules, playbooks), MCP servers y
herramientas globales (npm, pipx, bun, uv).

## TL;DR — Mac nueva en una sola corrida

```bash
git clone https://github.com/ummann/mac-setup.git ~/mac-setup
cd ~/mac-setup
chmod +x setup.sh macos-defaults.sh
./setup.sh
```

El script es **idempotente** — si lo corres dos veces no rompe nada.

## Qué hace `setup.sh`

| Paso | Qué hace | Bandera |
|---|---|---|
| 1. Homebrew | Instala brew si no existe + taps adicionales | `INSTALL_HOMEBREW` |
| 2. **brew bundle** | Instala TODO desde `Brewfile` (formulas + casks + MAS + vscode) | `USE_BREW_BUNDLE` |
| 3. Xcode | Acepta licencia, instala via MAS si falta | `INSTALL_XCODE` |
| 4. Node (fnm) | Instala fnm + Node LTS + globals (pnpm, yarn, claude-code, turbo, vercel, …) | `INSTALL_NODE` |
| 5. Python | pipx + black, flake8, mypy | `INSTALL_PYTHON` |
| 6. Docker | Verifica Docker Desktop / Colima | `INSTALL_DOCKER` |
| 7. VS Code / Cursor | Instala `code` y `cursor` CLI + extensiones de `extensions.txt` | `INSTALL_VSCODE_EXTENSIONS` |
| 8. Git | Aliases globales, user.name, user.email, default branch main | `CONFIGURE_GIT` |
| 9. Oh My Zsh | Powerlevel10k, autosuggestions, syntax-highlighting, iterm2 themes | `INSTALL_OHMYZSH` |
| 10. macOS defaults | Finder, Dock, teclado, trackpad, Screen Sharing | `CONFIGURE_MACOS_DEFAULTS` |
| 11. **Dotfiles** | Clona `~/dotfiles` + corre `install.sh` (symlinks .zshrc, .p10k.zsh, dev-tools) | `BOOTSTRAP_DOTFILES` |
| 12. **Claude config** | Clona `~/.claude` con agents, skills, rules, playbooks, prompts | `BOOTSTRAP_CLAUDE` |

Para desactivar cualquier sección, editar las flags al inicio de `setup.sh`.

## Estructura del repo

```
mac-setup/
├── Brewfile                              # Fuente de verdad de TODO lo de Homebrew
├── apps.txt                              # Lista legacy de casks (fallback)
├── extensions.txt                        # Extensiones VS Code/Cursor (fallback)
├── globals.md                            # Paquetes globales npm / pipx / bun / uv
├── pip-libs.md                           # Python user libs (mlx, torch, whisper, etc.)
├── extra-tools.md                        # Tools fuera de PM (opencode, maestro, ollama)
├── claude-config.md                      # Bootstrap de ~/.claude (Claude Code)
├── dotfiles.md                           # Bootstrap de ~/dotfiles
├── mcp-servers.md                        # MCP servers configurados + secrets
├── apps-extra.md                         # Apps fuera de brew (cmux, Higgsfield, MAS)
├── setup.sh                              # Script principal (idempotente)
├── macos-defaults.sh                     # Defaults adicionales de macOS
├── .zshrc.custom                         # Aliases y functions zsh
├── scripts/
│   ├── setup-folder-structure.sh         # ~/projects, ~/brand-assets, ~/Documents/Fiscal
│   ├── setup-desktop-dashboard.sh        # Symlinks Desktop → carpetas reales
│   ├── setup-dock.sh                     # Dock con 9 apps premium para dev
│   ├── setup-shell.sh                    # Oh My Zsh + Powerlevel10k
│   ├── backup-old-mac.sh                 # Backup pre-migración
│   ├── restore-new-mac.sh                # Restore en máquina nueva
│   └── ...                               # (decommission, backup-services, etc.)
└── README.md                             # Este archivo
```

## Componentes principales

### `Brewfile` — fuente de verdad

Todo lo de Homebrew vive aquí: 60+ formulas, 30+ casks, 4 MAS apps, 53 extensiones
VS Code/Cursor. Mantener al día con:

```bash
brew bundle dump --force --file=Brewfile      # exporta estado actual
brew bundle install --file=Brewfile           # restaura desde el archivo
brew bundle cleanup --file=Brewfile           # muestra qué eliminar
```

### `~/dotfiles` — shell + scripts personales

Ver [`dotfiles.md`](./dotfiles.md). Incluye `.zshrc`, `.p10k.zsh`, `.hammerspoon/`,
y todo el directorio `dev-tools/` con scripts: `assign-port`, `clone-all-repos`,
`init-stack`, `start-day`, `op-cmux`, etc.

Repo: `git@github.com:ummann-technologies/dotfiles.git`

### `~/.claude` — Claude Code config

Ver [`claude-config.md`](./claude-config.md). Incluye 24 subagents personalizados
(alfredo-reviewer, prometheus, atlas, momus, design-critic, …), 60+ skills
(uwl, deploy, design-component, codex, qa, …), reglas globales (alfredo-review,
prisma, router, …) y playbooks.

Repo: `git@github.com:ummann-technologies/ummann-claude-config.git`

### `mcp-servers.md` — Model Context Protocol

Servers actuales: github, stripe, sentry, postgres, playwright, gitnexus,
prisma, railway, figma. Ver el archivo para autenticación y secrets.

### `globals.md` / `pip-libs.md` / `extra-tools.md`

- **`globals.md`**: pipx (black, flake8, mypy) y npm globals (corepack +
  claude-code recomendado; resto vía npx).
- **`pip-libs.md`**: ~50 paquetes Python user-level — ML stack (mlx, mlx-whisper,
  torch, huggingface_hub, tiktoken), HTTP (httpx, requests), CLI UX (typer,
  rich), docs (fpdf2, openpyxl, pillow), `higgsfield-client`.
- **`extra-tools.md`**: opencode (AI coding CLI), maestro (mobile UI testing),
  gitnexus tools (`~/tools/gitnexus-*`), Ollama models (llama3.1:8b,
  nomic-embed-text), UMMANN LaunchAgents.

## Personalización antes de correr

Edita las variables al inicio de `setup.sh`:

```bash
GIT_NAME="UMMANN AI"
GIT_EMAIL="angel@ummann.com"

USE_BREW_BUNDLE=true      # recomendado
BOOTSTRAP_DOTFILES=true   # requiere acceso SSH a github.com:ummann-technologies
BOOTSTRAP_CLAUDE=true     # idem
```

## Después del setup

1. **Reiniciar terminal** para cargar nueva config zsh
2. **`p10k configure`** para configurar Powerlevel10k
3. **VS Code / Cursor**: `Cmd+Shift+P` → "Shell Command: Install …" si los symlinks fallan
4. **Docker Desktop**: abrirlo y completar onboarding (o usar Colima)
5. **Autenticación**:
   ```bash
   gh auth login
   railway login
   op signin                # 1Password CLI
   ```
6. **MCP servers**: ver `mcp-servers.md` para autenticar Stripe, Sentry, Figma
7. **Scripts de workspace** (post-setup):
   ```bash
   ./scripts/setup-folder-structure.sh    # ~/projects, ~/brand-assets, ~/Documents/Fiscal
   ./scripts/setup-desktop-dashboard.sh   # Desktop como dashboard (symlinks)
   ./scripts/setup-dock.sh                # Dock con 9 apps premium para dev
   ```
   **Reglas que aplican estos scripts:**
   - `~/projects/` SOLO para repos con `.git`/`package.json`/`Cargo.toml`. Nada de PDFs, logos, FIEL.
   - `~/brand-assets/` para logos y assets por cliente/marca.
   - `~/Documents/Fiscal/` para FIEL del SAT, contratos, acuses.
   - Desktop NO queda vacío — symlinks a carpetas reales lo convierten en dashboard.
8. **SSH key** (manual, ver abajo)

## SSH key (manual por seguridad)

```bash
ssh-keygen -t ed25519 -C "angel@ummann.com"
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub
# Pegar en https://github.com/settings/keys
```

## Sincronizar cambios

Cuando agregues una app, extension o cambies dotfiles:

```bash
# Brewfile
brew bundle dump --force --file=~/mac-setup/Brewfile
cd ~/mac-setup
git diff Brewfile                # revisar
git add Brewfile
git commit -m "feat(brew): add <package>"

# Extensions
code --list-extensions > ~/mac-setup/extensions.txt   # o curado a mano

# Dotfiles
cd ~/dotfiles
git status
git add <archivos-específicos>    # NUNCA git add -A
git commit -m "feat(dev-tools): describe change"
git push

# Claude config
cd ~/.claude
git add agents/ skills/ rules/
git commit -m "feat(claude): describe change"
git push
```

## Troubleshooting

### "Command Line Tools for Xcode" se queda colgado

`softwareupdate` no muestra progreso. Verificar en
**System Settings → General → Software Update**. Tarda 5–15 min.

### Homebrew no en PATH después de instalar

```bash
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel
eval "$(/usr/local/bin/brew shellenv)"
```

### `fnm` no en PATH

```bash
echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
exec zsh
```

### Brewfile install falla en MAS apps

Login en App Store primero. Si falla un MAS app específico (no comprado o
sin licencia), comenta esa línea en `Brewfile`.

### Bootstrap de `~/.claude` o `~/dotfiles` falla

```bash
# Verifica acceso SSH a GitHub
ssh -T git@github.com

# Si falla, configura SSH key (ver arriba) o usa HTTPS:
git clone https://github.com/ummann-technologies/dotfiles.git ~/dotfiles
git clone https://github.com/ummann-technologies/ummann-claude-config.git ~/.claude
```

## Licencia

MIT — uso interno UMMANN.
