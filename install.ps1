<#
.SYNOPSIS
  Instala o Fala Clara: a skill de comunicacao clara para Claude Code e Codex, ja ativa.

.DESCRIPTION
  1. Baixa o Fala Clara do GitHub (ou usa a pasta local, se rodar de um clone).
  2. Copia a skill "fala-clara" para:
       ~/.claude/skills/fala-clara   (Claude Code)
       ~/.codex/skills/fala-clara    (Codex; respeita CODEX_HOME)
       ~/.agents/skills/fala-clara   (pasta compartilhada entre agentes)
  3. Deixa a skill SEMPRE ATIVA: coloca um bloco marcado em
       ~/.claude/CLAUDE.md   e   ~/.codex/AGENTS.md
     (faz backup antes; o desinstalador tira so esse bloco).

.EXAMPLE
  irm https://raw.githubusercontent.com/carlos-dataengineer/fala-clara/main/install.ps1 | iex

.EXAMPLE
  .\install.ps1 -SkipCodex -NoAlwaysOn

.NOTES
  Via "irm | iex", use variaveis de ambiente no lugar dos parametros:
    $env:FALA_CLARA_SKIP_CLAUDE = '1'; $env:FALA_CLARA_SKIP_CODEX = '1'
    $env:FALA_CLARA_NO_ALWAYS_ON = '1'; $env:FALA_CLARA_REF = 'v1.0.0'
  FALA_CLARA_HOME troca a pasta inicial (usado nos testes).
#>
[CmdletBinding()]
param(
  [switch]$SkipClaude,
  [switch]$SkipCodex,
  [switch]$NoAlwaysOn,
  [string]$Ref = ''
)

$ErrorActionPreference = 'Stop'
$Repo = 'carlos-dataengineer/fala-clara'
$Name = 'fala-clara'
$Begin = '<!-- fala-clara:inicio (gerenciado pelo instalador do Fala Clara; nao edite dentro deste bloco) -->'
$End = '<!-- fala-clara:fim -->'

if ($env:FALA_CLARA_SKIP_CLAUDE -eq '1') { $SkipClaude = $true }
if ($env:FALA_CLARA_SKIP_CODEX -eq '1') { $SkipCodex = $true }
if ($env:FALA_CLARA_NO_ALWAYS_ON -eq '1') { $NoAlwaysOn = $true }
if (-not $Ref) { $Ref = if ($env:FALA_CLARA_REF) { $env:FALA_CLARA_REF } else { 'main' } }
$HomeDir = if ($env:FALA_CLARA_HOME) { $env:FALA_CLARA_HOME } else { $HOME }
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HomeDir '.codex' }

$Utf8 = New-Object System.Text.UTF8Encoding($false)
function Write-Step([string]$Text) { Write-Host "  > $Text" -ForegroundColor Cyan }
function Write-Ok([string]$Text) { Write-Host "  ok $Text" -ForegroundColor Green }

Write-Host ''
Write-Host '  Fala Clara - o Claude falando como gente' -ForegroundColor White
Write-Host ''

# 1. Origem dos arquivos ------------------------------------------------------
$temp = $null
$localRoot = if ($PSScriptRoot) { $PSScriptRoot } else { $null }
if ($localRoot -and (Test-Path (Join-Path $localRoot "skills/$Name/SKILL.md"))) {
  $root = $localRoot
  Write-Step "Usando os arquivos locais em $root"
} else {
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
  $temp = Join-Path ([IO.Path]::GetTempPath()) ("fala-clara-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $temp | Out-Null
  $zip = Join-Path $temp 'fala-clara.zip'
  $kind = if ($Ref -match '^v\d') { 'tags' } else { 'heads' }
  $url = "https://codeload.github.com/$Repo/zip/refs/$kind/$Ref"
  Write-Step "Baixando $Repo ($Ref)"
  Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
  Expand-Archive -Path $zip -DestinationPath $temp -Force
  $root = Get-ChildItem -Path $temp -Directory | Where-Object { Test-Path (Join-Path $_.FullName "skills/$Name/SKILL.md") } | Select-Object -First 1 -ExpandProperty FullName
  if (-not $root) { throw "O pacote baixado nao tem skills/$Name/SKILL.md." }
}
$skillSrc = Join-Path $root "skills/$Name"
$blockSrc = Join-Path $root 'ativacao/sempre-ativo.md'

# 2. Skill -------------------------------------------------------------------
function Install-Skill([string]$Target, [string]$Label) {
  if (Test-Path $Target) {
    $manifest = Join-Path $Target 'SKILL.md'
    $isOurs = (Test-Path $manifest) -and ((Get-Content $manifest -Raw -Encoding UTF8) -match "(?m)^name:\s*$Name\s*$")
    if (-not $isOurs) {
      Write-Warning "$Target ja existe e nao parece ser o Fala Clara. Pulei $Label para nao apagar nada."
      return
    }
    Remove-Item -Path $Target -Recurse -Force
  }
  New-Item -ItemType Directory -Path (Split-Path $Target -Parent) -Force | Out-Null
  Copy-Item -Path $skillSrc -Destination $Target -Recurse -Force
  Write-Ok "Skill instalada para $Label em $Target"
}

# 3. Bloco sempre ativo ------------------------------------------------------
function Set-AlwaysOn([string]$File, [string]$Label) {
  $body = [IO.File]::ReadAllText($blockSrc, $Utf8).Trim()
  $block = "$Begin`n$body`n$End"
  New-Item -ItemType Directory -Path (Split-Path $File -Parent) -Force | Out-Null
  $old = ''
  if (Test-Path $File) {
    $old = [IO.File]::ReadAllText($File, $Utf8)
    $backup = "$File.antes-fala-clara.bak"
    if (-not (Test-Path $backup) -and -not $old.Contains('<!-- fala-clara:inicio')) { [IO.File]::WriteAllText($backup, $old, $Utf8) }
  }
  $pattern = '(?s)\r?\n?' + [regex]::Escape('<!-- fala-clara:inicio') + '.*?' + [regex]::Escape($End) + '\r?\n?'
  $clean = [regex]::Replace($old, $pattern, "`n").TrimEnd()
  $new = if ($clean) { "$clean`n`n$block`n" } else { "$block`n" }
  [IO.File]::WriteAllText($File, $new, $Utf8)
  Write-Ok "Sempre ativo para $Label ($File)"
}

try {
  if (-not $SkipClaude) {
    Install-Skill (Join-Path $HomeDir ".claude/skills/$Name") 'Claude Code'
    if (-not $NoAlwaysOn) { Set-AlwaysOn (Join-Path $HomeDir '.claude/CLAUDE.md') 'Claude Code' }
  }
  if (-not $SkipCodex) {
    Install-Skill (Join-Path $CodexHome "skills/$Name") 'Codex'
    if (-not $NoAlwaysOn) { Set-AlwaysOn (Join-Path $CodexHome 'AGENTS.md') 'Codex' }
  }
  Install-Skill (Join-Path $HomeDir ".agents/skills/$Name") 'outros agentes'
} finally {
  if ($temp -and (Test-Path $temp)) { Remove-Item -Path $temp -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host '  Pronto! Abra uma sessao nova do Claude Code ou do Codex e converse normalmente.' -ForegroundColor White
Write-Host '  Nao precisa chamar a skill: ela ja vem ligada.'
Write-Host ''
Write-Host '  Usa o Claude no app ou no site (claude.ai)? Veja o passo extra no README:'
Write-Host "  https://github.com/$Repo#no-app-ou-site-do-claude"
Write-Host ''
