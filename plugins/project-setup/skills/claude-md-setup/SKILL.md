---
name: claude-md-setup
description: >-
  Set up or audit Claude Code project memory the right way — a lean CLAUDE.md plus
  offloaded docs, path-scoped .claude/rules/, and skills — so instructions stay
  high-signal instead of bloating context and getting ignored. Use this whenever
  setting up a repo for Claude Code, creating/scaffolding a CLAUDE.md, adding or
  organizing .claude/rules/, deciding how to structure project instructions,
  slimming a CLAUDE.md that has grown too long, or deciding which
  project-instruction content to move out of CLAUDE.md so it loads only when Claude
  needs it. Also covers monorepos (per-package CLAUDE.md, where to launch Claude,
  cross-package access). Reach for it even when the user just says "set up this
  project for Claude", "write a CLAUDE.md", "my CLAUDE.md is too long/getting
  ignored", or "how should I organize project instructions" — don't answer from
  memory, consult this skill and its references. NOT for human-facing docs (README,
  design docs, API docs), source-code comments/docstrings, or linter/formatter/
  tooling setup — only files that configure how Claude Code reads a project
  (CLAUDE.md, .claude/rules/, skills).
---

# Setting up lean Claude Code project memory

## Why this matters (the core principle)

Claude Code loads `CLAUDE.md` into context at the **start of every session, in full,
regardless of length**. Context is the scarce resource, and adherence *drops* as it
fills — so a bloated `CLAUDE.md` doesn't just cost tokens, it makes Claude follow
instructions **less** reliably. The whole game: a small, high-signal `CLAUDE.md`,
with everything heavier offloaded to mechanisms that load **only when relevant**.

Verified against the official docs; primary sources are listed at the bottom of each
reference file. Re-fetch if details seem stale.

## First: setup or audit?

- **New/immature project** → scaffold from scratch. Follow
  `references/new-project-setup-playbook.md` (step-by-step + copy-paste templates).
- **Existing `CLAUDE.md`, too long / getting ignored** → audit and slim. See the
  Audit workflow below.
- **Multiple packages** → read `references/monorepos.md` early; the monorepo-specific
  mechanics (especially *where you launch Claude*) change the whole approach.

## The non-negotiables (cheat-sheet)

Apply these whether setting up or auditing:

1. **Keep `CLAUDE.md` under ~200 lines.** For every line ask: *"would removing this
   cause Claude to make a mistake?"* If not, cut it.
2. **Include only always-true, whole-project facts:** build/test/typecheck commands,
   conventions that *differ from defaults*, project layout, repo etiquette, "always
   do X" rules, non-obvious gotchas. Exclude anything Claude can infer from code,
   standard conventions, frequently-changing info, long tutorials, file-by-file
   descriptions.
3. **Offload by how it should load** (full detail in
   `references/offloading-to-md-files.md`):
   - File-type/area-specific rules → `.claude/rules/*.md` with a `paths:` glob (loads
     only when Claude touches matching files).
   - Multi-step procedures / domain knowledge → **skills** (`.claude/skills/*/SKILL.md`).
   - Heavy reference docs → plain `docs/*.md` that `CLAUDE.md` **points to in prose**
     (loaded on demand).
   - Only use `@path` imports for a canonical file you accept loading every session.
4. **Do NOT use `@`-imports to "save context."** Imported files expand into context
   at launch — they're for organization/reuse, not token savings. This is the most
   common mistake; prefer prose pointers to `docs/*.md` for heavy content.
5. **Be concrete and structured.** "Run `npm test` before committing" beats "test your
   changes." Use headers + bullets. Add `IMPORTANT:`/`YOU MUST:` sparingly, only on
   genuinely critical rules.
6. **Give Claude a way to verify** (a test/build/lint/script) so it can close its own
   loop instead of relying on the user to catch errors.
7. **Deterministic must-happens are hooks, not memory.** If something must run every
   time (e.g. run the linter after edits, tests before commit), that's a hook —
   memory is only advisory. Making it a hook also lets you *delete* the corresponding
   `IMPORTANT: always run X` line from `CLAUDE.md`, freeing context. See the "Hooks"
   section in `references/offloading-to-md-files.md`.

## Setup workflow (condensed)

Full version with templates: `references/new-project-setup-playbook.md`.

1. Bootstrap with `/init`, or hand-author. Either way, **prune to essentials**.
2. Write a lean root `CLAUDE.md`: what it is, build/test commands, layout,
   conventions (differences from defaults), a "Docs (read on demand)" section with
   prose pointers, and — if useful — a "Start here each session" pointer to a living
   roadmap/status doc.
3. Move heavy content into `docs/*.md`, referenced in prose (not `@`-imported).
4. Add path-scoped `.claude/rules/*.md` (with `paths:` globs) for area/file-type
   reminders. Keep them terse and point them at the `docs/` file as the single source
   of truth so the two don't drift.
5. Put procedures/domain knowledge in skills, not inline.
6. Run `/memory` to confirm what actually loaded.

## Audit workflow (existing CLAUDE.md)

1. Run `/memory` to see every loaded file (root, nested, `.claude/rules/`).
2. Measure against the non-negotiables: length (<~200 lines?), any content Claude
   could infer from code, any long procedures/reference dumps that belong in
   skills/`docs`, any `@`-imports mistaken for context savings, vague or conflicting
   rules.
3. **Extract, don't delete indiscriminately:** move heavy docs to `docs/*.md` (prose
   pointer), area rules to `.claude/rules/*.md` (`paths:` glob), procedures to skills.
   Cut anything self-evident or inferable outright.
4. Resolve conflicts across root/nested/rules files (they cause arbitrary behavior).
5. Sharpen remaining rules into concrete, verifiable statements.
6. Re-check with `/memory`; confirm the root file is now lean.

## References (read on demand)

- **`references/claude-md-best-practices.md`** — what `CLAUDE.md` is, all file
  locations + load order, include/exclude table, sizing/structure/specificity,
  pitfalls, `/compact` behavior, debugging what loaded.
- **`references/offloading-to-md-files.md`** — the four offloading mechanisms
  (`@`-imports vs `.claude/rules/` vs skills vs prose-linked `docs/`), a decision
  matrix, and the `@`-imports-don't-save-context caveat. Read when deciding *where*
  content should go.
- **`references/new-project-setup-playbook.md`** — step-by-step recipe + copy-paste
  templates (lean CLAUDE.md, path-scoped rule, living roadmap) + checklist. Read when
  scaffolding a new project.
- **`references/monorepos.md`** — multi-package specifics: where you launch Claude
  decides what loads, per-package CLAUDE.md layering, the settings-not-inherited
  gotcha, cross-package access, per-package skills, read-reduction. Read when the repo
  has multiple packages. (The other three assume a single package.)
