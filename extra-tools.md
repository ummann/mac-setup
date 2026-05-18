# Tools fuera de Homebrew / pip / npm

Herramientas instaladas con installers propios o source builds. Documentadas
aquí para restauración manual en una Mac nueva.

## opencode

CLI AI coding assistant (`Mach-O arm64` en `~/.opencode/bin/opencode`).

```bash
# Install (instalador oficial)
curl -fsSL https://opencode.ai/install | bash

# Verificar
which opencode
opencode --version
```

PATH: `export PATH=$HOME/.opencode/bin:$PATH` (ya está en `~/.zshrc`).

## Maestro (mobile UI testing)

Instalado en `~/.maestro/bin/` con el installer oficial.

```bash
# Install
curl -fsSL "https://get.maestro.mobile.dev" | bash

# Verificar
maestro --version
```

PATH: `export PATH=$PATH:$HOME/.maestro/bin` (ya en `~/.zshrc`).

## GitNexus tools (~/tools/gitnexus-*)

Scripts personales para correr GitNexus localmente (API server + web UI).
Viven en `~/tools/` (NO en dotfiles).

Archivos:
- `~/tools/gitnexus-start.sh` — levanta API (puerto 4747) + Web UI (5173)
- `~/tools/gitnexus-stop.sh` — los detiene
- `~/tools/gitnexus-index-all.sh` — indexa todos los repos de ~/projects
- `~/tools/gitnexus-src/` — source del web UI clonado de gitnexus repo

### Restaurar en máquina nueva

```bash
mkdir -p ~/tools && cd ~/tools

# Clonar el web UI source
git clone https://github.com/gitnexus/gitnexus.git gitnexus-src

# Los scripts gitnexus-*.sh hay que recuperarlos del backup
# (o pedirlos a Claude para regenerar a partir de los aliases del .zshrc)
```

Aliases en `~/.zshrc` (vienen de dotfiles):
- `gnx-start`, `gnx-stop`, `gnx-ui`, `gnx-api`
- `gnx-reindex`, `gnx-reindex-all`
- `gnx-status`, `gnx-list`, `gnx-clean`, `gnx-wiki`, `gnx-logs`

## Ollama models

Modelos descargados (verificar con `ollama list`):

```bash
ollama pull nomic-embed-text       # 274 MB — embeddings
ollama pull llama3.1:8b            # 4.9 GB — chat model
```

## cmux (terminal multiplexer GUI)

Ya documentado en `apps-extra.md`. v0.63.2 instalado manualmente en
`/Applications/cmux.app/`.

## UMMANN LaunchAgents

Estos daemons corren en background via launchctl. Sus `.plist` viven en
`~/Library/LaunchAgents/` pero los binarios/scripts a los que apuntan están
DENTRO de cada proyecto. NO se restauran desde mac-setup, sino corriendo el
installer de cada proyecto.

| Agent | Origen |
|---|---|
| `com.ummann.tt-tracker` | (proyecto interno) |
| `ai.ummann.whatsapp-bridge` | `~/projects/ummann-ai/apps/whatsapp-bridge` |
| `com.ummann.notes-digest` | (proyecto interno) |
| `com.ummann.morning-whatsapp-summary` | (proyecto interno) |
| `com.ummann.tunnel-watchdog` | (proyecto interno) |
| `com.nemo.api`, `com.nemo.daemon`, `com.nemo.workers` | `~/projects/ummann-ai/apps/nemo-api` |

Para listar los que están corriendo:

```bash
launchctl list | grep -E "ummann|nemo"
```

Cada proyecto tiene su propio script `install-*-daemon.sh` para crear el plist
y registrar el agent. Ver `nemo-claude-hook.sh` en `/usr/local/bin/` (symlink
a un script de nemo-api).

## Hammerspoon Spoons

`~/.hammerspoon/init.lua` es symlink a `~/dotfiles/.hammerspoon/init.lua`.
Los Spoons (plugins) viven en `~/.hammerspoon/Spoons/`. Si se quieren versionar:

```bash
ls ~/.hammerspoon/Spoons/
# Documentar los Spoons usados aquí
```

## SSH config

`~/.ssh/config` y `~/.ssh/known_hosts` NO se versionan (sensibles + per-host).
Pero el contenido de `~/.ssh/config` se puede backupear manualmente. Los
`id_*` keys siempre se generan en cada máquina.
