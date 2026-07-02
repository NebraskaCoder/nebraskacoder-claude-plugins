# Writing a proper (lean) CLAUDE.md

Reference: <https://code.claude.com/docs/en/memory> and
<https://code.claude.com/docs/en/best-practices> (§ "Write an effective CLAUDE.md").

## What CLAUDE.md is

A markdown file of **persistent instructions** Claude Code reads at the start of
every session. Key properties to internalize:

- It's **loaded in full every session, regardless of length** — longer files cost
  more context and *reduce* adherence.
- It's delivered as a **user message after the system prompt** — it's *context, not
  enforced configuration*. Claude tries to follow it; there's no guarantee,
  especially for vague or conflicting instructions. For hard enforcement, use a
  [hook](https://code.claude.com/docs/en/hooks-guide) instead.
- The more **specific and concise** it is, the more reliably Claude follows it.

## Where the files live (and load order)

Files load from **broadest to most specific scope**, concatenated (not overridden),
so more-specific instructions appear later and effectively win. See
[Choose where to put CLAUDE.md files](https://code.claude.com/docs/en/memory#choose-where-to-put-claude-md-files)
and [How CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load).

| Scope | Location | Shared with |
|---|---|---|
| **Managed policy** (org-wide) | macOS `/Library/Application Support/ClaudeCode/CLAUDE.md`; Linux/WSL `/etc/claude-code/CLAUDE.md`; Windows `C:\Program Files\ClaudeCode\CLAUDE.md` | All users on machine (can't be excluded) |
| **User** | `~/.claude/CLAUDE.md` | Just you, all projects |
| **Project** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team, via source control |
| **Local** | `./CLAUDE.local.md` | Just you, this project (gitignore it) |

Loading mechanics:

- Claude **walks up** the directory tree from the working directory; every ancestor
  `CLAUDE.md`/`CLAUDE.local.md` loads at launch, ordered root → cwd. Within a
  directory, `CLAUDE.local.md` is appended after `CLAUDE.md`.
- `CLAUDE.md` files in **subdirectories below** the cwd load **on demand** — only
  when Claude reads a file in that subdirectory.
- After **`/compact`**, the **project-root `CLAUDE.md` is re-injected**; nested
  subdirectory files are not re-injected until Claude next reads a file there.
- **Block-level HTML comments** (`<!-- ... -->`) are stripped before injection — use
  them for maintainer notes without spending context. (Preserved inside code blocks
  and when you open the file with the Read tool.)

Bootstrap with **`/init`** (analyzes the codebase and generates a starter
`CLAUDE.md`; on an existing file it suggests improvements instead of overwriting).
Use **`/memory`** to see exactly which memory files are loaded this session and open
them for editing.

## What to include vs. exclude

From [best practices](https://code.claude.com/docs/en/best-practices):

| ✅ Include (Claude can't infer it) | ❌ Exclude |
|---|---|
| Bash/build/test commands Claude can't guess | Anything Claude can figure out by reading code |
| Code-style rules that **differ from defaults** | Standard language conventions Claude already knows |
| Testing instructions / preferred test runner | Detailed API docs (link to them instead) |
| Repo etiquette (branch naming, PR/commit conventions) | Information that changes frequently |
| Architectural decisions specific to the project | Long explanations or tutorials |
| Dev-environment quirks (required env vars, SDK versions) | File-by-file descriptions of the codebase |
| Common gotchas / non-obvious behaviors | Self-evident practices ("write clean code", "test your code") |

The test for every line: **"Would removing this cause Claude to make a mistake?"**
If not, cut it. Bloated files cause Claude to ignore your *actual* instructions.

## Sizing, structure, specificity

- **Size:** target **under 200 lines**. If it's growing, offload (see
  [offloading-to-md-files.md](./offloading-to-md-files.md)).
- **Structure:** use markdown headers and bullets to group related instructions.
  Claude scans structure like a reader does.
- **Specificity:** write instructions concrete enough to verify.
  - "Use 2-space indentation" > "format code properly"
  - "Run `npm test` before committing" > "test your changes"
  - "API handlers live in `src/api/handlers/`" > "keep files organized"
- **Emphasis:** add `IMPORTANT:` or `YOU MUST:` **sparingly** to boost adherence on
  the few genuinely critical rules. Overuse dilutes it.
- **Consistency:** contradictory rules make Claude pick arbitrarily. Periodically
  review the root file, nested files, and `.claude/rules/` to remove stale/conflicting
  guidance.

### Minimal shape (generic)

```markdown
# <project name>

One or two lines on what this is and any overarching working style.

## Build & test
- `<cmd>` — build
- `<cmd>` — run tests
- `<cmd>` — typecheck/lint
- Always run `<check>` before committing.

## Layout
- `src/<area>/` — <what lives here>
- ...

## Conventions
- <style rule that differs from defaults>
- <security/architecture "always do X" rule>

## Docs (read on demand)
- <topic> → `docs/<file>.md`
```

## Common pitfalls

- **Over-specified file** → Claude ignores half of it; important rules get lost.
  *Fix:* prune ruthlessly; convert must-happen rules to a
  [hook](https://code.claude.com/docs/en/hooks-guide).
- **Vague instructions** → ignored. *Fix:* make them concrete and checkable.
- **Conflicting instructions** across nested files / rules → arbitrary behavior.
  *Fix:* audit with `/memory`; in monorepos use
  [`claudeMdExcludes`](https://code.claude.com/docs/en/memory#exclude-specific-claude-md-files).
- **Assuming imports save context** — they don't (see the offloading doc).
- **Instruction "lost" after `/compact`** — it was conversation-only or in a nested
  file that hasn't reloaded. Put durable rules in the root `CLAUDE.md`.

## Debugging what loaded

- `/memory` lists all loaded `CLAUDE.md`, `CLAUDE.local.md`, and rules files.
- The
  [`InstructionsLoaded` hook](https://code.claude.com/docs/en/hooks#instructionsloaded)
  can log exactly which instruction files loaded, when, and why — useful for
  path-scoped rules and lazy subdirectory files.

## Related mechanisms (not CLAUDE.md, but adjacent)

- **AGENTS.md interop:** Claude reads `CLAUDE.md`, not `AGENTS.md`. If a repo uses
  `AGENTS.md`, create a `CLAUDE.md` that does `@AGENTS.md` (or symlink) so both tools
  share one source.
- **Auto memory:** Claude also keeps its *own* notes in
  `~/.claude/projects/<project>/memory/`; only `MEMORY.md` (first 200 lines / 25KB)
  loads at startup, topic files load on demand. This is Claude-written; `CLAUDE.md`
  is human-written. See [Auto memory](https://code.claude.com/docs/en/memory#auto-memory).
