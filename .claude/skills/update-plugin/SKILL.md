---
name: update-plugin
description: >-
  Update an existing plugin in this marketplace repo
  (nebraskacoder-claude-plugins) after it has changed — bump its version
  everywhere and keep the plugin manifest and marketplace catalog in sync. Use
  this whenever the user has modified a plugin and wants to "release", "bump the
  version", "cut a new version", "publish an update", or says a plugin "changed /
  needs a version bump". Also trigger when the user added a new component (a new
  skill, command, agent, or hook) to an existing plugin and wants it wired up and
  versioned, or asks to "sync the marketplace" / "update marketplace.json" for a
  plugin. It asks whether the change is a patch, minor, or major bump, then
  updates the version in plugins/<name>/.claude-plugin/plugin.json and the
  matching entry in .claude-plugin/marketplace.json, syncs descriptions and
  keywords, and validates everything lines up.
---

# Update a plugin in this marketplace

This skill releases a **change to an existing plugin** in this repository
(`nebraskacoder-claude-plugins`): it bumps the version and propagates that bump —
plus any description/keyword changes — to every place the version is recorded, so
Claude Code delivers the update to installers.

Use `create-plugin` to scaffold a brand-new plugin; use **this** skill once a
plugin already exists and its contents have changed.

Before doing anything, confirm you are inside the marketplace repo: there must be
a `.claude-plugin/marketplace.json` at the repo root. If there isn't, stop and
tell the user this skill only runs inside the marketplace repo.

## Where a version lives (what "everywhere" means)

For a single plugin, the version is recorded in **two** places that must always
match:

1. `plugins/<name>/.claude-plugin/plugin.json` → `version`
2. `.claude-plugin/marketplace.json` → the plugin's entry in the `plugins` array → `version`

This is what actually drives updates. Claude Code resolves a plugin's version
from the **first** of these that is set: (1) `version` in `plugin.json`, (2)
`version` in the marketplace entry, (3) the plugin's git commit SHA. It compares
the resolved version to what an installer already has — if they match, `/plugin
update` and auto-update **skip** the plugin. So the whole point of this skill is
to move that resolved version forward. Because `plugin.json` wins when the two
disagree, keep them equal so the marketplace entry never advertises a stale
version.

The **description** also lives in both of those spots and should stay in sync.
`keywords` live only in `plugin.json`.

