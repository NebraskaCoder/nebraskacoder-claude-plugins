# New-project setup playbook

A repeatable recipe for setting up Claude Code memory on a fresh project so it starts
lean and stays that way. Copy-paste templates are generic — replace the placeholders.

Backing references:
[memory](https://code.claude.com/docs/en/memory),
[best practices](https://code.claude.com/docs/en/best-practices),
[large codebases](https://code.claude.com/docs/en/large-codebases).

## Target layout

```
your-project/
├── CLAUDE.md                     # lean; always-loaded; points to docs/
├── docs/
│   ├── conventions.md            # full coding conventions (read on demand)
│   ├── roadmap.md                # living status/plan (update each session)
│   └── <topic>.md                # heavy references, one per topic
└── .claude/
    └── rules/
        ├── <area>.md             # path-scoped reminders (auto-load on match)
        └── ...
```

Principle: `CLAUDE.md` holds only what must be true *every* session; everything heavy
lives in `docs/` (prose-linked) or `.claude/rules/` (glob-scoped). See
[offloading-to-md-files.md](./offloading-to-md-files.md).

## Steps

### 1. Bootstrap

Run `/init` to generate a starter `CLAUDE.md` from the codebase, then refine — or
hand-author using the template below. Either way, **prune to the essentials**.

### 2. Author a lean `CLAUDE.md`

```markdown
# <project name>

<1–2 lines: what this is; overarching working style, e.g. "small incremental changes">

## Build & test
- `<cmd>` — build
- `<cmd>` — test
- `<cmd>` — typecheck / lint
- After changes: run `<check>`; it must pass.   <!-- concrete, verifiable -->

## Layout
- `<dir>/` — <what lives here>
- `<dir>/` — <what lives here>

## Conventions
- <style rule that DIFFERS from defaults>
- <security/architecture "always do X" rule>
- Full conventions → `docs/conventions.md`   <!-- prose pointer, not @import -->

## Start here each session
Read `docs/roadmap.md`; its "Start here" section names the next task. Keep it current.

## Docs (read on demand)
- Coding conventions → `docs/conventions.md`
- Roadmap & status → `docs/roadmap.md`
- <topic> → `docs/<topic>.md`
```

Keep it **under ~200 lines**. For each line: *would removing it cause a mistake?*

### 3. Move heavy content into `docs/`

Anything long — full conventions, architecture, runbooks, automation notes — goes in
`docs/*.md` and is **referenced from `CLAUDE.md` in prose** (not `@`-imported), so it
loads only when a task needs it.

### 4. Add path-scoped rules for area/file-type reminders

Create `.claude/rules/<area>.md` with a `paths:` glob so terse reminders auto-load
when Claude edits matching files:

```markdown
---
paths:
  - "<glob e.g. src/**/*.tsx>"
---

# <area> reminders
- <short, imperative rule>
- <short, imperative rule>

Full reference: `docs/conventions.md` (source of truth — this rule is a summary).
```

Keep rules terse and make the `docs/` file the **single source of truth** so the two
never drift meaningfully. Omit `paths:` only if the rule genuinely applies to *every*
file (it then loads every session).

### 5. (Optional) A "living" roadmap doc

A `docs/roadmap.md` that each session updates is a cheap way to carry intent across
sessions and hand work between them:

```markdown
# Roadmap & status

> Living document. At the end of each session, update: move shipped items to Done,
> note decisions, adjust next steps.

## ▶ Start here (next session)
**Task: <name>.** <goal, brief spec, suggested approach, how to verify>

## Done
- [x] ...

## Next (one at a time)
- [ ] ...

## Later (backlog)
- [ ] ...

## Notes / decisions
- ...
```

Point to it from `CLAUDE.md`'s "Start here each session" section so a fresh session
knows where to begin.

### 6. Give Claude a way to verify

Per [best practices](https://code.claude.com/docs/en/best-practices), record a
concrete check (tests, build, a screenshot compare, a script) in `CLAUDE.md` so
Claude can close its own loop instead of relying on you to spot errors.

### 7. Verify the setup loaded

Run `/memory` to confirm which files are loaded. Optionally enable the
[`InstructionsLoaded` hook](https://code.claude.com/docs/en/hooks#instructionsloaded)
to log path-scoped-rule loading while you tune globs.

## Maintenance discipline

- Treat `CLAUDE.md` **like code**: review it when Claude misbehaves, prune regularly,
  and confirm edits actually change behavior.
- If Claude repeatedly violates a rule, the file is probably **too long** — trim, or
  convert must-happen rules into a [hook](https://code.claude.com/docs/en/hooks-guide).
- Audit for **conflicts** across root `CLAUDE.md`, nested files, and `.claude/rules/`.
- In monorepos, exclude irrelevant ancestor files with
  [`claudeMdExcludes`](https://code.claude.com/docs/en/memory#exclude-specific-claude-md-files).

## Quick checklist

- [ ] `CLAUDE.md` under ~200 lines, only always-true facts
- [ ] Build/test/typecheck commands present and concrete
- [ ] A verifiable check Claude can run
- [ ] Heavy content in `docs/*.md`, referenced in prose (not `@`-imported)
- [ ] Area rules in `.claude/rules/*.md` with `paths:` globs, pointing at `docs/` as
      source of truth
- [ ] Procedures/domain knowledge as **skills**, not inline
- [ ] `/memory` confirms everything loads as intended
