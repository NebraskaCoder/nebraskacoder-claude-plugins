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
- Plugin `source` paths in the catalog are relative to the repo root, e.g.
  `"./plugins/<plugin-name>"`.

## Adding a new plugin

Each new plugin needs a `plugins/<plugin-name>/` folder with a
`.claude-plugin/plugin.json`, plus an entry appended to the `plugins` array in
`.claude-plugin/marketplace.json`.

The fastest way is the built-in **`create-plugin`** skill (in
`.claude/skills/`): just say something like _"create a new plugin"_ while
working in this repo and it will scaffold the folder, manifest, and any
components you pick, then register the plugin in the marketplace for you.

## Updating a plugin

After changing an existing plugin, its version needs bumping in two places that
must stay in sync — the plugin's `.claude-plugin/plugin.json` and its entry in
`.claude-plugin/marketplace.json` — since Claude Code resolves plugin updates
from that per-plugin version.

The built-in **`update-plugin`** skill (in `.claude/skills/`) handles this: say
something like _"bump the version"_, _"cut a new release"_, or _"I added a skill,
sync the marketplace"_ while working in this repo. It surveys what changed, asks
whether it's a patch, minor, or major bump, updates the version in both files,
syncs descriptions/keywords, wires up any newly added component, and validates
that everything lines up. (The top-level `marketplace.json` version is catalog
metadata and is left alone on a routine plugin bump.)

## License

Released into the public domain under [The Unlicense](https://unlicense.org) —
see [`LICENSE`](LICENSE). Use, copy, modify, and distribute freely, no
attribution required.
