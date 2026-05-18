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

```bash
# Gestores de paquetes
npm i -g pnpm yarn corepack

# Claude Code + Anthropic
npm i -g @anthropic-ai/claude-code

# Frameworks / CLIs
npm i -g typescript ts-node
npm i -g turbo
npm i -g vercel
npm i -g netlify-cli
npm i -g wrangler
npm i -g firebase-tools
npm i -g eas-cli
npm i -g expo-cli
npm i -g @angular/cli
npm i -g @sentry/cli
```

> Tip: para fijar versión de Node nueva, usar `fnm install <ver> --lts && fnm default <ver>`.

## bun (Bun runtime)

Vacío actualmente. Bun se instala como runtime via Brewfile (`oven-sh/bun/bun`).
Si llegas a usar globals, listarlos aquí.

## uv (Python runner alterno)

Vacío. `uv` está instalado via Brewfile y se usa como package manager rápido para
proyectos Python. Si agregas tools globales (`uv tool install ...`), listarlas aquí.

## Sync rápido tras `brew bundle install`

```bash
~/mac-setup/setup.sh --globals       # corre solo esta sección
```

Si el script no existe ese flag aún (rev antigua), correr la sección manualmente:

```bash
# Python
pipx install black flake8 mypy

# Node
fnm install --lts && fnm default 22 && eval "$(fnm env)"
npm i -g pnpm yarn @anthropic-ai/claude-code typescript ts-node turbo vercel \
  wrangler firebase-tools eas-cli expo-cli @angular/cli @sentry/cli netlify-cli
```
