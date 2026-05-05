# template-harness — generates .claude/settings.json (statusLine only) for the cloned project (Windows)
# Delegates hook wiring to hooks\caveman-kor\install.ps1.
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1 [-Force] [-Yes]
#   -Force: overwrite existing settings.json
#   -Yes  : auto-confirm runtime installs (skip Y/N prompts)
#
# Note: statusline.ps1 is a lean port of statusline.sh (cwd + git + model + context % + caveman badge).
# Skipped vs statusline.sh: ccusage, session reset time, cost/burn rate.
param([switch]$Force, [switch]$Yes)
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$Settings  = Join-Path $ScriptDir "settings.json"

if (-not (Test-Path (Join-Path $ScriptDir "statusline.ps1"))) {
    Write-Host "ERROR: statusline.ps1 missing" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path (Join-Path $ScriptDir "hooks\caveman-kor\install.ps1"))) {
    Write-Host "ERROR: hooks\caveman-kor\install.ps1 missing" -ForegroundColor Red
    exit 1
}

Write-Host "OS: Windows"

# ---- runtime checks: node + python ----
$NodeMin    = 20
$PyMinMajor = 3
$PyMinMinor = 11

function Prompt-YN($msg) {
    if ($Yes) { return $true }
    $ans = Read-Host "$msg [y/N]"
    return ($ans -match '^(y|Y)')
}

function Check-Node {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) { return $false }
    try {
        $v = (& node --version) -replace '^v', '' -replace '\..*', ''
        return ([int]$v -ge $NodeMin)
    } catch { return $false }
}

function Check-Python {
    $cmd = $null
    if (Get-Command python -ErrorAction SilentlyContinue)  { $cmd = "python" }
    elseif (Get-Command python3 -ErrorAction SilentlyContinue) { $cmd = "python3" }
    if (-not $cmd) { return $false }
    try {
        $out = & $cmd -c "import sys; print(f'{sys.version_info.major} {sys.version_info.minor}')"
        $parts = $out.Trim().Split(' ')
        $major = [int]$parts[0]; $minor = [int]$parts[1]
        if ($major -gt $PyMinMajor) { return $true }
        if ($major -eq $PyMinMajor -and $minor -ge $PyMinMinor) { return $true }
        return $false
    } catch { return $false }
}

function Install-WithWinget($id, $name) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "  ERROR: winget not found. Install $name manually from the official site." -ForegroundColor Red
        return $false
    }
    & winget install --id $id --silent --accept-source-agreements --accept-package-agreements
    return ($LASTEXITCODE -eq 0)
}

if (Check-Node) {
    Write-Host "  node: $((& node --version)) OK"
} else {
    Write-Host "  node: missing or < v$NodeMin"
    if (Prompt-YN "Install Node.js now?") {
        if (-not (Install-WithWinget "OpenJS.NodeJS.LTS" "Node.js")) { exit 1 }
        if (-not (Check-Node)) {
            Write-Host "ERROR: node still not satisfying >= v$NodeMin after install. Restart shell and retry." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "ERROR: node required to continue." -ForegroundColor Red
        exit 1
    }
}

if (Check-Python) {
    $pyCmd = if (Get-Command python -ErrorAction SilentlyContinue) { "python" } else { "python3" }
    Write-Host "  python: $((& $pyCmd --version)) OK"
} else {
    Write-Host "  python: missing or < $PyMinMajor.$PyMinMinor"
    if (Prompt-YN "Install Python now?") {
        if (-not (Install-WithWinget "Python.Python.3.12" "Python")) { exit 1 }
        if (-not (Check-Python)) {
            Write-Host "ERROR: python still not satisfying >= $PyMinMajor.$PyMinMinor after install. Restart shell and retry." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "ERROR: python required to continue." -ForegroundColor Red
        exit 1
    }
}

if (Test-Path $Settings) {
    if (-not $Force) {
        Write-Host "$Settings exists. Use -Force to overwrite (current file will be backed up to .bak)."
        exit 0
    }
    Copy-Item $Settings "$Settings.bak" -Force
    Write-Host "  backed up to $Settings.bak"
}

$json = @'
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$CLAUDE_PROJECT_DIR/.claude/statusline.ps1\""
  }
}
'@

Set-Content -Path $Settings -Value $json -Encoding UTF8
Write-Host "Wrote $Settings (statusLine only)" -ForegroundColor Green

Write-Host ""
Write-Host "Delegating hook setup to hooks\caveman-kor\install.ps1..."
$cavemanInstall = Join-Path $ScriptDir "hooks\caveman-kor\install.ps1"
$argList = @("-ExecutionPolicy", "Bypass", "-File", $cavemanInstall)
if ($Force) { $argList += "-Force" }
if ($Yes)   { $argList += "-Yes" }
& powershell @argList

Write-Host ""
Write-Host "All done. Restart Claude Code to activate." -ForegroundColor Green
