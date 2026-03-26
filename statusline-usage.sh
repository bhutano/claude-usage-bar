#!/bin/bash
# ──────────────────────────────────────────────────────────────
#  claude-usage-bar  —  status line for Claude Code CLI
#  https://github.com/bhutano/claude-usage-bar
#
#  Requirements: Python 3  (auto-detected)
#  Works on: macOS, Linux, Windows (Git Bash / WSL)
#
#  Language: set USAGE_BAR_LANG=en|it in ~/.claude/usage-bar.conf
#  or as an environment variable. Defaults to "en".
# ──────────────────────────────────────────────────────────────

INPUT=$(cat)

# ── Read language config ──────────────────────────────────────
LANG_CODE="${USAGE_BAR_LANG:-}"
CONFIG_FILE="$HOME/.claude/usage-bar.conf"
if [ -z "$LANG_CODE" ] && [ -f "$CONFIG_FILE" ]; then
    LANG_CODE=$(grep '^LANG=' "$CONFIG_FILE" 2>/dev/null | head -1 | cut -d= -f2 | tr -d '[:space:]')
fi
LANG_CODE="${LANG_CODE:-en}"

# ── Auto-detect Python 3 ──────────────────────────────────────
PYTHON=""
for candidate in python3 python /c/Python313/python /usr/bin/python3 /usr/local/bin/python3; do
    if "$candidate" -c "import sys; assert sys.version_info >= (3,6)" 2>/dev/null; then
        PYTHON="$candidate"
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo "[ claude-usage-bar: Python 3 not found / Python 3 non trovato ]"
    exit 0
fi

"$PYTHON" - <<'PYEOF' "$INPUT" "$LANG_CODE"
# -*- coding: utf-8 -*-
import sys, json, datetime, io

# Force UTF-8 on Windows (avoids cp1252 encoding errors)
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

data_str = sys.argv[1] if len(sys.argv) > 1 else ""
lang     = sys.argv[2] if len(sys.argv) > 2 else "en"

# ── Translations ──────────────────────────────────────────────
T = {
    "en": {
        "waiting":   "Waiting for first response...",
        "reset_now": "reset now",
        "na":        "N/A",
        "5h":        "5h",
        "7d":        "7d",
        "ctx":       "ctx",
        "reset":     "reset",
        "days":      "d",
        "hours":     "h",
        "minutes":   "m",
    },
    "it": {
        "waiting":   "In attesa della prima risposta...",
        "reset_now": "reset ora",
        "na":        "N/A",
        "5h":        "5h",
        "7d":        "7d",
        "ctx":       "ctx",
        "reset":     "reset",
        "days":      "g",
        "hours":     "h",
        "minutes":   "m",
    },
}

# Fallback to English for unknown languages
t = T.get(lang, T["en"])

try:
    data = json.loads(data_str)
except Exception:
    print(f"[ {t['waiting']} ]")
    sys.exit(0)

# ── ANSI colors ───────────────────────────────────────────────
GREEN  = "\033[32m"
ORANGE = "\033[38;5;208m"
RED    = "\033[31m"
CYAN   = "\033[36m"
BOLD   = "\033[1m"
DIM    = "\033[2m"
RESET  = "\033[0m"

FILLED = "\u2588"   # █
EMPTY  = "\u2591"   # ░

# ── Helpers ───────────────────────────────────────────────────
def bar(pct, length=8):
    try:
        v = float(pct)
        filled = int(v / 100 * length)
        return FILLED * filled + EMPTY * (length - filled)
    except Exception:
        return EMPTY * length

def color_rate(pct):
    """Rate limits — orange ≥80%, red ≥90%"""
    try:
        v = float(pct)
    except Exception:
        return f"{DIM}{t['na']}{RESET}"
    c = RED if v >= 90 else ORANGE if v >= 80 else GREEN
    return f"{c}{bar(v)} {v:.0f}%{RESET}"

def color_ctx(pct):
    """Context window — orange ≥70%, red >80%"""
    try:
        v = float(pct)
    except Exception:
        return f"{DIM}{t['na']}{RESET}"
    c = RED if v > 80 else ORANGE if v >= 70 else GREEN
    return f"{c}{bar(v)} {v:.0f}%{RESET}"

def time_until(ts):
    try:
        diff = int(ts) - int(datetime.datetime.now().timestamp())
        if diff <= 0:
            return f"{GREEN}{t['reset_now']}{RESET}"
        h_total = diff // 3600
        m       = (diff % 3600) // 60
        d_      = t['days']
        h_      = t['hours']
        m_      = t['minutes']
        if h_total >= 24:
            d, h = h_total // 24, h_total % 24
            return f"{CYAN}{d}{d_} {h}{h_}{RESET}"
        return f"{CYAN}{h_total}{h_} {m}{m_}{RESET}" if h_total > 0 else f"{CYAN}{m}{m_}{RESET}"
    except Exception:
        return f"{DIM}?{RESET}"

# ── Data extraction ───────────────────────────────────────────
rate = data.get("rate_limits", {})
fh   = rate.get("five_hour", {})
sd   = rate.get("seven_day", {})
ctx  = data.get("context_window", {})

fh_pct, fh_reset = fh.get("used_percentage"), fh.get("resets_at")
sd_pct, sd_reset = sd.get("used_percentage"), sd.get("resets_at")
ctx_pct          = ctx.get("used_percentage")

# ── Build output ──────────────────────────────────────────────
parts = []

if fh_pct is not None:
    reset_str = f" {t['reset']} {time_until(fh_reset)}" if fh_reset else ""
    parts.append(f"{BOLD}{t['5h']}:{RESET} {color_rate(fh_pct)}{reset_str}")
else:
    parts.append(f"{DIM}{t['5h']}: {t['na']}{RESET}")

if sd_pct is not None:
    reset_str = f" {t['reset']} {time_until(sd_reset)}" if sd_reset else ""
    parts.append(f"{BOLD}{t['7d']}:{RESET} {color_rate(sd_pct)}{reset_str}")
else:
    parts.append(f"{DIM}{t['7d']}: {t['na']}{RESET}")

if ctx_pct is not None:
    parts.append(f"{BOLD}{t['ctx']}:{RESET} {color_ctx(ctx_pct)}")

sep = f"  {DIM}|{RESET}  "
print(sep.join(parts))
PYEOF