There is also a **top-level** `version` on the marketplace catalog itself
(`.claude-plugin/marketplace.json` → top-level `version`). Per the Claude Code
docs this is just the "marketplace manifest version" — it is **not** part of the
plugin-update mechanism (that's driven entirely by the per-plugin version above).
So a routine bump of one existing plugin **must not** touch it. Treat it as a
catalog-level version and only bump it when the catalog's structure changes — a
plugin is added or removed. (If the user tells you otherwise, follow them.)

## Workflow

### 1. Identify which plugin changed

If the user named the plugin, use it. Otherwise infer it from what changed —
`git status --short` and `git -C . diff --stat` will show which `plugins/<name>/`
directory has edits. If more than one plugin changed, handle them one at a time
and confirm the list with the user. Confirm `plugins/<name>/` exists before
proceeding.

### 2. Survey the change so you can recommend a bump

Look at what actually changed before asking anything — this lets you *recommend* a
bump level instead of making the user guess. Useful signals:

- `git diff --stat -- plugins/<name>/` and `git status --short -- plugins/<name>/`
  to see which files changed and whether any are new or deleted.
- New component directories/files (`skills/<new>/SKILL.md`, `commands/<new>.md`,
  `agents/<new>.md`, `hooks/hooks.json`) → a capability was **added**.
- Deleted or renamed components → a capability was **removed/changed** (breaking).
- Read the actual diff for behavior-affecting edits (a command's arguments, a
  skill's `name`, a hook's matcher) vs. cosmetic ones (wording, typos, reference
  docs).

Map what you find to semver:

- **patch** (`0.1.0 → 0.1.1`) — fixes and polish that change nothing about what
  the plugin *offers*: bug fixes in an existing component, prompt/wording tweaks,
  reference-doc edits, typos, metadata cleanup.
- **minor** (`0.1.0 → 0.2.0`) — a new, backward-compatible capability: a new
  command/agent/skill/hook, new options, broader triggers. Existing usage still
  works unchanged. **Adding a new skill/component is at least a minor bump.**
- **major** (`0.1.0 → 1.0.0`) — a breaking change: a component removed or renamed
  (including a skill rename, which changes its `/<plugin>:<skill>` invocation), a
  command's arguments/behavior changed incompatibly, or a restructure that breaks
  existing usage.

### 3. Ask the bump level

Read the current version from `plugin.json` first so you can show concrete target
versions. Use AskUserQuestion with the three options, lead with your recommended
one (labelled "(Recommended)"), and in each option's description show the exact
resulting version, e.g. for a current `0.1.0`:

- **Patch → 0.1.1** — fixes/polish, no change to what the plugin offers.
- **Minor → 0.2.0** — new backward-compatible capability (new skill/command/etc.).
- **Major → 1.0.0** — breaking change (component removed/renamed, behavior changed).

Base the recommendation on your step-2 survey. If the user's answer conflicts with
the survey (e.g. they picked patch but a new skill was added), say so briefly and
let them decide — they may have a reason.

Compute the new version by incrementing the chosen field and zeroing the ones to
its right (`major.minor.patch`). Preserve any pre-release/build suffix only if the
user asks.

### 4. If a component was added or removed, wire it up

Components in the standard directories (`commands/`, `agents/`, `skills/`,
`hooks/hooks.json`, `.mcp.json`) are **auto-discovered** — there is no manifest
list of them to edit, so a new skill needs no path wiring as long as it sits in
`plugins/<name>/skills/<skill>/SKILL.md`. What actually needs attention:

- **Verify the new component is well-formed** so it will load and trigger. For a
  skill: `SKILL.md` has YAML frontmatter with `name` (matching its directory) and
  a `description`. For a command/agent: valid frontmatter. For hooks/MCP: valid
  JSON, and bundled paths use `${CLAUDE_PLUGIN_ROOT}`.
- **Refresh the plugin's `description`** if the change meaningfully expands (or
  narrows) what the plugin does, so the `/plugin` UI reflects reality. Mirror any
  description edit into the marketplace entry (they must match).
- **Refresh `keywords`** in `plugin.json` if new capabilities introduce obvious
  new discovery terms.
- Only add a component **path key** to `plugin.json` (`commands`, `skills`, …) if
  the component lives somewhere non-standard; standard dirs must stay omitted.

If a component was **removed**, that's a major bump (step 2/3) — and make sure no
stale path key in `plugin.json` still points at it.

### 5. Apply the edits

Make exactly these changes:

1. `plugins/<name>/.claude-plugin/plugin.json` → set `version` to the new version;
   update `description`/`keywords` if step 4 called for it.
2. `.claude-plugin/marketplace.json` → in the plugin's entry, set `version` to the
   **same** new version; mirror the `description` if it changed.
3. Top-level marketplace `version` → only if a plugin was added/removed from the
   catalog (usually not — leave it alone for a routine bump).

Preserve each file's existing formatting (indentation, key order, spacing). Prefer
targeted edits over rewriting whole files.

### 6. Validate and report

- Every JSON file you touched must still parse. Fast check:
  `python3 -c "import json,sys; [json.load(open(f)) for f in sys.argv[1:]]; print('ok')" .claude-plugin/marketplace.json plugins/<name>/.claude-plugin/plugin.json`
- The `version` in `plugin.json` **equals** the `version` in that plugin's
  marketplace entry.
- The `name` still matches between the two files, and `description` is in sync.
- Report to the user: old → new version, the bump level, which files changed, and
  any description/keyword updates. Give next steps: review the diff and commit
  (e.g. `git commit -m "release <name> v<new>"`). Remind them that installers get
  the update when the bumped `version` is published.

Do not commit or push unless the user asks — leave the working tree ready.

## Reference files

Schema details are shared with `create-plugin`; consult those rather than
duplicating them:

- `../create-plugin/references/plugin-json.md` — full `plugin.json` and
  marketplace-entry field reference.
- `../create-plugin/references/component-templates.md` — component shapes, useful
  when verifying a newly added component is well-formed.
