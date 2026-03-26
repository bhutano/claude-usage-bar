# claude-usage-bar

A persistent status bar for **Claude Code CLI** that shows your account's rate limit usage (5h and 7d windows), current session context, and countdown to reset — just like the "Usage" page in Claude settings.

The bar updates automatically after every response, right below the input box.

> 🌐 [Leggi in italiano](#italiano)

---

## Preview

### Normal usage
```
5h: ██░░░░░░ 28%  reset 2h 14m  |  7d: ████░░░░ 55%  reset 4d 0h  |  ctx: ███░░░░░ 42%
```

### Approaching limits (orange)
```
5h: ██████░░ 85%  reset 0h 42m  |  7d: ████░░░░ 62%  reset 1d 6h  |  ctx: ██████░░ 75%
```

### Critical (red)
```
5h: ███████░ 95%  reset 0h 12m  |  7d: ███████░ 92%  reset 3d 2h  |  ctx: ███████░ 88%
```

### Waiting for first response
```
5h: N/A  |  7d: N/A
```

---

## Fields

| Field | Meaning | Color thresholds |
|-------|---------|-----------------|
| **5h** | Rate limit over the last 5 hours (daily proxy) | green < 80% · orange 80–90% · red ≥ 90% |
| **7d** | Weekly rate limit | green < 80% · orange 80–90% · red ≥ 90% |
| **ctx** | Context window usage for the current session | green < 70% · orange 70–80% · red > 80% |
| **reset** | Countdown to limit reset | hours/minutes if < 24h · days and hours if ≥ 24h |

> **Note:** `5h` and `7d` show real data only with a **Claude.ai Pro or Max** plan.
> They will appear as `N/A` when using a standalone API key.

---

## Requirements

- [Claude Code CLI](https://claude.ai/code) installed
- Python 3.6+  (macOS/Linux: pre-installed · Windows: [python.org](https://python.org))
- **Claude.ai Pro or Max** plan for rate limit data

---

## Installation

### Option 1 — Automatic (recommended)

```bash
git clone https://github.com/YOUR_USERNAME/claude-usage-bar.git
cd claude-usage-bar
bash install.sh
```

The installer will ask you to choose a language, then set everything up automatically.

Then **restart Claude Code**.

### Option 2 — Manual

1. Copy `statusline-usage.sh` to `~/.claude/` and make it executable:
   ```bash
   cp statusline-usage.sh ~/.claude/statusline-usage.sh
   chmod +x ~/.claude/statusline-usage.sh
   ```

2. Copy the config file:
   ```bash
   cp usage-bar.conf ~/.claude/usage-bar.conf
   ```

3. Add to `~/.claude/settings.json`:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/statusline-usage.sh"
     }
   }
   ```

4. Restart Claude Code.

### Option 3 — Skill `/usage-bar`

Copy the repo folder into `~/.claude/skills/`:

```bash
cp -r . ~/.claude/skills/usage-bar
```

Then type `/usage-bar` inside Claude Code to install everything automatically.

---

## Changing the language

### Method 1 — Edit the config file

Open `~/.claude/usage-bar.conf` and change the `LANG` line:

```ini
LANG=en   # English
LANG=it   # Italiano
```

No restart needed — the change takes effect on the next response.

### Method 2 — Re-run the installer

```bash
bash install.sh --lang it
```

### Method 3 — Per-session environment variable

Override the language for a single session without changing the config:

```bash
USAGE_BAR_LANG=it claude
```

### Method 4 — From inside Claude Code

Type `/usage-bar` and ask Claude to change the language.

---

## Supported languages

| Code | Language  |
|------|-----------|
| `en` | English   |
| `it` | Italiano  |

### Adding a new language

Open `statusline-usage.sh` and add a new entry to the `T` dictionary in the Python block:

```python
T = {
    "en": { ... },
    "it": { ... },
    "fr": {                        # ← add your language here
        "waiting":   "En attente de la première réponse...",
        "reset_now": "réinitialisation maintenant",
        "na":        "N/D",
        "5h":        "5h",
        "7d":        "7j",
        "ctx":       "ctx",
        "reset":     "réinit.",
        "days":      "j",
        "hours":     "h",
        "minutes":   "m",
    },
}
```

Then set `LANG=fr` in `~/.claude/usage-bar.conf`.

---

## How it works

Claude Code pipes a JSON object to the script's stdin after each response. The script extracts `rate_limits` and `context_window` fields and formats them with ANSI color bars and a reset countdown.

Relevant JSON fields:

```json
{
  "context_window": {
    "used_percentage": 42
  },
  "rate_limits": {
    "five_hour":  { "used_percentage": 28.0, "resets_at": 1743000000 },
    "seven_day":  { "used_percentage": 55.0, "resets_at": 1743500000 }
  }
}
```

---

## File structure

```
claude-usage-bar/
├── README.md               ← this file
├── SKILL.md                ← /usage-bar skill (auto-installer + help)
├── statusline-usage.sh     ← status bar script (i18n, cross-platform)
├── usage-bar.conf          ← language config (copy to ~/.claude/)
└── install.sh              ← one-shot installer with language prompt
```

---

## Compatibility

| Platform | Status |
|----------|--------|
| macOS | ✓ |
| Linux | ✓ |
| Windows (Git Bash / WSL) | ✓ |

Python is auto-detected (`python3`, `python`, common paths). No external dependencies — standard library only.

---

## License

MIT

---

---

<a name="italiano"></a>

# claude-usage-bar — Italiano

Una barra di stato persistente per **Claude Code CLI** che mostra in tempo reale i limiti di utilizzo dell'account (finestre 5h e 7d), la finestra di contesto della sessione corrente e il countdown al reset — esattamente come la pagina "Utilizzo" nelle impostazioni di Claude.

La barra si aggiorna automaticamente dopo ogni risposta, sotto la casella di input.

---

## Anteprima

### Utilizzo normale
```
5h: ██░░░░░░ 28%  reset 2h 14m  |  7d: ████░░░░ 55%  reset 4g 0h  |  ctx: ███░░░░░ 42%
```

### Avvicinamento ai limiti (arancione)
```
5h: ██████░░ 85%  reset 0h 42m  |  7d: ████░░░░ 62%  reset 1g 6h  |  ctx: ██████░░ 75%
```

### Limiti critici (rosso)
```
5h: ███████░ 95%  reset 0h 12m  |  7d: ███████░ 92%  reset 3g 2h  |  ctx: ███████░ 88%
```

---

## Campi

| Campo | Significato | Soglie colore |
|-------|-------------|---------------|
| **5h** | Rate limit ultime 5 ore (proxy giornaliero) | verde < 80% · arancione 80–90% · rosso ≥ 90% |
| **7d** | Rate limit settimanale | verde < 80% · arancione 80–90% · rosso ≥ 90% |
| **ctx** | Finestra di contesto della sessione corrente | verde < 70% · arancione 70–80% · rosso > 80% |
| **reset** | Countdown al reset | ore/minuti se < 24h · giorni e ore se ≥ 24h |

> **Nota:** `5h` e `7d` mostrano dati reali solo con piano **Claude.ai Pro o Max**.
> Con API key standalone appariranno come `N/A`.

---

## Installazione

### Opzione 1 — Script automatico (consigliato)

```bash
git clone https://github.com/YOUR_USERNAME/claude-usage-bar.git
cd claude-usage-bar
bash install.sh
```

L'installer chiederà la lingua preferita e configurerà tutto automaticamente.

Poi **riavvia Claude Code**.

### Opzione 2 — Manuale

1. Copia `statusline-usage.sh` in `~/.claude/` e rendilo eseguibile:
   ```bash
   cp statusline-usage.sh ~/.claude/statusline-usage.sh
   chmod +x ~/.claude/statusline-usage.sh
   ```

2. Copia il file di configurazione:
   ```bash
   cp usage-bar.conf ~/.claude/usage-bar.conf
   ```

3. Aggiungi a `~/.claude/settings.json`:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/statusline-usage.sh"
     }
   }
   ```

4. Riavvia Claude Code.

---

## Cambiare la lingua

### Metodo 1 — Modifica il file di configurazione

Apri `~/.claude/usage-bar.conf` e cambia la riga `LANG`:

```ini
LANG=en   # English
LANG=it   # Italiano
```

Non serve riavviare — la modifica è attiva dalla risposta successiva.

### Metodo 2 — Reinstalla con lingua diversa

```bash
bash install.sh --lang en
```

### Metodo 3 — Variabile d'ambiente per sessione singola

```bash
USAGE_BAR_LANG=en claude
```

### Metodo 4 — Da Claude Code

Scrivi `/usage-bar` e chiedi a Claude di cambiare la lingua.

---

## Aggiungere una nuova lingua

Apri `statusline-usage.sh` e aggiungi una nuova voce nel dizionario `T` nel blocco Python:

```python
T = {
    "en": { ... },
    "it": { ... },
    "fr": {                        # ← aggiungi qui la tua lingua
        "waiting":   "En attente de la première réponse...",
        "reset_now": "réinitialisation maintenant",
        "na":        "N/D",
        "5h":        "5h",
        "7d":        "7j",
        "ctx":       "ctx",
        "reset":     "réinit.",
        "days":      "j",
        "hours":     "h",
        "minutes":   "m",
    },
}
```

Poi imposta `LANG=fr` in `~/.claude/usage-bar.conf`.
