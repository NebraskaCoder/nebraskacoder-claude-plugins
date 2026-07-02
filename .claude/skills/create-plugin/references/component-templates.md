# Component starter templates

Use these as starting points and adapt them to what the user described. Create
only the components the user asked for. Each file below sits at the plugin root
(e.g. `plugins/<name>/commands/foo.md`), never inside `.claude-plugin/`.

## `${CLAUDE_PLUGIN_ROOT}`

An environment variable that resolves to the absolute path of the installed
plugin's root directory. Use it any time a hook, MCP server, or command needs to
reference a file bundled with the plugin, so the path works regardless of where
the plugin gets installed. Example: `"${CLAUDE_PLUGIN_ROOT}/scripts/run.sh"`.

## Command — `commands/<command>.md`

Auto-discovered; becomes `/<plugin>:<command>`. Frontmatter is optional. The body
is the prompt; `$ARGUMENTS` (or `$1`, `$2`, …) interpolate user args.

```markdown
---
description: One line describing what this command does.
argument-hint: "[optional-arg]"
allowed-tools: Read, Grep, Bash
---

# <Command title>

<Instructions to Claude for what to do when this command runs. Reference
arguments with $ARGUMENTS.>
```

## Agent — `agents/<agent>.md`

Auto-discovered subagent. The `description` is the trigger signal — make it
specific and include example situations, because that's how the model decides to
invoke it.

```markdown
---
name: <agent-name>
description: >-
  Use this agent when <specific situation>. Include concrete example triggers.
  Be a little pushy about when it applies so it isn't under-triggered.
tools: Read, Grep, Glob, Bash
---

You are <role>. <System prompt: responsibilities, method, output format, and
what "done" looks like.>
```

Omit `tools` to give the agent the default tool set; list tools only to restrict
it.

## Skill — `skills/<skill>/SKILL.md`

Auto-discovered; becomes `/<plugin>:<skill>`. Each skill is its own subdirectory
containing `SKILL.md` (plus optional `references/`, `scripts/`, `assets/`).

```markdown
---
name: <skill-name>
description: >-
  What the skill does AND when to use it — this is the primary trigger, so name
  the situations and phrasings that should invoke it. Lean slightly pushy to
  avoid under-triggering.
---

# <Skill title>

<Instructions, in imperative voice. Explain the *why* behind steps. Keep the body
focused; move long reference material into references/ and point to it.>
```

## Hooks — `hooks/hooks.json`

Auto-discovered. Maps events to matchers to commands. Reference bundled scripts
with `${CLAUDE_PLUGIN_ROOT}`.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/scripts/on-edit.sh\""
          }
        ]
      }
    ]
  }
}
```

Common events: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`,
`SubagentStop`, `SessionStart`, `SessionEnd`, `PreCompact`, `Notification`. If a
hook runs a script, create it under `scripts/` and make it executable
(`chmod +x`).

## MCP servers — `.mcp.json`

Auto-discovered at the plugin root. Standard MCP config; use
`${CLAUDE_PLUGIN_ROOT}` for bundled server binaries or configs.

```json
{
  "mcpServers": {
    "<server-name>": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
    }
  }
}
```
