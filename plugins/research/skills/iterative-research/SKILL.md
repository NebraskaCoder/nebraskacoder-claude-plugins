---
name: iterative-research
description: >-
  Disciplined iterative web research. Decomposes a question into sub-questions,
  searches the web in batches, reshapes the plan based on what each batch
  returns (adding, removing, pivoting), verifies load-bearing facts against
  primary sources, and synthesizes a context-aware answer with cited sources.
  Use this whenever the user wants to research a topic — a how-to ("how do I
  make a button accessible", "how do I rotate an OAuth token correctly"), the
  current state of something ("is X production-ready", "what's the state of Y
  in 2026"), a best-practice question, investigating why something behaves a
  certain way, evaluating an approach, or comparing options — or asks you to
  "look into", "dig into", "research", "investigate", or "search iteratively".
  Reach for it even when the user never says the word "research" but is
  plainly asking an evidence-backed question that one search won't settle.
---

# Iterative Research

A single web search gives you the first page of someone else's summary.
Real questions — "how do I do X correctly", "is Y production-ready",
"what's the current best practice for Z", or yes, "should I use A or B" —
have several moving parts, and the answer to one search reshapes what you
need to ask next. This skill is the loop that handles that properly: anchor
to the user's actual situation, break the question down, search until each
piece is genuinely answered, check the load-bearing facts against primary
sources, then give back an answer that's actually useful to *this* user.

## When to use this

Use it for any question where one search won't settle it. Common shapes:

- **How-to** with non-obvious correctness: "how do I make a button
  accessible", "how do I rotate a Kubernetes service-account token without
  downtime".
- **Current state / readiness**: "what's the state of WebAssembly outside
  the browser", "is HTTP/3 worth turning on yet".
- **Best practice**: "what's the recommended way to store secrets in
  GitHub Actions today".
- **Investigation**: "why does this library behave like X in case Y" when
  the answer lives in docs/issues/changelogs.
- **Comparison or decision**: "X vs Y for our use case".

Skip it for a single quick fact ("what port does Redis use" — just search
once) or anything answerable from the codebase or the conversation itself.

## The loop

### 1. Anchor to the user's context

A research answer is only useful if it's tied to the user's actual
situation. Before searching, note the constraints that will shape the
conclusion: their environment, stack, scale, existing tools, skills, stated
goals, hard requirements. Pull these from the conversation; ask if
something material is missing.

Generic advice often reads as plausible but doesn't actually help. "Use
ARIA labels" is much weaker than "the button is icon-only inside a `<form>`
that already has a visible heading, so `aria-label` on the button is the
right move and `aria-labelledby` would double-announce." The context is
what turns a textbook answer into the one the user can act on.

### 2. Draft an initial research plan — and treat it as mutable

Write an explicit list of the specific sub-questions that, once answered,
fully resolve the topic. This is the *starting* plan, not the final one.
It will be reshaped by what each batch of results reveals — that's the whole
point of the loop. "Search until everything is answered" is meaningless
without a written, evolving definition of "everything".

The shape of the initial plan depends on the question:

- **How-to**: what's the correct/standard pattern, what variants exist for
  the user's framework or stack, common mistakes and gotchas, what tooling
  verifies it.
- **Current state / readiness**: what status the project/standard is in
  (stable / beta / experimental), recent release activity, known
  production users, outstanding limitations.
- **Best practice**: what authoritative sources currently recommend, when
  that recommendation changed and why, what alternatives exist and when
  they're preferred.
- **Investigation**: what the docs say, what known issues/PRs exist around
  this behaviour, what the source actually does if it's open source.
- **Comparison**: what each option is, maturity and maintenance, the
  *decisive* differences (not every difference), fit with the user's
  setup, costs and risks of each, what the community currently picks.

These are starting points; expect the plan to look different after the
first batch.

Surface the initial plan to the user in a sentence or two so they can flag
anything you missed before you sink time into searching.

### 3. The search/reshape loop

This is the core of the skill. **The plan is a live queue you edit after
every batch — not a checklist you tick off.**

Each turn:

1. **Pick the top few open items from the plan and search them in parallel.**
   Independent sub-questions are independent searches — issue several
   WebSearch calls in a single turn so they run together. Write specific
   queries, not broad ones; include the current month/year when recency
   matters (versions, "best practice", "current recommendation"). Don't
   burn the whole plan in one batch — the next batch should be informed by
   what this one returns.

   If a batch comes back as mostly SEO listicles and shallow round-ups,
   reformulate before searching again: swap terminology, add
   `site:github.com` for issues and discussions, `site:<official-docs>`
   for primary sources, or `site:reddit.com` for practitioner takes. The
   top organic results are often the worst signal-to-noise; the answers
   that actually settle a question usually live in project docs, release
   notes, GitHub issues, and posts by people who shipped the thing.

2. **Read the results, then reshape the plan.** This is the step people
   skip. After every batch, do four things explicitly:

   - **Confirm**: which sub-questions are now genuinely answered?
     Strike them.
   - **Add**: what new sub-questions did the results surface? Almost
     every batch uncovers questions you didn't know to ask up front —
     an answer that ends "but only on platforms with X" surfaces "does
     the user's platform have X?". Add them. The plan often grows
     before it shrinks; that's the process working.
   - **Remove**: which queued sub-questions are now moot? An answer
     elsewhere may have settled a downstream question, or the direction
     of the research may have shifted enough that a planned search is no
     longer worth running. Cut them — don't search out of inertia.
   - **Pivot**: which half-answered sub-questions need a sharper
     follow-up? "Is this maintained?" → snippets said yes but vaguely →
     pivot to "last release date and changelog". And: when a
     sub-question is load-bearing and the snippets are thin, dated, or
     conflicting, queue a WebFetch of the primary source (official docs,
     spec, release notes, the project's own repo) — never rest a
     conclusion on a second-hand summary of a fact that decides the
     outcome.

   Two read-the-results habits that shape every reshape. When
   well-sourced answers contradict each other, the usual cause isn't
   that one is wrong — it's that they're talking about different cases.
   Find the boundary that explains both rather than picking a side ("it
   depends on X" is a real finding, not a cop-out, *if* you can name X).
   And on time-sensitive questions (current versions, current best
   practice, current behaviour), the more recent credible source
   usually wins as a tiebreaker — though check that the older one isn't
   being kept alive for a reason (a deprecation that got reversed, a
   regression in the newer version).

   Make this edit *visible* — write the updated plan in the response so the
   user can see what shifted. Naming the moves out loud also helps you
   actually make them rather than just running more searches by reflex.

3. **Repeat** until either every open item is answered, or new batches only
   re-confirm what you have (diminishing returns). State which of the two
   ended the loop. If something genuinely can't be pinned down, say so
   plainly — a known gap is more useful than a confident guess.

### 4. Synthesize — adapt the ending to the question

The shape of the answer should match the shape of the question:

- **How-to** → give the actual answer: the steps, the snippet, the
  attribute names, the gotchas the user would otherwise hit. Anchored to
  their stack from step 1, not a generic recipe.
- **Current state / readiness** → present where things stand, organized
  (stable vs experimental, who uses it in production, the open caveats).
  No forced verdict unless the user asked for one.
- **Best practice** → state what the current recommendation is, when it
  changed and why, and when the older approach is still acceptable.
- **Investigation** → the cause or mechanism, with the evidence trail.
- **Comparison / decision** → end with an explicit recommendation, framed
  as your take, tailored to the user's context. Give the reasoning, name
  the costs and risks of the option you picked, and say when the other
  choice would have been the right one. The user asked for a call — make
  it; hedging every sentence into "it depends" wastes the research.

Across all of these: cite sources inline as markdown links. Prefer
concrete specifics — version numbers, flag names, attribute names, code
snippets, command lines — over vague summaries; the specifics are what
make the answer actionable rather than just plausible-sounding. And
don't state as settled fact anything that rests on a single unverified
snippet.

## Output

Deliver the findings in the conversation, structured to skim. The right
structure depends on the question — a comparison table for "X vs Y", a
numbered procedure for a how-to, short labelled sections for state-of /
best-practice. Put the actionable conclusion where the user will see it
(the steps, the recommendation, the verdict), not buried under context.
Close with a `Sources:` list of the markdown links the answer actually
rests on — not every URL that appeared, the ones that matter.

Then **offer** to save a research doc — don't wait to be asked, and don't
force it either. Something like: "Want me to save this to
`docs/research/<topic>.md` so the reasoning isn't lost?" Write it only if
they say yes. Put it wherever fits the repo (`docs/research/` is a good
default; match existing conventions if the repo has them). For non-repo
contexts, suggest a sensible place or just ask where.

### Research doc template

When the user opts in, follow this shape (omit sections that don't apply
— e.g. the Recommendation section is only for decisions):

```markdown
# <Topic> — research

Research captured <date>.<If a decision was made: **Decision: <X>.**>
<One line on why this doc exists / what it feeds into.>

## Question

<What was being researched and why.>

## Findings

<The sub-questions and their answers, organized for the question type.
A table for comparisons, a procedure for how-to, sections for state-of.
The facts that drove the conclusion.>

## Recommendation
<Only for decisions. The call, the reasoning, the costs/risks of the
pick, and when the other option would win.>

## Sources

<Every source as a markdown link.>
```

## Quality bar — what to avoid

- **One search and stop.** The exact failure this skill exists to prevent.
  If you searched once and answered, you didn't use the skill.
- **A pile of facts with no synthesis.** The user asked a question;
  assemble the facts into an answer to it.
- **A generic answer.** If the answer would read the same for any user
  asking the same question, you skipped step 1.
- **Trusting a snippet on a decisive fact.** Verify it at the primary
  source.
- **Searching forever.** Past diminishing returns, stop and deliver.
- **Static checklist thinking.** If your plan at the end looks exactly
  like your plan at the start, you didn't really run the loop — the
  results should have reshaped it.
- **Hedging when asked for a take.** Commit, *then* caveat — not the
  reverse.
