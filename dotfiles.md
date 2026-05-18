# Bootstrap de `~/dotfiles`

Repo: [`ummann-technologies/dotfiles`](https://github.com/ummann-technologies/dotfiles)

Contiene:

- `.zshrc`, `.zshrc.custom`, `.p10k.zsh` — shell config
- `.hammerspoon/` — automatizaciones macOS (window mgmt, hotkeys)
- `dev-tools/` — scripts personales:
  - `assets.sh`, `assign-port.sh`, `brief.sh`, `clone-all-repos.sh`
  - `close-projects.sh`, `db.sh`, `deploy.sh`, `deps.sh`
  - `fetch-railway-staging-envs.sh`, `gs.sh`
  - `init-stack.sh` — bootstrap de proyecto nuevo
  - `linear-projects.conf`, `local-ports.conf` — registros
  - `logs.sh`, `nuke.sh`, `op-cmux.sh`, `open-projects.sh`
  - `organize-desktops.sh`, `p.sh`, `ping.sh`
  - `placeholders/` — templates `.env`, `mcp.json`, etc.
  - `ports.sh`, `prs.sh`, `pull-all.sh`
  - `secrets-vault.md` — workflow del 1Password vault `Dev`
  - `start-day.sh`

## Restaurar en una Mac nueva

```bash
# 1. Clonar
git clone git@github.com:ummann-technologies/dotfiles.git ~/dotfiles

# 2. Correr el installer (crea symlinks ~/.zshrc -> ~/dotfiles/.zshrc, etc.)
~/dotfiles/install.sh

# 3. Verificar
ls -la ~/.zshrc ~/.zshrc.custom ~/.p10k.zsh ~/.hammerspoon
ls ~/dotfiles/dev-tools/

# 4. Recargar shell
exec zsh
```

## Convenciones del registry de puertos

El archivo `~/dotfiles/dev-tools/local-ports.conf` mantiene rangos de 100 por
proyecto. Asignar nuevos puertos con:

```bash
~/dotfiles/dev-tools/assign-port.sh <nombre-proyecto>
ports                                # ver registro
```

## 1Password vault `Dev`

`~/dotfiles/dev-tools/secrets-vault.md` documenta el workflow completo. Resumen:

- Vault `Dev` en 1Password contiene credenciales por proyecto.
- Templates en `~/dotfiles/dev-tools/placeholders/` usan referencias `op://Dev/...`.
- `init-stack.sh` resuelve las referencias al hidratar `.env` de un proyecto nuevo.

Alias relevantes (definidos en `.zshrc.custom`):

```bash
op   # alias → opp (1Password CLI)
opc  # op-cmux.sh helper
```

## Sincronizar cambios

```bash
cd ~/dotfiles
git status
git add dev-tools/<archivo-especifico>   # nunca `git add -A`
git commit -m "feat(dev-tools): describe change"
git push
```
