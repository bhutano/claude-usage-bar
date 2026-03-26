---
name: usage-bar
description: Install or check the Claude Code usage status bar (rate limits 5h/7d, session context, reset countdown). Also use to change the display language.
user-invocable: true
allowed-tools: Bash(python3 *), Bash(bash *), Bash(chmod *), Bash(cp *), Bash(mkdir *), Bash(grep *), Bash(cat *)
---

# claude-usage-bar

Manage the persistent status bar that shows Claude Code usage limits.

## Step 1 — Check installation status

```
!`test -f ~/.claude/statusline-usage.sh && echo "INSTALLED" || echo "NOT_INSTALLED"`
```

```
!`test -f ~/.claude/usage-bar.conf && cat ~/.claude/usage-bar.conf || echo "NO_CONFIG"`
```

## Step 2 — Act on the result

### If NOT installed

Copy the script from the skill directory and update settings.json:

```
!`
cp "${CLAUDE_SKILL_DIR}/statusline-usage.sh" ~/.claude/statusline-usage.sh
chmod +x ~/.claude/statusline-usage.sh
`
```

```
!`python3 -c "
import json, os
p = os.path.expanduser('~/.claude/settings.json')
try: cfg = json.load(open(p))
except: cfg = {}
cfg['statusLine'] = {'type': 'command', 'command': '~/.claude/statusline-usage.sh'}
with open(p, 'w') as f: json.dump(cfg, f, indent=2); f.write('\n')
print('settings.json updated.')
"`
```

Write the default config file:

```
!`cat > ~/.claude/usage-bar.conf << 'EOF'
# claude-usage-bar — configuration
# Available languages: en (English), it (Italian)
# Override per-session: USAGE_BAR_LANG=it claude
#
LANG=en
EOF
echo "Config written."`
```

Tell the user installation is complete and they need to **restart Claude Code** to see the bar.

### If already installed — show live test

Run a live preview with simulated data:

```
!`bash ~/.claude/statusline-usage.sh <<'EOF'
{"context_window":{"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":28.0,"resets_at":1800},"seven_day":{"used_percentage":85.0,"resets_at":345600}}}
EOF`
```

Also show the current language setting from the config file.

### If the user wants to change language

Ask which language they want, then update `~/.claude/usage-bar.conf`:

```
!`sed -i 's/^LANG=.*/LANG=it/' ~/.claude/usage-bar.conf && echo "Language set to: it"`
```

Replace `it` with the desired language code. No restart needed — the change takes effect on the next response.

---

## Field reference

Explain to the user what each field means:

- **5h** — Rate limit over the last 5 hours (daily proxy). Green < 80%, orange 80–90%, red ≥ 90%
- **7d** — Weekly rate limit. Same color scale
- **ctx** — Context window usage for the current session. Green < 70%, orange 70–80%, red > 80%
- **reset** — Countdown to limit reset. Hours/minutes if < 24h, days and hours if ≥ 24h
- Rate limit data is only available with a **Claude.ai Pro or Max** plan

## Supported languages

| Code | Language |
|------|----------|
| `en` | English  |
| `it` | Italiano |

To add a new language, open `statusline-usage.sh` and add a new entry to the `T` dictionary in the Python section.
