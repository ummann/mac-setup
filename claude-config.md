# Bootstrap de `~/.claude` (Claude Code config)

Toda la configuración de Claude Code vive en `~/.claude/` y está versionada en
un repo **privado**: [`ummann-technologies/ummann-claude-config`](https://github.com/ummann-technologies/ummann-claude-config).

Incluye:

- `agents/` — subagents personalizados (alfredo-reviewer, prometheus, atlas, momus, etc.)
- `skills/` — slash commands (uwl, deploy, design-component, qa, codex, etc.)
- `rules/` — reglas globales (alfredo-review.md, prisma.md, router.md, etc.)
- `playbooks/` — recipes para infra, security, perf, ci-cd
- `prompts/` — prompts reutilizables
- `commands/`, `hooks/`, `templates/`, `guides/`
- `CLAUDE.md` — instrucciones globales
- `settings.json` — config no-secreta (`settings.local.json` queda local)

## Restaurar en una Mac nueva

```bash
# 1. Instalar Claude Code (lo hace setup.sh con npm globals)
npm i -g @anthropic-ai/claude-code

# 2. Clonar el repo en su ubicación
git clone git@github.com:ummann-technologies/ummann-claude-config.git ~/.claude

# 3. Verificar
ls ~/.claude/{agents,skills,rules,playbooks,CLAUDE.md}
```

## Lo que NO se restaura desde git

Estos archivos quedan en `.gitignore` del repo y deben recrearse en cada Mac:

| Archivo / dir | Cómo se recrea |
|---|---|
| `~/.claude/sessions/` | Se generan al usar Claude Code |
| `~/.claude/projects/` | Memoria persistente — backup manual o vía Drive |
| `~/.claude/settings.local.json` | Permisos por máquina, se crea al primer uso |
| `~/.claude/higgsfield-session.json` | Re-loguear en higgsfield.ai con Playwright |
| `~/.claude/cache/`, `paste-cache/`, `file-history/` | Se regeneran |
| `~/.claude/telemetry/`, `shell-snapshots/` | Se regeneran |

## Sincronizar cambios locales con el repo

```bash
cd ~/.claude
git status                        # ver cambios pendientes
git add agents/ skills/ rules/    # SOLO archivos específicos, nunca `git add -A`
git commit -m "feat: add new skill X"
git push
```

⚠️ **Verificar antes de cada commit** que `settings.json` no contiene secrets
(`FIGMA_API_KEY`, tokens, etc.). Si encuentras alguno, moverlo a 1Password vault
y referenciarlo con `op://Dev/...`.

## Memoria persistente

`~/.claude/projects/-Users-angelibz/memory/` contiene MEMORY.md + archivos por
tema. **No se sincroniza con el repo público** porque puede tener info personal.
Backup recomendado:

```bash
# Comprimir y subir a Drive/Dropbox periódicamente
tar -czf ~/Documents/claude-memory-$(date +%F).tar.gz \
  -C ~/.claude/projects/-Users-angelibz memory/
```
