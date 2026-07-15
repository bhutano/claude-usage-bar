#!/bin/bash
# ──────────────────────────────────────────────────────────────
#  claude-usage-bar — installer
#  Usage:  bash install.sh [--lang en|it]
# ──────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills/usage-bar"
SETTINGS="$CLAUDE_DIR/settings.json"
CONFIG="$CLAUDE_DIR/usage-bar.conf"

# ── Parse --lang argument ─────────────────────────────────────
LANG_CODE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --lang) LANG_CODE="$2"; shift 2 ;;
        *)      shift ;;
    esac
done

# ── Interactive language prompt (if not passed via --lang) ────
if [ -z "$LANG_CODE" ]; then
    echo ""
    echo "  Select language / Seleziona la lingua:"
    echo "  [1] English (default)"
    echo "  [2] Italiano"
    echo ""
    printf "  Choice / Scelta [1]: "
    read -r choice
    case "$choice" in
        2) LANG_CODE="it" ;;
        *) LANG_CODE="en" ;;
    esac
fi

# ── Banner ────────────────────────────────────────────────────
echo ""
echo "  claude-usage-bar — installer  (lang: $LANG_CODE)"
echo "  ──────────────────────────────────────────────────"

# ── 1. Copy statusline script ─────────────────────────────────
echo "  [1/4] Copying statusline-usage.sh to $CLAUDE_DIR ..."
mkdir -p "$CLAUDE_DIR"
cp "$SCRIPT_DIR/statusline-usage.sh" "$CLAUDE_DIR/statusline-usage.sh"
chmod +x "$CLAUDE_DIR/statusline-usage.sh"

# ── 2. Install skill ──────────────────────────────────────────
echo "  [2/4] Installing skill /usage-bar to $SKILLS_DIR ..."
mkdir -p "$SKILLS_DIR"
cp "$SCRIPT_DIR/SKILL.md"              "$SKILLS_DIR/SKILL.md"
cp "$SCRIPT_DIR/statusline-usage.sh"   "$SKILLS_DIR/statusline-usage.sh"
chmod +x "$SKILLS_DIR/statusline-usage.sh"

# ── 3. Write config ───────────────────────────────────────────
echo "  [3/4] Writing config to $CONFIG ..."
cat > "$CONFIG" <<EOF
# claude-usage-bar — configuration
# Edit LANG= to change the display language.
# Available: en (English), it (Italian)
# You can also override per-session: USAGE_BAR_LANG=it claude
#
LANG=$LANG_CODE
EOF

# ── 4. Patch settings.json ────────────────────────────────────
echo "  [4/4] Enabling statusLine in $SETTINGS ..."

PYTHON=""
for candidate in python3 python /c/Python313/python /usr/bin/python3; do
    if "$candidate" -c "import sys; assert sys.version_info >= (3,6)" 2>/dev/null; then
        PYTHON="$candidate"
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo ""
    echo "  WARNING: Python 3 not found."
    echo "  Add manually to $SETTINGS:"
    echo '  "statusLine": { "type": "command", "command": "~/.claude/statusline-usage.sh" }'
    exit 1
fi

"$PYTHON" - <<PYEOF
import json, os
p = os.path.expanduser("~/.claude/settings.json")
try:
    with open(p) as f: cfg = json.load(f)
except FileNotFoundError:
    cfg = {}
cfg["statusLine"] = {"type": "command", "command": "~/.claude/statusline-usage.sh"}
with open(p, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print("  settings.json updated.")
PYEOF

echo ""
echo "  ✓ Installation complete!"
echo ""
echo "  Restart Claude Code to activate the status bar."
echo ""
echo "  To change language later, edit: $CONFIG"
echo "  or run:  bash install.sh --lang it"
echo ""
