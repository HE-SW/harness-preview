# caveman-kor — merges caveman hooks into the cloned project's .claude/settings.json (Windows)
# Use this when you don't want the full template-harness statusline — just caveman.
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1 [-Force]
param([switch]$Force)
$ErrorActionPreference = "Stop"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: node required (used to merge settings.json)." -ForegroundColor Red
    exit 1
}

$ScriptDir = $PSScriptRoot
$ClaudeDir = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$Settings  = Join-Path $ClaudeDir "settings.json"

$Required = @("caveman-config.cjs", "caveman-activate.cjs", "caveman-mode-tracker.cjs", "caveman-stats.cjs", "caveman-statusline.ps1")
foreach ($f in $Required) {
    if (-not (Test-Path (Join-Path $ScriptDir $f))) {
        Write-Host "ERROR: $f missing in $ScriptDir" -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path $Settings)) { Set-Content -Path $Settings -Value "{}" }
Copy-Item $Settings "$Settings.bak" -Force

$env:CAVEMAN_SETTINGS = $Settings -replace '\\', '/'
$env:CAVEMAN_FORCE    = if ($Force) { "1" } else { "0" }

$nodeScript = @'
const fs = require('fs');
const p = process.env.CAVEMAN_SETTINGS;
const force = process.env.CAVEMAN_FORCE === '1';
const s = JSON.parse(fs.readFileSync(p, 'utf8'));
s.hooks = s.hooks || {};

const wire = (event, file, msg) => {
  s.hooks[event] = s.hooks[event] || [];
  const idx = s.hooks[event].findIndex(e => e.hooks && e.hooks.some(h => h.command && h.command.includes('caveman-kor/' + file)));
  const entry = {
    hooks: [{
      type: 'command',
      command: 'node "$CLAUDE_PROJECT_DIR/.claude/hooks/caveman-kor/' + file + '"',
      timeout: 5,
      statusMessage: msg
    }]
  };
  if (idx === -1) {
    s.hooks[event].push(entry);
    console.log('  wired ' + event + ' -> ' + file);
  } else if (force) {
    s.hooks[event][idx] = entry;
    console.log('  rewrote ' + event + ' -> ' + file);
  } else {
    console.log('  ' + event + ' already wired');
  }
};
wire('SessionStart', 'caveman-activate.cjs', 'Loading caveman mode...');
wire('UserPromptSubmit', 'caveman-mode-tracker.cjs', 'Tracking caveman mode...');

fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
'@

$tmpJs = Join-Path ([System.IO.Path]::GetTempPath()) ("caveman-merge-" + [Guid]::NewGuid().ToString() + ".js")
Set-Content -Path $tmpJs -Value $nodeScript -Encoding UTF8
try {
    & node $tmpJs
    $exit = $LASTEXITCODE
} finally {
    Remove-Item $tmpJs -Force -ErrorAction SilentlyContinue
}
if ($exit -eq 0) {
    Remove-Item "$Settings.bak" -Force
} else {
    Write-Host "ERROR: merge failed; original preserved at $Settings.bak" -ForegroundColor Red
    exit 1
}

Write-Host "Done. Restart Claude Code to activate." -ForegroundColor Green
