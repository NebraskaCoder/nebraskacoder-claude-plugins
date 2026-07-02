---
name: create-plugin
description: >-
  Scaffold a new Claude Code plugin inside this marketplace repo
  (nebraskacoder-claude-plugins) and register it in the marketplace catalog. Use
  this whenever the user wants to create, add, scaffold, bootstrap, or start a
  new plugin here — including phrasings like "new plugin", "add a plugin", "make
  me a plugin that…", "create a command/agent/skill/hook plugin", or "add
  something to my marketplace". Trigger it even when the user describes plugin
  functionality without saying the word "scaffold". It creates
  plugins/<name>/.claude-plugin/plugin.json, stubs the chosen components
  (commands, agents, skills, hooks, MCP), and appends the plugin to
  .claude-plugin/marketplace.json.
---

# Create a plugin in this marketplace

This skill scaffolds a new plugin in **this repository**
(`nebraskacoder-claude-plugins`) and wires it into the marketplace so it becomes
installable via `/plugin install <name>@nebraskacoder-claude-plugins`.

Everything here is tuned to this repo's conventions. Before doing anything,
confirm you are working inside the marketplace repo: there must be a
`.claude-plugin/marketplace.json` at the repo root. If there isn't, stop and tell
the user this skill only runs inside the marketplace repo.

## The repo's layout (what you're building into)

```
nebraskacoder-claude-plugins/
├── .claude-plugin/
│   └── marketplace.json      # catalog — you append the new plugin here
└── plugins/
    └── <plugin-name>/        # you create this whole folder
        ├── .claude-plugin/
        │   └── plugin.json   # the plugin manifest
        ├── commands/         # optional — slash commands (*.md)
        ├── agents/           # optional — subagents (*.md)
        ├── skills/           # optional — <skill-name>/SKILL.md
        └── hooks/
            └── hooks.json    # optional — hook definitions
```

Only `plugin.json` lives inside a plugin's `.claude-plugin/`. Every component
directory (`commands/`, `agents/`, `skills/`, `hooks/`) sits at the plugin root
and is auto-discovered by Claude Code — no manifest wiring is needed for them.

## Workflow

Follow these steps in order. Prefer asking the questions in a single batch (use
AskUserQuestion when available) so the user isn't drip-fed prompts.

### 1. Gather the essentials

Ask for, and settle on, these before creating any files:

- **name** — the plugin identifier. Must be kebab-case (lowercase letters,
  digits, hyphens). This is what users type in `/plugin install
  <name>@nebraskacoder-claude-plugins`. If the user gives a name with spaces or
  capitals, convert it and confirm the converted form.
- **description** — one sentence on what the plugin does. Goes in both the
  manifest and the marketplace entry.
- **version** — default `0.1.0` unless the user says otherwise.
- **author** — default to the repo owner unless told otherwise:
  - name: `NebraskaCoder`
  - email: `nebraskacoder@gmail.com`
  - url: `https://github.com/NebraskaCoder`
- **license** — default `Unlicense` (this repo is public-domain; see its
  `LICENSE`). Only change it if the user asks.

Before writing anything, check that `plugins/<name>/` does not already exist. If
it does, stop and ask whether to pick a different name or update the existing
plugin — do not overwrite it.

### 2. Pick components

Ask which components to include (multiple allowed): **commands**, **agents**,
**skills**, **hooks**, **MCP servers**. For each one the user picks, get enough
detail to make a *meaningful* first stub, not an empty placeholder — e.g. the
command's purpose, the agent's job, the skill's trigger, the hook's event. A stub
the user can immediately edit into something real is far more useful than a
lorem-ipsum file.

It's fine to create a plugin with no components yet (just the manifest) if that's
what the user wants.

### 3. Create the manifest

Write `plugins/<name>/.claude-plugin/plugin.json`. Minimal shape:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "<name>",
  "version": "0.1.0",
  "description": "<description>",
  "author": {
    "name": "NebraskaCoder",
    "email": "nebraskacoder@gmail.com",
    "url": "https://github.com/NebraskaCoder"
  },
  "homepage": "https://github.com/NebraskaCoder/nebraskacoder-claude-plugins",
  "license": "Unlicense",
  "keywords": []
}
```

`name` is the only strictly required field, but always include `version`,
`description`, `author`, and `license` — they drive the UI and update behavior. Only add
component path keys (`commands`, `agents`, `skills`, `hooks`, `mcpServers`) if the
user puts components in non-default locations; the default directories are
auto-discovered, so listing them is redundant. See `references/plugin-json.md`
for the full field list.

### 4. Stub the chosen components

Create only the directories the user asked for, each with one real starter file.
Templates and conventions are in `references/component-templates.md` — read it and
adapt the stubs to what the user described. Quick summary:

- `commands/<cmd>.md` — a slash command; markdown body with optional YAML
  frontmatter (`description`, `argument-hint`, `allowed-tools`).
- `agents/<agent>.md` — a subagent; YAML frontmatter with `name`, `description`
  (with trigger examples), optional `tools`, then the system prompt.
- `skills/<skill>/SKILL.md` — a skill; YAML frontmatter with `name` +
  `description`, then instructions. Becomes `/<plugin>:<skill>`.
- `hooks/hooks.json` — event → matcher → command. Reference bundled scripts with
  `${CLAUDE_PLUGIN_ROOT}` so paths work wherever the plugin is installed.
- `.mcp.json` — MCP server config; also use `${CLAUDE_PLUGIN_ROOT}` for bundled
  server paths.

### 5. Register in the marketplace

This is the step that makes the plugin real. Append an object to the `plugins`
array in the root `.claude-plugin/marketplace.json`:

```json
{
  "name": "<name>",
  "source": "./plugins/<name>",
  "description": "<description>",
  "version": "0.1.0"
}
```

`source` is a path **relative to the repo root** (not to the marketplace file),
so it is always `./plugins/<name>`. `name` here must match the plugin's manifest
`name` exactly. Keep entries in the array in a sensible order (e.g. the order
they were added, or alphabetical — match whatever the file already does).

### 6. Validate and report

- Validate every JSON file you wrote or changed actually parses. A fast check:
  `python3 -c "import json,sys; [json.load(open(f)) for f in sys.argv[1:]]; print('ok')" <files...>`
- Confirm `marketplace.json`'s new `name` matches the manifest `name`.
- Tell the user exactly what was created (file tree), and give the next steps:
  fill in the component stubs, then commit. Remind them that to try it locally
  they can run `/plugin marketplace add ./` (or the repo path) and
  `/plugin install <name>@nebraskacoder-claude-plugins`.

Do not commit or push unless the user asks — just leave the working tree ready.

## Reference files

- `references/plugin-json.md` — full `plugin.json` schema and field reference.
- `references/component-templates.md` — starter templates for commands, agents,
  skills, hooks, and MCP configs, plus the `${CLAUDE_PLUGIN_ROOT}` convention.
