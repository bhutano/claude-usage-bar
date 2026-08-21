---
name: usage-bar
description: Install or check the Claude Code usage status bar (rate limits 5h/7d, session context, reset countdown, model, effort, and working directory). Also use to change the display language.
user-invocable: true
allowed-tools: Bash(uname *), Bash(bash *), Bash(powershell.exe *), Bash(cygpath *), Bash(test *), Bash(grep *), Bash(cat *), Bash(sed *), Bash(printf *)
---

# claude-usage-bar

Manage the persistent status bar that shows Claude Code usage limits. Use the native PowerShell renderer on Windows and the Bash renderer on macOS, Linux, Git Bash, and WSL.

## Step 1 — Detect the platform and check installation status

```
!`
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) OS=windows; TARGET="$HOME/.claude/statusline-usage.ps1" ;;
  *)                    OS=unix;    TARGET="$HOME/.claude/statusline-usage.sh" ;;
esac
echo "OS=$OS"
test -f "$TARGET" && echo "INSTALLED ($TARGET)" || echo "NOT_INSTALLED"
test -f "$HOME/.claude/usage-bar.conf" && cat "$HOME/.claude/usage-bar.conf" || echo "NO_CONFIG"
`
```

## Step 2 — Act on the result

### If NOT installed

Run the platform-appropriate installer from the skill directory:

```
!`
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    INSTALLER=$(cygpath -w "${CLAUDE_SKILL_DIR}/install.ps1")
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$INSTALLER" -Lang en
    ;;
  *)
    bash "${CLAUDE_SKILL_DIR}/install.sh" --lang en
    ;;
esac
`
```

Tell the user installation is complete and they need to **restart Claude Code** to see the bar.

### If already installed — show live test

Run a live preview with simulated data using the installed renderer:

```
!`
SAMPLE='{"model":{"display_name":"Opus 4.6"},"effort":{"level":"high"},"workspace":{"current_dir":"/home/user/project"},"context_window":{"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":28.0},"seven_day":{"used_percentage":85.0}}}'
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    TARGET=$(cygpath -w "$HOME/.claude/statusline-usage.ps1")
    printf '%s' "$SAMPLE" | powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$TARGET"
    ;;
  *)
    printf '%s' "$SAMPLE" | bash "$HOME/.claude/statusline-usage.sh"
    ;;
esac
`
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
- **session details** — Current model in yellow, reasoning effort (when supported), and working directory in bright green on a second line. The home directory is shortened to `~`
- Rate limit data is only available with a **Claude.ai Pro or Max** plan

## Supported languages

| Code | Language |
|------|----------|
| `en` | English  |
| `it` | Italiano |

To add a new language, update both `statusline-usage.sh` and `statusline-usage.ps1` so the renderers stay in sync.
