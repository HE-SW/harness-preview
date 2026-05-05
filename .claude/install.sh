#!/bin/bash
# template-harness — generates .claude/settings.json (statusLine only) for the cloned project (Mac/Linux)
# Delegates hook wiring to hooks/caveman-kor/install.sh.
# Usage: bash install.sh [--force] [--yes]
#   --force: overwrite existing settings.json
#   --yes  : auto-confirm runtime installs (skip Y/N prompts)
set -e

FORCE=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE=1 ;;
    --yes|-y)   ASSUME_YES=1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS="$SCRIPT_DIR/settings.json"

[ -f "$SCRIPT_DIR/statusline.sh" ] || { echo "ERROR: statusline.sh missing" >&2; exit 1; }
[ -f "$SCRIPT_DIR/hooks/caveman-kor/install.sh" ] || { echo "ERROR: hooks/caveman-kor/install.sh missing" >&2; exit 1; }

case "$OSTYPE" in
  darwin*) OS="macOS" ;;
  linux*)  OS="Linux" ;;
  msys*|cygwin*|mingw*) OS="Windows-bash"; echo "WARN: detected Windows shell — use install.ps1 for native PowerShell setup" >&2 ;;
  *) OS="$OSTYPE" ;;
esac
echo "OS: $OS"

# ---- runtime checks: node + python ----
NODE_MIN=20
PY_MIN_MAJOR=3
PY_MIN_MINOR=11

prompt_yn() {
  local msg="$1"
  if [ "$ASSUME_YES" -eq 1 ]; then return 0; fi
  read -r -p "$msg [y/N] " ans </dev/tty
  [[ "$ans" =~ ^[Yy] ]]
}

check_node() {
  command -v node >/dev/null 2>&1 || return 1
  local v
  v=$(node --version 2>/dev/null | sed 's/^v//; s/\..*//')
  [[ "$v" =~ ^[0-9]+$ ]] || return 1
  [ "$v" -ge "$NODE_MIN" ]
}

check_python() {
  local cmd=python3
  command -v "$cmd" >/dev/null 2>&1 || cmd=python
  command -v "$cmd" >/dev/null 2>&1 || return 1
  local out
  out=$("$cmd" -c 'import sys; print(f"{sys.version_info.major} {sys.version_info.minor}")' 2>/dev/null) || return 1
  local major minor
  major=${out%% *}; minor=${out##* }
  [ "$major" -gt "$PY_MIN_MAJOR" ] && return 0
  [ "$major" -eq "$PY_MIN_MAJOR" ] && [ "$minor" -ge "$PY_MIN_MINOR" ]
}

install_pkg() {
  local pkg_mac="$1" pkg_apt="$2"
  case "$OS" in
    macOS)
      command -v brew >/dev/null 2>&1 || { echo "  ERROR: Homebrew not found. Install from https://brew.sh" >&2; return 1; }
      brew install "$pkg_mac"
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y $pkg_apt
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y $pkg_apt
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm $pkg_apt
      else
        echo "  ERROR: no supported package manager (apt/dnf/pacman). Install $pkg_mac manually." >&2
        return 1
      fi
      ;;
    *)
      echo "  ERROR: auto-install not supported on $OS. Install $pkg_mac manually." >&2
      return 1
      ;;
  esac
}

if check_node; then
  echo "  node: $(node --version) OK"
else
  echo "  node: missing or < v$NODE_MIN"
  if prompt_yn "Install Node.js now?"; then
    install_pkg node "nodejs npm" || exit 1
    check_node || { echo "ERROR: node still not satisfying >= v$NODE_MIN after install" >&2; exit 1; }
  else
    echo "ERROR: node required to continue." >&2
    exit 1
  fi
fi

if check_python; then
  PY_CMD=$(command -v python3 || command -v python)
  echo "  python: $($PY_CMD --version) OK"
else
  echo "  python: missing or < $PY_MIN_MAJOR.$PY_MIN_MINOR"
  if prompt_yn "Install Python now?"; then
    install_pkg python "python3" || exit 1
    check_python || { echo "ERROR: python still not satisfying >= $PY_MIN_MAJOR.$PY_MIN_MINOR after install" >&2; exit 1; }
  else
    echo "ERROR: python required to continue." >&2
    exit 1
  fi
fi

if [ -f "$SETTINGS" ]; then
  if [ "$FORCE" -eq 0 ]; then
    echo "$SETTINGS exists. Use --force to overwrite (current file will be backed up to .bak)."
    exit 0
  fi
  cp "$SETTINGS" "$SETTINGS.bak"
  echo "  backed up to $SETTINGS.bak"
fi

cat > "$SETTINGS" <<'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "/bin/bash \"$CLAUDE_PROJECT_DIR/.claude/statusline.sh\""
  }
}
EOF

chmod +x "$SCRIPT_DIR/statusline.sh"
echo "Wrote $SETTINGS (statusLine only)"

echo ""
echo "Delegating hook setup to hooks/caveman-kor/install.sh..."
FORCE_ARG=""; [ "$FORCE" -eq 1 ] && FORCE_ARG="--force"
bash "$SCRIPT_DIR/hooks/caveman-kor/install.sh" $FORCE_ARG

echo ""
echo "All done. Restart Claude Code to activate."
