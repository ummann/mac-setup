# Paquetes Python user-level (pip --user)

Estos paquetes están instalados con `pip3 install --user` y NO via pipx ni brew.
Son librerías de Python que usan los scripts personales y proyectos (ML, OCR,
generación de PDFs, clientes API).

## Inventario actual

```bash
pip3 list --user
```

### ML / AI (Apple Silicon optimizado)
- `mlx` — Apple Silicon ML framework
- `mlx-metal` — backend Metal
- `mlx-whisper` — whisper en MLX
- `openai-whisper` — whisper de OpenAI (CPU/CUDA)
- `torch` — PyTorch
- `numpy`, `numba`, `scipy`, `networkx`
- `tiktoken` — tokenizer de OpenAI
- `huggingface_hub`, `hf-xet` — HuggingFace
- `higgsfield-client` — client custom para higgsfield.ai

### HTTP / async
- `httpx`, `httpcore`, `h11`, `anyio`
- `requests`, `urllib3`, `certifi`
- `idna`, `charset-normalizer`

### CLI / UX
- `typer`, `click`, `shellingham`, `rich`
- `Pygments`, `markdown-it-py`, `mdurl`

### Documentos / archivos
- `fpdf2` — generar PDFs
- `openpyxl`, `et_xmlfile` — Excel
- `pillow` — imágenes
- `fonttools`

### Otros
- `Jinja2`, `MarkupSafe`, `PyYAML`
- `tqdm`, `packaging`, `more-itertools`, `regex`
- `defusedxml`, `filelock`, `fsspec`
- `typing_extensions`, `exceptiongroup`
- `sympy`, `mpmath`, `llvmlite`
- `annotated-doc`

## Instalación bulk

```bash
pip3 install --user \
  mlx mlx-metal mlx-whisper openai-whisper torch \
  huggingface_hub tiktoken higgsfield-client \
  httpx requests \
  typer click rich \
  fpdf2 openpyxl pillow \
  Jinja2 PyYAML tqdm
```

## Capturar estado actual

Para regenerar este archivo desde la máquina actual:

```bash
pip3 list --user --format=freeze > /tmp/pip-user-freeze.txt
# Editar y curar a mano para mantener categorías
```

## ¿Por qué `pip --user` y no pipx?

- **pipx** = para CLIs aisladas (black, flake8, mypy) que se ejecutan como comandos.
- **pip --user** = librerías que importas desde scripts Python personales o
  proyectos que viven fuera de un virtualenv.
- En entornos profesionales se prefieren **virtualenvs por proyecto** (vía `uv`
  o `venv`). El uso de `pip --user` global queda para scripts ad-hoc.

## Migrar a uv (recomendado)

`uv` (en Brewfile) es 10–100× más rápido que pip y maneja virtualenvs por
proyecto. Idealmente:

```bash
# Por proyecto
cd ~/projects/nemo-api
uv venv && source .venv/bin/activate
uv pip install -r requirements.txt
```

Y mantener pip --user solo para scripts standalone.
