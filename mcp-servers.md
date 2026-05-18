# MCP Servers configurados

Los MCP (Model Context Protocol) servers le dan a Claude Code acceso a servicios
externos. La configuración vive en **dos lugares**:

- `~/.claude.json` → servers nivel usuario, JSON con `mcpServers`.
- `~/.claude/settings.json` → servers nivel proyecto/usuario combinado.

Cuando hay overlap entre ambos, **`~/.claude.json` gana**.

## Inventario actual

| Server | Tipo | Endpoint / comando | Notas |
|---|---|---|---|
| `github` | http | `https://api.githubcopilot.com/mcp/` | Vía Copilot, requiere `gh auth login` |
| `stripe` | http | `https://mcp.stripe.com/` | OAuth en primer uso |
| `sentry` | http | `https://mcp.sentry.dev/mcp` | OAuth en primer uso |
| `postgres` | stdio | `npx -y @bytebase/dbhub` | DB read access |
| `playwright` | stdio | `playwright-mcp --browser chromium --proxy-server socks5://127.0.0.1:9050` | Usa Tor proxy |
| `gitnexus` | stdio | `npx -y gitnexus@latest mcp` | Code knowledge graph |
| `prisma` | stdio | `npx prisma mcp` | Schema awareness |
| `railway` | stdio | `npx -y @railway/mcp-server` | Necesita `railway login` |
| `figma` | stdio | `npx -y figma-developer-mcp --stdio` | **Requiere FIGMA_API_KEY** |

⚠️ **Secret detectado**: la entrada de `figma` en `settings.json` tiene la API key
en plaintext. Mover a 1Password vault `Dev/Figma/api_key` y referenciar con
`op read "op://Dev/Figma/api_key"` desde el `env` del MCP, o usar variable
de entorno cargada por `direnv` (jamás commitear).

## Setup en una Mac nueva

Después de clonar `~/.claude` (ver `claude-config.md`), correr:

```bash
# 1. Autenticar servicios HTTP / OAuth
gh auth login                       # github MCP
# stripe y sentry → primer uso abren OAuth en el browser

# 2. Autenticar Railway
railway login

# 3. Cargar la FIGMA_API_KEY desde 1Password
op signin
op read "op://Dev/Figma/api_key"    # confirma que existe
# Editar ~/.claude/settings.json para reemplazar el valor en plaintext por
# `${FIGMA_API_KEY}` y exportar la variable desde ~/.zshrc.custom con `op read`.

# 4. Verificar
claude mcp list                     # debería listar todos
```

## Agregar un MCP server nuevo

```bash
# Server HTTP (OAuth)
claude mcp add <nombre> --type http --url https://...

# Server stdio
claude mcp add <nombre> --type stdio --command npx --args "-y,paquete@latest"
```

Después correr `claude mcp list` para confirmar.

## Troubleshooting

- **MCP server no aparece**: revisar JSON syntax con `jq . ~/.claude.json`.
- **Playwright timeout**: verificar que `tor` está corriendo (`brew services list`).
- **gitnexus no encuentra repos**: correr `/setup-gbrain` skill.
