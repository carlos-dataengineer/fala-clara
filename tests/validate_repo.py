"""Valida a estrutura do repositório Fala Clara.

Uso:
    python tests/validate_repo.py

Termos que nunca podem aparecer (dados privados) vão na variável
FALA_CLARA_PROIBIDOS, separados por vírgula.
"""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILL = ROOT / "skills" / "fala-clara"
erros: list[str] = []


def falha(msg: str) -> None:
    erros.append(msg)


def ler(p: Path) -> str:
    return p.read_text(encoding="utf-8")


def frontmatter(texto: str) -> dict[str, str]:
    m = re.match(r"^---\n(.*?)\n---\n", texto, re.S)
    if not m:
        return {}
    dados: dict[str, str] = {}
    for linha in m.group(1).splitlines():
        if linha and not linha.startswith(" ") and ":" in linha:
            chave, valor = linha.split(":", 1)
            dados[chave.strip()] = valor.strip()
    return dados


# 1. Arquivos obrigatórios ---------------------------------------------------
obrigatorios = [
    "README.md", "LICENSE", "CHANGELOG.md", "CONTRIBUTING.md", "CODE_OF_CONDUCT.md",
    "SECURITY.md", "SUPPORT.md", "VERSION", ".gitattributes", ".gitignore",
    "install.ps1", "install.sh", "uninstall.ps1", "uninstall.sh",
    "ativacao/sempre-ativo.md", "ativacao/preferencias-claude-ai.txt",
    ".claude-plugin/plugin.json", ".claude-plugin/marketplace.json", "hooks/hooks.json",
    "skills/fala-clara/SKILL.md", "docs/como-funciona.md",
]
for rel in obrigatorios:
    if not (ROOT / rel).is_file():
        falha(f"Falta o arquivo {rel}")

# 2. SKILL.md ----------------------------------------------------------------
skill_md = ler(SKILL / "SKILL.md")
fm = frontmatter(skill_md)
if fm.get("name") != "fala-clara":
    falha("SKILL.md: 'name' precisa ser fala-clara (igual ao nome da pasta)")
if not re.fullmatch(r"[a-z0-9-]{1,64}", fm.get("name", "")):
    falha("SKILL.md: 'name' só com minúsculas, números e hífen (até 64)")
desc = fm.get("description", "")
if not desc:
    falha("SKILL.md: falta 'description'")
if len(desc) > 1024:
    falha(f"SKILL.md: 'description' tem {len(desc)} caracteres (máximo 1024)")
if "<" in desc or ">" in desc:
    falha("SKILL.md: 'description' não pode ter < ou >")
if len(skill_md.splitlines()) >= 500:
    falha("SKILL.md: precisa ter menos de 500 linhas")

for link in re.findall(r"\]\((references/[^)]+)\)", skill_md):
    if not (SKILL / link).is_file():
        falha(f"SKILL.md: link quebrado {link}")

# 3. Versões coerentes -------------------------------------------------------
versao = ler(ROOT / "VERSION").strip()
if not re.fullmatch(r"\d+\.\d+\.\d+", versao):
    falha(f"VERSION inválida: {versao!r}")
m = re.search(r"^\s+version:\s*([\d.]+)\s*$", skill_md, re.M)
if not m or m.group(1) != versao:
    falha("SKILL.md: metadata.version difere de VERSION")
if f"## [{versao}]" not in ler(ROOT / "CHANGELOG.md"):
    falha(f"CHANGELOG.md não tem a seção [{versao}]")

# 4. Plugin, marketplace e gancho --------------------------------------------
try:
    plugin = json.loads(ler(ROOT / ".claude-plugin/plugin.json"))
    market = json.loads(ler(ROOT / ".claude-plugin/marketplace.json"))
    hooks = json.loads(ler(ROOT / "hooks/hooks.json"))
except json.JSONDecodeError as e:
    falha(f"JSON inválido: {e}")
