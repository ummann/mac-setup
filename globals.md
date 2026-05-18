# Paquetes globales (npm / pipx / bun / uv)

Esta es la lista de paquetes globales que NO instala Homebrew. El `setup.sh` los
instala automáticamente al correr `--full`. Mantén esta lista al día con:

```bash
# Inventario actual
pipx list --short
npm list -g --depth=0 --global
bun pm ls -g
uv tool list
```

## pipx (Python)

```bash
pipx install black
pipx install flake8
pipx install mypy
```

## npm globals (Node)

Node se maneja con **fnm**. Versión actual: **v22.22.3** (default).

**Estado real**: actualmente solo `corepack` y `npm` están instalados como
globals reales. El resto se usa con `npx` por demanda. Si querés tener los
CLIs siempre listos (más rápido pero ocupa disco), instalarlos así:

```bash
# Gestores de paquetes
corepack enable      # habilita pnpm y yarn sin instalar globales

# Claude Code (recomendado)
npm i -g @anthropic-ai/claude-code

# CLIs frecuentemente usados (opcional — npx funciona igual)
npm i -g @railway/mcp-server      # MCP server railway
npm i -g gitnexus                 # code knowledge graph
npm i -g @playwright/mcp          # Playwright MCP
npm i -g turbo vercel wrangler    # si los usás seguido
```

> Tip: para fijar versión de Node nueva, usar `fnm install <ver> --lts && fnm default <ver>`.
> Después de instalar fnm, recargar: `eval "$(fnm env --use-on-cd)"`.

## bun (Bun runtime)

Vacío actualmente. Bun se instala como runtime via Brewfile (`oven-sh/bun/bun`).
Si llegas a usar globals, listarlos aquí.

## uv (Python runner alterno)

Vacío. `uv` está instalado via Brewfile y se usa como package manager rápido para
proyectos Python. Si agregas tools globales (`uv tool install ...`), listarlas aquí.

## Otros paquetes (no-npm/pipx)

- **pip3 user packages** (ML stack: mlx, torch, whisper, huggingface_hub, …):
  ver `pip-libs.md`.
- **Tools fuera de package managers** (opencode, maestro, gitnexus tools,
  ollama models): ver `extra-tools.md`.

## Sync rápido tras `brew bundle install`

Después de correr `setup.sh` (que ya instala fnm + Node LTS), correr:

```bash
# Python — pipx CLIs
pipx install black flake8 mypy

# Python — pip user libs (ver pip-libs.md para lista completa)
pip3 install --user mlx mlx-whisper torch huggingface_hub tiktoken \
  httpx typer rich fpdf2 openpyxl pillow Jinja2 PyYAML

# Node — habilitar pnpm/yarn sin instalar
corepack enable

# Node — CLI principal
npm i -g @anthropic-ai/claude-code
```
