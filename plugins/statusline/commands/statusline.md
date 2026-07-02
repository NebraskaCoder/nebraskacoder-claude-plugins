---
description: Install NebraskaCoder's three-line Claude Code statusline (model/git/PR, context+cost bar, rate limits) into ~/.claude and wire it into settings.json.
argument-hint: "[--print] to preview without installing"
allowed-tools: Bash, Read, Write, Edit
---

# Install the statusline

Install the bundled statusline so the user's Claude Code shows the exact
three-line status they had before: line 1 = model, fast-mode, thinking effort,
directory, git branch (+dirty), PR, output style; line 2 = a context-usage bar
with absolute tokens, cost, session duration, and a >200k warning; line 3 =
Pro/Max rate-limit windows with usage % and reset countdowns.

The script is bundled with this plugin at `${CLAUDE_PLUGIN_ROOT}/assets/statusline.sh`
— treat it as the source of truth and copy it verbatim. Do not rewrite it.

If the argument is `--print`, only show what you *would* do (the target paths and
the settings block) and stop — don't touch anything.

## Steps

### 1. Check dependencies

The script parses its JSON input with `jq` and reads git state with `git`. Run
`command -v jq` and `command -v git`. If `jq` is missing, warn the user clearly:
without it the statusline renders nothing (each field falls back to empty). Offer
the install hint for their platform (`brew install jq` on macOS, `apt install jq`
on Debian/Ubuntu) and ask whether to continue anyway. `git` is only used inside
repos, so its absence just hides the branch segment — note it but proceed.

### 2. Install the script

Copy the bundled script to the user's home Claude directory and make it
executable — this mirrors the user's original setup, where `settings.json`
points at `~/.claude/statusline.sh`:

```bash
mkdir -p ~/.claude
cp "${CLAUDE_PLUGIN_ROOT}/assets/statusline.sh" ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Installing a copy (rather than pointing `settings.json` at the plugin's cache
path) is deliberate: the cache path changes across plugin versions, and a stable
`~/.claude/statusline.sh` is exactly what the user had.

If `~/.claude/statusline.sh` already exists and differs from the bundled one,
show the user a diff and confirm before overwriting — they may have local tweaks
worth keeping.

### 3. Wire it into settings.json

The statusline only shows once `~/.claude/settings.json` has a `statusLine`
block. Merge in this exact block **without disturbing any other keys** — this
file holds the user's permissions, env, hooks, etc., so never overwrite the whole
file. Back it up first, then do a structured edit.

Target block (matches the user's original config):

```json
"statusLine": {
  "type": "command",
  "command": "~/.claude/statusline.sh",
  "padding": 0,
  "refreshInterval": 60
}
```

A safe merge that preserves everything else (creates the file if absent):

```bash
cp ~/.claude/settings.json ~/.claude/settings.json.bak 2>/dev/null || true
python3 - <<'PY'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
try:
    with open(p) as f: cfg = json.load(f)
except FileNotFoundError:
    cfg = {}
cfg["statusLine"] = {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0,
    "refreshInterval": 60,
}
with open(p, "w") as f:
    json.dump(cfg, f, indent=2); f.write("\n")
print("statusLine written to", p)
PY
```

### 4. Verify it renders

Prove the install works by feeding the script a representative payload and
showing the user the actual colored output — this catches a missing `jq` or a
broken copy immediately:

```bash
printf '%s' '{
  "model": {"display_name": "Opus 4.8"},
  "workspace": {"current_dir": "'"$PWD"'"},
  "context_window": {"used_percentage": 42, "total_input_tokens": 84000, "context_window_size": 200000},
  "cost": {"total_cost_usd": 1.23, "total_duration_ms": 185000},
  "output_style": {"name": "default"},
  "effort": {"level": "high"},
  "fast_mode": false,
  "exceeds_200k_tokens": false,
  "rate_limits": {
    "five_hour": {"used_percentage": 24, "resets_at": '"$(( $(date +%s) + 14520 ))"'},
    "seven_day": {"used_percentage": 61, "resets_at": '"$(( $(date +%s) + 320000 ))"'}
  }
}' | ~/.claude/statusline.sh
```

If it prints three lines with a green context bar and the rate-limit row, it's
working.

### 5. Report

Tell the user what changed (`~/.claude/statusline.sh` installed, `statusLine`
block added to `settings.json`, backup at `settings.json.bak`) and that the
statusline appears on the next prompt / refreshes every 60s. If they're in an
active session and don't see it, a quick restart of Claude Code picks it up.
