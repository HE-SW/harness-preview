# statusline.ps1 — Windows port of statusline.sh (lean version)
# Renders: cwd + git branch + model + context % + caveman badge
# Reads Claude Code's stdin JSON and prints a single styled status line.
# Skipped vs statusline.sh: ccusage, session reset time, cost/burn rate.

$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---- unicode glyphs (ASCII-safe source so PS 5.1 on cp949 doesn't mangle) ----
$GlyphBlock = [char]0x2588          # full block
$GlyphLight = [char]0x2591          # light shade
$GlyphRobot = [char]::ConvertFromUtf32(0x1F916)  # robot face
$GlyphBrain = [char]::ConvertFromUtf32(0x1F9E0)  # brain

# ---- read stdin ----
$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { $data = $null }

# ---- ANSI helpers ----
$Esc = [char]27
$UseColor = -not $env:NO_COLOR
function Color($code) { if ($UseColor) { "$Esc[${code}m" } else { "" } }
function Reset       { Color "0" }

$DirColor       = Color "34"           # blue
$GitColor       = Color "32"           # green
$ModelColor     = Color "38;5;147"     # light purple
$CtxSafe        = Color "38;5;194"     # mint
$CtxCaution     = Color "38;5;229"     # cream
$CtxDanger      = Color "38;5;217"     # salmon

# ---- progress bar ----
function ProgressBar([int]$pct, [int]$width = 5) {
    if ($pct -lt 0) { $pct = 0 }
    if ($pct -gt 100) { $pct = 100 }
    $filled = [math]::Floor($pct * $width / 100)
    $empty  = $width - $filled
    return ($GlyphBlock.ToString() * $filled) + ($GlyphLight.ToString() * $empty)
}

# ---- extract fields ----
$cwd = $data.workspace.current_dir
if (-not $cwd) { $cwd = $data.cwd }
if (-not $cwd) { $cwd = "unknown" }
$home = $env:USERPROFILE
if ($cwd.StartsWith($home)) { $cwd = "~" + $cwd.Substring($home.Length) }

$modelName = $data.model.display_name
if (-not $modelName) { $modelName = "Claude" }
$modelShort = $modelName -replace '\s*\([^)]*\)', ''

$sessionId = $data.session_id

# ---- git branch ----
$gitBranch = ""
try {
    $null = & git rev-parse --git-dir 2>$null
    if ($LASTEXITCODE -eq 0) {
        $gitBranch = (& git branch --show-current 2>$null).Trim()
        if (-not $gitBranch) { $gitBranch = (& git rev-parse --short HEAD 2>$null).Trim() }
    }
} catch {}

# ---- context window ----
function GetMaxContext($name) {
    switch -Wildcard ($name) {
        "*1M*"      { return 1000000 }
        "*1m*"      { return 1000000 }
        "*Opus*"    { return 200000 }
        "*Sonnet*"  { return 200000 }
        "*Haiku 3.5*" { return 200000 }
        "*Haiku 4*" { return 200000 }
        "*Haiku*"   { return 200000 }
        default     { return 200000 }
    }
}

$ctxPct = $null
$ctxColor = $CtxSafe
if ($sessionId) {
    $maxCtx = GetMaxContext $modelName
    $projectKey = ($cwd -replace '~', $home) -replace '[\\/]', '-'
    $projectKey = $projectKey -replace '^-', ''
    $sessionFile = Join-Path $home ".claude\projects\-$projectKey\$sessionId.jsonl"
    if (Test-Path $sessionFile) {
        try {
            $tail = Get-Content $sessionFile -Tail 20 -ErrorAction Stop
            $latestTokens = 0
            foreach ($line in $tail) {
                try {
                    $obj = $line | ConvertFrom-Json
                    if ($obj.message.usage) {
                        $u = $obj.message.usage
                        $t = 0
                        if ($u.input_tokens)            { $t += [int]$u.input_tokens }
                        if ($u.cache_read_input_tokens) { $t += [int]$u.cache_read_input_tokens }
                        if ($t -gt 0) { $latestTokens = $t }
                    }
                } catch {}
            }
            if ($latestTokens -gt 0) {
                $usedPct = [int]($latestTokens * 100 / $maxCtx)
                if ($usedPct -ge 80)      { $ctxColor = $CtxDanger }
                elseif ($usedPct -ge 60)  { $ctxColor = $CtxCaution }
                else                       { $ctxColor = $CtxSafe }
                $ctxPct = $usedPct
            }
        } catch {}
    }
}

# ---- render ----
$out = ""
$out += "$DirColor$cwd$(Reset)"
if ($gitBranch) {
    $out += " $GitColor($gitBranch)$(Reset)"
}
$out += "  $GlyphRobot $ModelColor$modelShort$(Reset)"
if ($null -ne $ctxPct) {
    $bar = ProgressBar $ctxPct 5
    $out += "  $GlyphBrain $ctxColor$ctxPct% $bar$(Reset)"
} else {
    $out += "  $GlyphBrain --"
}

# ---- caveman badge ----
$badgeScript = Join-Path $PSScriptRoot "hooks\caveman-kor\caveman-statusline.ps1"
if (Test-Path $badgeScript) {
    $badge = & powershell -NoProfile -ExecutionPolicy Bypass -File $badgeScript 2>$null
    if ($badge) { $out += "  $badge" }
}

[Console]::Write($out)
[Console]::WriteLine()
