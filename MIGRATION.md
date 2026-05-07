# 🚚 Migración Mac → Mac

Guía completa para migrar tu entorno de desarrollo entre Macs sin perder nada.

## TL;DR

```bash
# === EN MAC VIEJA ===
cd ~/projects/mac-setup
git pull
./scripts/backup-old-mac.sh      # configs + repos + envs (cifrado)
./scripts/backup-services.sh     # LaunchAgents + DBs + state runtime (cifrado)

# Copiar ~/mac-migration/ a la mac nueva (AirDrop, USB, iCloud, rsync)

# === EN MAC NUEVA ===
git clone https://github.com/ummann/mac-setup.git
cd mac-setup
./setup.sh                                       # tools, apps, brew (15-30 min)
./scripts/setup-shell.sh                         # dotfiles + ~/.claude
./scripts/restore-new-mac.sh ~/mac-migration/    # configs + repos + envs
./scripts/restore-services.sh ~/mac-migration/   # daemons + DBs + state
```

---

## 📋 Inventario al 2026-05-06

### Orgs de GitHub
- **`ummann`** (12 repos): ummann-ai, dictamed-ia, barebatravels, ummove-deck, nemo, mac-setup, ummtime, inaf, gcc-erp, facturacion-auto, BarebaConnect, ummann.github.io, ummann-claude-config, dev-tools
- **`ummann-technologies`** (11 repos): dotfiles, arquitecturacanfield, whatsapp-mcp, sigen, inaf-v2, inaf-entrenadores, tt-tracker, toc-toc-doc, nemo, inaf
- **`Ummove-technologies`** (1 repo): Ummove
- **Externos**: `fuzzyflags/adepthr-ar-portal`, `fuzzyflags/prestige-installers-dashboard`, `Creadores-en-Potencia/cep`

### 🚨 Riesgos antes de migrar
Estos repos están solo en tu mac — si la pierdes, **se va el código**:
- `canfield-oc-matcher` — 253 archivos sin commitear, **sin remote**
- `sat-fiscal` — 38 archivos, **sin remote**
- `skool` — 22 archivos, **sin remote**
- `asia-inspection-research` — **sin git**
- `adepthr-ar-portal` — 5 commits sin pushear

El script `backup-old-mac.sh` te avisa de cada uno y los empaqueta en el tarball.

---

## 🔧 Qué se respalda

### `backup-services.sh` — daemons y state runtime (cifrado)
- **LaunchAgents** `~/Library/LaunchAgents/*.plist` (filtra UMMANN, nemo, brew services, cloudflare)
- **Postgres** `pg_dump -Fc` por DB (nemo, adepthr_*, etc.) + `pg_dumpall --globals-only`
- **Redis** `dump.rdb` (con `BGSAVE` previo para snapshot fresco)
- **cmux state** `~/Library/Application Support/cmux/` (sin el socket)
- **uwl state** `~/.uwl/` (sessions, summaries, exec)
- **whatsapp-mcp** SQLite DBs (mensajes, contactos)
- **Runtime snapshot** (procesos activos, puertos, custom binaries) para diagnóstico

### `backup-old-mac.sh` — configs sensibles (cifradas en el tarball)
- `~/.ssh/` — keys, config, known_hosts, authorized_keys
- `~/.gitconfig`, `~/.gitignore_global`
- `~/.gnupg/` (si existe)
- `~/.aws/`, `~/.gcloud/`, `~/.config/gcloud/`
- `~/.cloudflared/`, `~/.railway/`, `~/.docker/`
- `~/.eas-creds`, `~/.expo/`
- `~/.bash_profile`, `~/.zshrc`, `~/.zshrc.custom`, `~/.zprofile`, `~/.p10k.zsh`
- `~/.npmrc`, `~/.pnpmrc`, `~/.yarnrc`
- `~/.claude/` (agents, commands, hooks, memories, playbooks, prompts, rules, sessions, settings)
- `~/.cursor/`, `~/.opencode/`, `~/.copilot/`
- `~/.hammerspoon/`
- `~/.iterm2-colors/`
- `~/.config/` completo

