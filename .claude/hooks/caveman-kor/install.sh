#!/bin/bash
# caveman-kor — merges caveman hooks into the cloned project's .claude/settings.json (Mac/Linux)
# Use this when you don't want the full template-harness statusline — just caveman.
# Usage: bash install.sh [--force]
set -e

FORCE=0
for arg in "$@"; do
  case "$arg" in --force|-f) FORCE=1 ;; esac
done

if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: node required (used to merge settings.json)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SETTINGS="$CLAUDE_DIR/settings.json"

# Verify hook files exist alongside this script
for h in caveman-config.cjs caveman-activate.cjs caveman-mode-tracker.cjs caveman-stats.cjs caveman-statusline.sh; do
  [ -f "$SCRIPT_DIR/$h" ] || { echo "ERROR: $h missing in $SCRIPT_DIR" >&2; exit 1; }
done

chmod +x "$SCRIPT_DIR/caveman-statusline.sh"

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.bak"

if ! CAVEMAN_SETTINGS="$SETTINGS" CAVEMAN_FORCE="$FORCE" node -e "
  const fs = require('fs');
  const p = process.env.CAVEMAN_SETTINGS;
  const force = process.env.CAVEMAN_FORCE === '1';
  const s = JSON.parse(fs.readFileSync(p, 'utf8'));
  s.hooks = s.hooks || {};

  const wire = (event, file, msg) => {
    s.hooks[event] = s.hooks[event] || [];
    const idx = s.hooks[event].findIndex(e => e.hooks?.some(h => h.command?.includes('caveman-kor/' + file)));
    const entry = {
      hooks: [{
        type: 'command',
        command: 'node \"\$CLAUDE_PROJECT_DIR/.claude/hooks/caveman-kor/' + file + '\"',
        timeout: 5,
        statusMessage: msg
      }]
    };
    if (idx === -1) {
      s.hooks[event].push(entry);
      console.log('  wired ' + event + ' → ' + file);
    } else if (force) {
      s.hooks[event][idx] = entry;
      console.log('  rewrote ' + event + ' → ' + file);
    } else {
      console.log('  ' + event + ' already wired');
    }
  };
  wire('SessionStart', 'caveman-activate.cjs', 'Loading caveman mode...');
  wire('UserPromptSubmit', 'caveman-mode-tracker.cjs', 'Tracking caveman mode...');

  fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
"; then
  echo "ERROR: merge failed; original preserved at $SETTINGS.bak" >&2
  exit 1
fi
rm -f "$SETTINGS.bak"

echo "Done. Restart Claude Code to activate."
