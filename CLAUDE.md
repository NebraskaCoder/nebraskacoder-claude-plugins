# nebraskacoder-claude-plugins

A personal Claude Code **plugin marketplace**. Not an app — there's no
build/test/typecheck step. The only "validation" is that the JSON files parse and
cross-reference correctly (see below). Content is JSON manifests + Markdown
components + the occasional bundled script.

## Layout

- `.claude-plugin/marketplace.json` — the one catalog, at the repo root. Lists
  every plugin in its `plugins` array.
- `plugins/<name>/.claude-plugin/plugin.json` — each plugin's manifest.
- `plugins/<name>/{commands,agents,skills,hooks}/` — components, auto-discovered.
- `.claude/skills/` — repo tooling skills (`create-plugin`, `update-plugin`),
  used only while working *in* this repo; not shipped in the marketplace.

## Invariants (get these wrong and installs/updates break)

- A plugin's `marketplace.json` entry `name` must exactly match its `plugin.json`
  `name`. `source` is relative to the repo root: `./plugins/<name>`.
- **Version lives in two places that must stay equal:** `plugin.json` `version`
  and that plugin's `marketplace.json` entry `version`. Claude Code resolves
  updates from the per-plugin version, so a bump that misses either spot ships a
  stale or skipped update.
- The **top-level** `marketplace.json` `version` is catalog metadata, *not* part
  of the update mechanism. Leave it alone on a routine plugin bump; move it only
  when a plugin is added to or removed from the catalog.
- Component dirs (`commands/`, `agents/`, `skills/`, `hooks/hooks.json`,
  `.mcp.json`) are auto-discovered. Don't add path keys for them to `plugin.json`
  unless a component lives somewhere non-standard.
- Keep the `plugin.json` `description` and its `marketplace.json` entry
  `description` in sync.

## Workflows (use the skills — they encode the conventions and validate)

- **Add a plugin** → the `create-plugin` skill. Scaffolds the folder, manifest,
  and components, then registers it in the catalog.
- **Release a change / bump a version / wire up a newly added component** → the
  `update-plugin` skill. Asks patch/minor/major and syncs both version spots.
- Full `plugin.json` field reference and component starter templates:
  `.claude/skills/create-plugin/references/`. Read on demand; don't duplicate here.

## Repo etiquette

- Author defaults for new manifests: `NebraskaCoder` /
  `nebraskacoder@gmail.com` / `https://github.com/NebraskaCoder`.
- After editing any JSON, confirm it parses and names/versions line up, e.g.:
  `python3 -c "import json,sys; [json.load(open(f)) for f in sys.argv[1:]]; print('ok')" <files>`
- Don't commit or push unless asked — leave the working tree ready.
