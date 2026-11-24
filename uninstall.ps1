<#
.SYNOPSIS
  Remove o Fala Clara: as pastas da skill e o bloco "sempre ativo".

.DESCRIPTION
  Apaga so o que o instalador criou. O resto do seu CLAUDE.md / AGENTS.md fica intacto.

.EXAMPLE
  irm https://raw.githubusercontent.com/carlos-dataengineer/fala-clara/main/uninstall.ps1 | iex
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Name = 'fala-clara'
$End = '<!-- fala-clara:fim -->'
$HomeDir = if ($env:FALA_CLARA_HOME) { $env:FALA_CLARA_HOME } else { $HOME }
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HomeDir '.codex' }
$Utf8 = New-Object System.Text.UTF8Encoding($false)

function Remove-Skill([string]$Target) {
  $manifest = Join-Path $Target 'SKILL.md'
  if ((Test-Path $manifest) -and ((Get-Content $manifest -Raw -Encoding UTF8) -match "(?m)^name:\s*$Name\s*$")) {
    Remove-Item -Path $Target -Recurse -Force
    Write-Host "  ok Removido $Target" -ForegroundColor Green
  }
}

function Remove-Block([string]$File) {
  if (-not (Test-Path $File)) { return }
  $old = [IO.File]::ReadAllText($File, $Utf8)
  $pattern = '(?s)\r?\n?' + [regex]::Escape('<!-- fala-clara:inicio') + '.*?' + [regex]::Escape($End) + '\r?\n?'
  if (-not [regex]::IsMatch($old, $pattern)) { return }
  $new = [regex]::Replace($old, $pattern, "`n").Trim()
  if ($new) { [IO.File]::WriteAllText($File, "$new`n", $Utf8) } else { Remove-Item -Path $File -Force }
  Write-Host "  ok Bloco sempre ativo retirado de $File" -ForegroundColor Green
}

Remove-Skill (Join-Path $HomeDir ".claude/skills/$Name")
Remove-Skill (Join-Path $CodexHome "skills/$Name")
Remove-Skill (Join-Path $HomeDir ".agents/skills/$Name")
Remove-Block (Join-Path $HomeDir '.claude/CLAUDE.md')
Remove-Block (Join-Path $CodexHome 'AGENTS.md')

Write-Host ''
Write-Host '  Fala Clara removido. Os backups *.antes-fala-clara.bak, se existirem, ficaram onde estavam.'
Write-Host ''