else:
    if plugin.get("name") != "fala-clara":
        falha("plugin.json: name precisa ser fala-clara")
    if plugin.get("version") != versao:
        falha("plugin.json: version difere de VERSION")
    plugins = market.get("plugins", [])
    if not plugins or plugins[0].get("name") != "fala-clara":
        falha("marketplace.json: precisa listar o plugin fala-clara")
    elif plugins[0].get("version") != versao or market.get("metadata", {}).get("version") != versao:
        falha("marketplace.json: versões diferem de VERSION")
    comandos = [
        h.get("command", "")
        for grupo in hooks.get("hooks", {}).get("SessionStart", [])
        for h in grupo.get("hooks", [])
    ]
    if not any("ativacao/sempre-ativo.md" in c for c in comandos):
        falha("hooks.json: o SessionStart precisa imprimir ativacao/sempre-ativo.md")

# 5. Instaladores ------------------------------------------------------------
for nome in ("install.ps1", "uninstall.ps1"):
    dados = (ROOT / nome).read_bytes()
    if dados.startswith(b"\xef\xbb\xbf"):
        falha(f"{nome}: não pode ter BOM")
    try:
        dados.decode("ascii")
    except UnicodeDecodeError:
        falha(f"{nome}: precisa ser ASCII puro (PowerShell 5.1 e irm | iex)")

inicio = "<!-- fala-clara:inicio"
fim = "<!-- fala-clara:fim -->"
for nome in ("install.ps1", "install.sh", "uninstall.ps1", "uninstall.sh"):
    texto = ler(ROOT / nome)
    if fim not in texto or (inicio not in texto):
        falha(f"{nome}: marcadores do bloco sempre ativo ausentes")
marcador_ps1 = re.search(r"\$Begin = '([^']+)'", ler(ROOT / "install.ps1"))
marcador_sh = re.search(r'BEGIN="([^"]+)"', ler(ROOT / "install.sh"))
if not (marcador_ps1 and marcador_sh and marcador_ps1.group(1) == marcador_sh.group(1)):
    falha("install.ps1 e install.sh precisam usar o mesmo marcador de início")

# 6. Ativação curta e coerente -----------------------------------------------
bloco = ler(ROOT / "ativacao/sempre-ativo.md")
if len(bloco) > 2500:
    falha(f"sempre-ativo.md tem {len(bloco)} caracteres; mantenha abaixo de 2500")
if "fala-clara" not in bloco:
    falha("sempre-ativo.md precisa citar a skill fala-clara")
if len(ler(ROOT / "ativacao/preferencias-claude-ai.txt")) > 1500:
    falha("preferencias-claude-ai.txt precisa caber nas preferências do perfil (até 1500 caracteres)")

# 7. Links locais do README e docs -------------------------------------------
for doc in ("README.md", "docs/como-funciona.md", "CONTRIBUTING.md", "SUPPORT.md"):
    base = (ROOT / doc).parent
    for alvo in re.findall(r"\]\(([^)#\s]+)\)", ler(ROOT / doc)):
        if re.match(r"[a-z]+:", alvo):
            continue
        if not (base / alvo).exists():
            falha(f"{doc}: link quebrado {alvo}")

# 8. Termos privados ---------------------------------------------------------
proibidos = [t.strip().lower() for t in os.environ.get("FALA_CLARA_PROIBIDOS", "").split(",") if t.strip()]
if proibidos:
    for arq in ROOT.rglob("*"):
        if not arq.is_file() or ".git" in arq.parts or arq.suffix in {".png", ".zip"}:
            continue
        try:
            texto = arq.read_text(encoding="utf-8").lower()
        except UnicodeDecodeError:
            continue
        for termo in proibidos:
            if re.search(rf"\b{re.escape(termo)}\b", texto):
                falha(f"{arq.relative_to(ROOT)}: contém termo privado '{termo}'")

if erros:
    print("Problemas encontrados:")
    for e in erros:
        print(f"  - {e}")
    sys.exit(1)
print(f"Tudo certo: Fala Clara {versao} validado.")
