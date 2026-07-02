# Monorepos & large codebases

The lean-`CLAUDE.md` principles from the other files still apply, but monorepos add
mechanics that decide what actually loads. This file covers those.

Primary source: <https://code.claude.com/docs/en/large-codebases>. Related:
[memory](https://code.claude.com/docs/en/memory),
[skills](https://code.claude.com/docs/en/skills),
[settings](https://code.claude.com/docs/en/settings).

## Example layout

```
monorepo/
  CLAUDE.md                       # root: orients Claude to the whole repo
  .claude/settings.json           # root settings (see gotcha #3)
  packages/
    api/
      CLAUDE.md                   # API-specific instructions
      .claude/settings.json       # per-package settings (self-contained)
      .claude/skills/api-testing/SKILL.md
      src/
    web/
      CLAUDE.md
      .claude/skills/component-patterns/SKILL.md
      src/
    shared/
      CLAUDE.md
      src/
```

The same patterns work in a large single tree — substitute a subsystem dir
(`src/backend/`, `lib/core/`) for `packages/api/`.

## 1. Where you launch Claude decides what loads (the #1 lever)

See [Choose where to start Claude](https://code.claude.com/docs/en/large-codebases#choose-where-to-start-claude).

| Start from | File access | CLAUDE.md loaded at launch | Use when |
|---|---|---|---|
| **Repo root** | Every file | **Root only**; each subpackage's file loads **on demand** when Claude reads there | Task spans multiple packages |
| **A package dir** | That subtree only (until you grant more) | **That dir's file + every ancestor's** | Work is scoped to one package |

Consequence: starting from `packages/api/` loads `packages/api/CLAUDE.md` + root
`CLAUDE.md`, and **no `packages/web/` instructions** enter context. Prefer starting
in the package you're working in — it's the cleanest way to scope context, better
than trying to exclude everything else.

## 2. Layer CLAUDE.md by directory

See [Layer CLAUDE.md files by directory](https://code.claude.com/docs/en/large-codebases#layer-claude-md-files-by-directory).
A common two-level split:

- **Root `CLAUDE.md`** — repo-wide only: what the repo is, package map, commit
  conventions, and *where to run commands*. Keep it oriented, not exhaustive.
- **Per-package `CLAUDE.md`** — that package's stack, build/test/dev commands, and
  local conventions.

Root example:

```markdown
This is a monorepo with three packages under packages/:
- packages/api: Node.js REST API (Express, TypeScript, PostgreSQL)
- packages/web: React frontend (Vite, TypeScript, Tailwind)
- packages/shared: shared TypeScript utilities used by both

Run commands from the package directory, not the monorepo root.
Each package has its own package.json, tsconfig.json, and test suite.
```

Per-package example (`packages/api/CLAUDE.md`):

```markdown
This package is the REST API server.
- Test: `npm test` (Vitest)     - Dev: `npm run dev` (port 3001)
- Migrations: `npm run migrate`  - Env: copy `.env.example` to `.env`

API routes are in src/routes/ (each exports an Express router).
DB queries use Knex in src/db/. Never write raw SQL in route handlers.
```

Commit these; each directory's owner maintains its file and reviews edits in PRs.

### Per-directory CLAUDE.md vs. path-scoped rules

Both target part of the tree; they differ in where the file lives and when it loads
([comparison](https://code.claude.com/docs/en/large-codebases#choose-between-per-directory-claude-md-and-path-scoped-rules)):

| Approach | Lives | Loads when | Use when |
|---|---|---|---|
| Per-directory `CLAUDE.md` | Inside the package, with its code | At launch if you start there, else on demand when Claude reads a file there | Directory owners maintain their own conventions, versioned with the code |
| Path-scoped rule (`.claude/rules/*.md` + `paths:`) | Central `.claude/` at repo root | When Claude works a file matching the glob | You want all conventions in one place, or one rule spans many scattered paths |

## 3. Gotcha: `.claude/settings.json` is NOT inherited like CLAUDE.md

CLAUDE.md files load from your starting dir **and every ancestor**. Project
**settings do not** — `.claude/settings.json` loads **only from the directory you
start Claude in**. So each package's settings file must be **self-contained**, not
layered on the root. If you also start sessions from the root, put the settings the
root needs (e.g. `Read` deny rules that must apply inside worktrees) in the root's
`.claude/settings.json` too.

## 4. Exclude irrelevant packages — `claudeMdExcludes`

When starting from the root, every subpackage's `CLAUDE.md` loads as soon as Claude
reads a file there. Skip ones you never touch
([docs](https://code.claude.com/docs/en/large-codebases#exclude-irrelevant-claude-md-files)):

```json
// .claude/settings.local.json (personal) — glob-matched against ABSOLUTE paths,
// so start relative-style patterns with **/
{
  "claudeMdExcludes": [
    "**/packages/admin-dashboard/**",   // whole package (CLAUDE.md + rules)
    "**/packages/legacy-*/**",
    "**/packages/*/CLAUDE.md"           // every package's CLAUDE.md, keep the root
  ]
}
```

The list is static (not a per-task switch). To focus on a different package day to
day, **start Claude from that package's directory** instead of editing exclusions.
Arrays merge across scopes; managed-policy CLAUDE.md can't be excluded.

## 5. Cross-package edits — `additionalDirectories` vs `--add-dir`

When started from a package, Claude can only touch that subtree. To edit a sibling
(e.g. a shared type used by `api` and `web`), grant access
([docs](https://code.claude.com/docs/en/large-codebases#grant-access-across-packages-or-repositories)):

```json
// packages/api/.claude/settings.json — relative to the start dir
{ "permissions": { "additionalDirectories": ["../shared", "../web"] } }
```

Or at runtime: `claude --add-dir ../shared`. **Important difference in what loads:**

| Added with | Loads that dir's CLAUDE.md + rules | Loads its skills |
|---|---|---|
| `additionalDirectories` setting | **Never** | **Never** |
| `--add-dir` flag / `/add-dir` | Only with `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` | Yes |

Both grant read/edit access; they differ only in whether the sibling's instructions
come along.

## 6. Per-package skills & discoverability at scale

Put area-specific procedures in `<package>/.claude/skills/*/SKILL.md`; they load on
demand only when relevant, so API tooling doesn't cost context during frontend work
([docs](https://code.claude.com/docs/en/large-codebases#add-per-directory-skills)).

Which skills are *in scope* depends on where you start:
- From a **package dir**: that dir + ancestors up to root + user/enterprise skills.
- From the **root**: skills from every subdir Claude touches — can grow into the
  hundreds.

Claude picks a skill from its **name + description**, and **descriptions get
truncated when there are many** — so keep descriptions short and lead with words a
request would actually contain (e.g. "writing or modifying tests in `packages/api/`").
Put widely-shared skills (PR conventions, deploy checklist) in the **root**
`.claude/skills/` so they load from any start dir; package cross-repo ones as a
plugin (namespaced `plugin:skill`) to avoid collisions.

You can also scope a root-level skill by file pattern via its `paths:` frontmatter
(e.g. a migration skill scoped to `**/migrations/**`).

## 7. Reduce what Claude *reads* (large-repo context control)

Beyond instructions, file reads dominate context in big repos:

- **Block generated/vendored reads**: `.gitignore`'d paths (`node_modules/`, `dist/`)
  are already skipped in search; for checked-in generated/vendored code add
  `permissions.deny` `Read(...)` rules
  ([docs](https://code.claude.com/docs/en/large-codebases#block-reads-of-generated-and-vendored-code)).
- **Code-intelligence plugin** (per language) → jump to definitions/refs via the
  language server instead of scanning files.
- **`worktree.sparsePaths`** → check out only needed dirs in worktrees (list dirs,
  not files; include `.claude` to get root rules/skills inside the worktree); pair
  with `symlinkDirectories: ["node_modules"]`.

## 8. When per-directory layering stops scaling

Files drift, no one owns the root. Move conventions into on-demand, centrally-owned
mechanisms ([docs](https://code.claude.com/docs/en/large-codebases#centralize-conventions-when-layering-stops-scaling)):

- **Plugins** — versioned bundles of skills/hooks/commands a platform team owns.
- **MCP server** — expose an existing code-search/RAG index so Claude queries it
  instead of reading files.
- **`SessionStart` hook** — print (from a repo-committed path→plugin map) which
  plugin owns the area you launched in, so Claude surfaces it up front.
- **`Stop` hook** — review the session transcript and propose CLAUDE.md updates while
  the gap is fresh.

## Cross-package changes: scope & sequence

Config controls what Claude *sees*; sequencing controls consistency
([docs](https://code.claude.com/docs/en/large-codebases#scope-and-plan-changes-that-span-packages)):

- **Do the whole change in one session** (shared edit + all call sites) so decisions
  stay consistent instead of re-derived per package.
- **Save the plan to a markdown file before editing** — a long cross-package session
  compacts along the way, and the saved plan survives where conversation may not.

## Monorepo quick checklist

- [ ] Root `CLAUDE.md` orients (package map + "run commands from the package dir")
- [ ] Each package has its own `CLAUDE.md` (stack + commands + local conventions)
- [ ] Prefer **starting Claude in the package** you're working in
- [ ] Per-package `.claude/settings.json` is **self-contained** (settings aren't inherited)
- [ ] `claudeMdExcludes` for packages you never touch (when starting from root)
- [ ] Cross-package access via `additionalDirectories` / `--add-dir` (know what loads)
- [ ] Area procedures as **per-package skills**; short, keyword-led descriptions
- [ ] `Read` deny rules + code intelligence + `sparsePaths` to cut file-read cost
- [ ] If layering stops scaling → plugins / MCP / governance hooks
