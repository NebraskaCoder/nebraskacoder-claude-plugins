# NebraskaCoder Claude Plugins

A personal [Claude Code](https://code.claude.com/docs/en/claude-code) plugin
marketplace. It hosts my reusable plugins — commands, agents, skills, and hooks
— that I can install into any Claude Code session.

## Installing from this marketplace

Add the marketplace once, then install any plugin from it:

```
/plugin marketplace add NebraskaCoder/nebraskacoder-claude-plugins
/plugin install <plugin-name>@nebraskacoder-claude-plugins
```

You can also browse and manage everything interactively with `/plugin`.

Useful management commands:

```
/plugin marketplace list                 # list added marketplaces
/plugin marketplace update nebraskacoder-claude-plugins
/plugin marketplace remove nebraskacoder-claude-plugins
```

## Repository layout

```
nebraskacoder-claude-plugins/
├── .claude-plugin/
│   └── marketplace.json     # marketplace catalog (lists every plugin)
├── plugins/                 # one subdirectory per plugin
│   └── <plugin-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json  # the plugin's manifest
│       ├── commands/        # slash commands (*.md)
│       ├── agents/          # subagents (*.md)
│       ├── skills/          # skills (<name>/SKILL.md)
│       └── hooks/
│           └── hooks.json   # hook definitions
└── README.md
```

- There is exactly **one** `marketplace.json`, at the repo root under
  `.claude-plugin/`.
- Each plugin lives in its own folder under `plugins/` and has its own
  `.claude-plugin/plugin.json`.
- The marketplace's `metadata.pluginRoot` is `./plugins`, so plugin `source`
  paths are resolved relative to that directory.

## Adding a new plugin

Each new plugin needs a `plugins/<plugin-name>/` folder with a
`.claude-plugin/plugin.json`, plus an entry appended to the `plugins` array in
`.claude-plugin/marketplace.json`.

## Available plugins

_None yet — the first one is on its way._