### `.env*` files de cada proyecto
Se inventarian todos los `.env`, `.env.local`, `.env.staging`, `.env.production`, `.env.example`, `.env.keys` y se empacan en `envs.tar.gz` dentro del backup.

### Inventarios
- `brew leaves` y `brew list --cask` → `brew-installed.txt`
- `npm ls -g --depth=0` → `npm-globals.txt`
- `pnpm ls -g --depth=0` → `pnpm-globals.txt`
- `code --list-extensions` → `vscode-extensions.txt`
- `cursor --list-extensions` → `cursor-extensions.txt`
- `mas list` → `mas-apps.txt` (Mac App Store)
- `ls /Applications` → `apps.txt`
- `nvm ls` → `node-versions.txt`

### Estado de repos
- `git-status.txt` con remote, branch, dirty count, unpushed commits por repo
- `repos-no-remote.txt` con los repos en peligro
- `wip-summary.txt` con todos los archivos modificados sin commitear

---

## 🛠️ Pasos manuales (NO automatizables)

Estos no los puede hacer el script — hazlos tú:

### Antes de migrar
- [ ] **Sign out de iCloud** en System Settings (después de copiar el tarball)
- [ ] **Logout de apps**: 1Password, Slack, Discord, Notion, Spotify
- [ ] **Backup de Time Machine** completo de la mac vieja (opcional pero recomendado)
- [ ] **Exportar bookmarks** de navegadores si no usas sync
- [ ] **Mensajes de iMessage** — habilitar iCloud sync
- [ ] **Notas, Reminders, Photos** — verificar que están en iCloud
- [ ] Revisar `~/Desktop/` y `~/Documents/` y mover lo importante a un proyecto o iCloud

### Cuentas y tokens a re-loguear en la mac nueva
- [ ] `gh auth login` (GitHub CLI)
- [ ] `claude login` (si usas web)
- [ ] `railway login`
- [ ] `vercel login`
- [ ] `firebase login`
- [ ] `eas login` (Expo)
- [ ] `gcloud auth login`
- [ ] `stripe login`
- [ ] `cloudflared login` o `wrangler login`
- [ ] `npm login` si tienes paquetes privados
- [ ] Docker Desktop login
- [ ] Cursor account
- [ ] App Store + Mac App Store con tu Apple ID

### Autorizaciones de hardware/software
- [ ] Authorize iTunes/Music con tu Apple ID (max 5 macs)
- [ ] Re-license apps de pago: TablePlus, Sublime, etc.
- [ ] Re-pairing de dispositivos Bluetooth
- [ ] Activar Touch ID en Terminal/sudo (`sudo` + edit `/etc/pam.d/sudo`)

---

## 🔥 Limpieza opcional de la mac vieja

Después de verificar que TODO funciona en la nueva:

```bash
# Wipe seguro (recomendado antes de vender/regalar)
# System Settings > General > Transfer or Reset > Erase All Content
```

---

## 📚 Referencias

- `setup.sh` — instala todo desde cero (corre primero en mac nueva)
- `macos-defaults.sh` — defaults de macOS (Finder, Dock, etc.)
- `scripts/setup-shell.sh` — clona dotfiles + ummann-claude-config
- `scripts/backup-old-mac.sh` — configs + repos + envs
- `scripts/restore-new-mac.sh` — restaura configs + clona repos
- `scripts/backup-services.sh` — LaunchAgents + DBs + cmux/uwl state
- `scripts/restore-services.sh` — restaura daemons + DBs + state
- `Brewfile`, `apps.txt`, `extensions.txt`, `cursor-extensions.txt`, `mas-apps.txt`

---

## 🆘 Si algo falla

- El backup queda en `~/mac-migration/` con tarball cifrado + checksums
- Los repos sin remote se mueven a `~/mac-migration/standalone-repos/` como bundles git
- Cada `.env` queda en `~/mac-migration/envs/` con su path original

Mensaje al final del script: si ves "✅ Backup completo" estás listo para migrar.
