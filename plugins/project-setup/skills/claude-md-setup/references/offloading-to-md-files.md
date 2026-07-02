# Offloading content out of the always-loaded context

The point of a lean `CLAUDE.md` is to move everything else into mechanisms that load
**only when relevant** (four of them), plus **hooks** for rules that shouldn't sit in
memory at all — and one important non-savings caveat about imports.

References: [memory docs](https://code.claude.com/docs/en/memory),
[skills](https://code.claude.com/docs/en/skills),
[hooks](https://code.claude.com/docs/en/hooks-guide),
[features overview](https://code.claude.com/docs/en/features-overview).

## The critical caveat: `@`-imports do NOT save context

`CLAUDE.md` can import files with `@path/to/file` syntax, but **imported files are
expanded and loaded into context at launch**, alongside the file that imports them.
So imports are for **organization/reuse**, *not* context reduction — the tokens are
spent every session either way.

Details ([Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)):

- Both relative and absolute paths work; **relative resolves against the importing
  file**, not the cwd.
- Imports can nest, **max depth 4 hops**.
- Import parsing **skips code spans and fenced code blocks** — wrap a path in
  backticks (`` `@README` ``) to mention it without importing.
- First time a project uses external imports, Claude shows an **approval dialog**;
  decline and imports stay disabled silently.
- You can import from home, e.g. `@~/.claude/my-preferences.md`, to share personal
  instructions across worktrees.

**Use imports when** you want one canonical file (e.g. `@AGENTS.md`, a shared
standards file) reflected in `CLAUDE.md` and you accept it loading every session.
**Don't use imports** expecting a smaller context.

## 1. Path-scoped rules — `.claude/rules/` (the workhorse for "load when relevant")

Put topic files in `.claude/rules/`. Add a `paths:` glob frontmatter and the rule
**only loads when Claude reads/edits a matching file**. This is the primary tool for
file-type- or area-specific guidance.

Reference:
[Organize rules with `.claude/rules/`](https://code.claude.com/docs/en/memory#organize-rules-with-claude/rules/)
and [Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules).

```
your-project/
├── .claude/
│   ├── CLAUDE.md
│   └── rules/
│       ├── code-style.md        # no `paths:` → loads every session
│       ├── testing.md           # scope with `paths:` to load on demand
│       └── frontend/
│           └── components.md     # nested dirs are discovered recursively
```

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/**/*.{ts,tsx}"    # brace expansion for multiple extensions
---

# API rules
- All endpoints validate input.
- Use the standard error response format.
```

Facts to remember:

- **No `paths:` field → loaded unconditionally at launch**, same priority as
  `.claude/CLAUDE.md`. Add `paths:` to make it conditional.
- Path-scoped rules **trigger when Claude reads a matching file**, not on every tool
  use. They are *not* loaded at startup.
- One topic per file, descriptive filename; all `.md` discovered **recursively**.
- Glob patterns: `**/*.ts`, `src/**/*`, `*.md` (root only), `src/components/*.tsx`,
  plus brace expansion.
- **Symlinks are supported** — link a shared rules dir/file into many projects
  (`ln -s ~/shared-rules .claude/rules/shared`).
- **User-level rules** in `~/.claude/rules/` apply to every project and load *before*
  project rules (project rules win on conflict).
- Frontmatter keys: just `paths:` (a YAML list of globs). No `name`/`description`.

## 2. Skills — `.claude/skills/*/SKILL.md` (on-demand procedures & domain knowledge)

Skills load **only when invoked or when Claude judges them relevant** — ideal for
multi-step workflows and domain knowledge that shouldn't sit in context all the time.

```markdown
---
name: api-conventions
description: REST API design conventions for our services
---
# API Conventions
- Use kebab-case for URL paths
- Version APIs in the URL path (/v1/, /v2/)
```

Add `disable-model-invocation: true` for side-effecting workflows you want to trigger
manually (`/skill-name`). Reference: <https://code.claude.com/docs/en/skills>.

## 3. Subdirectory `CLAUDE.md` — on-demand, by directory

A `CLAUDE.md` in a subdirectory below the cwd loads **when Claude reads a file in
that directory**. Good for area-specific context in large repos. Downside vs. rules:
it's directory-scoped (not glob-scoped) and **not re-injected after `/compact`**
until Claude next reads there. Prefer `.claude/rules/` with `paths:` for finer
control.

## 4. Plain `docs/*.md` pointed to in prose (heaviest reference material)

For long reference docs, keep them as ordinary markdown under `docs/` and **mention
them in `CLAUDE.md` in prose** ("Detailed X → `docs/x.md`") *without* `@`-importing.
Claude reads them with its file tools **only when the task needs them**. This is the
leanest option for large content: zero startup cost, loaded on demand.

## Decision matrix

| You have… | Use | Loads when |
|---|---|---|
| Always-true, whole-project facts | `CLAUDE.md` (root) | Every session |
| Rules specific to a file type / area | `.claude/rules/*.md` **with `paths:`** | Claude touches a matching file |
| Rules that truly apply everywhere, kept modular | `.claude/rules/*.md` **without `paths:`** | Every session |
| A multi-step procedure or domain playbook | **Skill** (`.claude/skills/*/SKILL.md`) | Invoked / judged relevant |
| Heavy reference doc | `docs/*.md` + **prose pointer** | Claude opens it on demand |
| One canonical file mirrored into CLAUDE.md | `@import` (accept per-session cost) | Every session |
| A rule that must ALWAYS run (e.g. pre-commit) | **Hook**, not memory | Deterministically, at the lifecycle event |

## 5. Hooks — for rules that must ALWAYS run (deterministic enforcement)

Memory is **advisory**: Claude reads `CLAUDE.md`/rules and *tries* to comply, but may
not. When something must happen **every time, regardless of what Claude decides** — run
the linter after each edit, run tests/format before a commit, block writes to a
protected path — that's a **hook**, not a memory instruction. Hooks are shell commands
Claude Code runs deterministically at lifecycle events, so they're the right tool
whenever "please remember to X" isn't reliable enough.

- **Configured in** `.claude/settings.json` (or via `/hooks`), not in any `.md` file.
- **Common events:** `PostToolUse` (e.g. run `ruff`/`prettier` after an edit), `Stop`
  (gate before finishing — run tests, propose CLAUDE.md updates), `PreToolUse` (block a
  dangerous command or a write to `migrations/`), `SessionStart` (print context/setup).
- **Rule of thumb:** if you're tempted to write `IMPORTANT: always run X` in `CLAUDE.md`
  and X is a shell command, make it a hook instead — then you can *delete* that line from
  memory (freeing context) because enforcement no longer depends on adherence.
- Claude can write hooks for you ("write a hook that runs eslint after every file edit").

Reference: <https://code.claude.com/docs/en/hooks-guide> (event list and input fields:
<https://code.claude.com/docs/en/hooks>).

## Anti-patterns

- Treating `@`-imports as a way to shrink context. (They don't.)
- Dumping a whole style guide inline in `CLAUDE.md` instead of a path-scoped rule.
- Putting a rarely-needed procedure in `CLAUDE.md` instead of a skill.
- Relying on a nested `CLAUDE.md` for a critical rule (it can vanish after
  `/compact`) — keep critical rules in the root file.
