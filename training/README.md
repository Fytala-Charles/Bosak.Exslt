<div align="center">
  <img src="../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala Bosak.Exslt training curriculum">
  <br><br>
  <h1>Learning XSLT with EXSLT — Training Curriculum</h1>
  <p>Eleven self-paced sessions that teach XSLT 3.0 by re-creating the EXSLT library, one function at a time — plus a companion XPath foundations track</p>
</div>

---

## What this is

The **Bosak.Exslt** repository holds two things at once:

1. **The library** (`src/`) — a pure-XSLT 3.0 implementation of EXSLT, ready to
   `xsl:import` into your own stylesheets. It is the finished artifact.
2. **This training** (`training/`) — the journey through which that library was
   built. Each session takes one EXSLT function and teaches the XSLT techniques
   needed to implement it, from your first template to recursive scanning,
   node identity, and duration arithmetic.

The library is the destination. The training is the path.

## How a session works

Every session is a small **test-driven (TDD) exercise**:

1. **RED** — the `starter/transform.xsl` compiles and runs, but its output does
   not match the golden file. The failing test shows you exactly what to build.
2. **Implement** — you write the missing XSLT, guided by the lesson in the
   session's `README.md`. Progressive hints are there when you get stuck;
   `solution/transform.xsl` is the reference answer.
3. **GREEN** — once your starter produces the golden output, the test passes
   and the technique is yours.

A session directory always looks like this:

```
training/NN-slug/
  README.md            the lesson: concept, walkthrough, exercise, hints
  input.xml            source document the transform runs against
  case/
    meta.json          provenance metadata (same shape as the golden corpus)
    expected.xml       the golden output — the contract your code must satisfy
                       (expected.txt for text output)
  starter/transform.xsl   incomplete — the test is RED; this is what you edit
  solution/transform.xsl  the completed exercise — compare after your attempt
```

## Setup

**New here? Start with [Session 00 — Setup & Tooling](00-setup/README.md).** It
walks through installing the .NET 10 SDK, VS Code, and the Bosak XPath / XSLT
extension, verifies everything with a configuration check
(`training/00-setup/check-setup.ps1 -RunTests`), and gives a 10-minute tour of
working in VS Code.

In short, you need:

- The .NET 10 SDK (`dotnet --version` should print 10.x).
- VS Code with the **Bosak XPath / XSLT** extension (`fytala.vscode-bosak`)
  for editing and running transforms.

Run the training tests from the repository root:

```bash
dotnet test training/TrainingTests/TrainingTests.csproj
```

Each session produces two tests: `Solution_matches_golden` (the reference answer
matches the golden output) and `Starter_differs_from_golden` (the exercise is still
unsolved). Your job is to turn the red one green — in your own copy of the
starter, or directly in `starter/transform.xsl` if you are not preserving your
work between sessions.

## The golden rule: training never touches the library

`training/` is a sandbox. Session stylesheets must be **self-contained**:
they never `xsl:include` or `xsl:import` anything from `src/`. The library
files appear only as *reading material* — the lesson will point you at the
finished implementation (e.g. `src/math.xsl`) **after** your own attempt, so
you can compare approaches. The golden corpus in `tests/` is equally
untouchable. The single exception is the capstone session (10), which teaches
the contribution workflow: there you deliberately copy your finished work into
the library, with headers, attribution, and documentation updates.

## Curriculum

| # | Session | XSLT techniques | Vehicle functions | Status |
|---|---------|-----------------|-------------------|--------|
| 0 | [Setup & tooling](00-setup/README.md) | — this session installs the toolchain | configuration check (`check-setup.ps1`) instead of an exercise | Available |
| 1 | [XSLT basics](01-xslt-basics/README.md) | The processing model, template rules, literal result elements, `xsl:value-of` / `xsl:for-each`, attribute value templates | — (transform `<team>` into a roster document) | Available |
| 2 | [Your first stylesheet](02-first-stylesheet/README.md) | Stylesheet anatomy, `xsl:function`, sequences, the `!` operator, empty-input handling | `math:min`, `math:max`, `math:highest` | Available |
| 3 | [Recursion as the basic loop](03-recursion/README.md) | Recursive `xsl:function`, default parameters, `substring` arithmetic | `str:padding`, `str:align` | Available |
| 4 | [Regular expressions](04-regular-expressions/README.md) | `fn:tokenize`, escaping literal delimiters, `analyze-string` vs `tokenize` | `str:tokenize`, `str:split`, `str:encode-uri` | Available |
| 5 | Stateful scanning | Left-to-right scans, recursion with an accumulator, positional mapping | `str:replace` | Planned |
| 6 | Nodes, identity, grouping | `is` vs `=`, document order, `except`/`intersect`, `xsl:for-each-group` | `set:has-same-node`, `set:distinct`, `set:difference` | Planned |
| 7 | Result trees and types | What variables hold in XSLT 3.0, document nodes, `instance of` | `exsl:node-set`, `exsl:object-type` | Planned |
| 8 | Dates I — parsing & formatting | `xs:date`/`xs:dateTime`, `format-date` picture strings, invalid input | `date:year`, `date:leap-year`, `date:month-name` | Planned |
| 9 | Dates II — duration arithmetic | `xs:duration` component arithmetic, carry/normalization, decimal precision | `date:duration`, `date:add-duration`, `date:sum` | Planned |
| 10 | The limits of pure XSLT | Function items, `fold-left`/`map`/`filter`, why `dyn:evaluate` cannot exist here | `dyn:evaluate` (tier 3), `func:*` | Planned |
| 11 | Capstone: ship a function | Full contribution workflow — golden case first, then implementation | learner's choice | Planned |

Difficulty rises session by session, and each session's technique is genuinely
needed by the next one's function — this is a dependency graph, not just a
reading order.

**Prerequisites:** sessions 1+ assume you can read XPath expressions
(paths, predicates, function calls — every `select` attribute is XPath). If
that is new to you, work through the
[XPath foundations track](xpath/README.md) first: it uses the same
RED→GREEN method on raw `.xpath` expression files, and XSLT sessions 1–3
build on its sessions 1–2.

## Pacing

Each session takes **30–60 minutes**. Work at your own pace, in any order you
like — but if you skip ahead and a technique feels unexplained, the
"Prerequisites" line at the top of each session README tells you where it was
taught. No session assumes a trainer is present.

## Authoring a new session

Sessions are numbered directories `NN-slug/` with a branded `README.md`
(banner with meaningful `alt` text, `© Fytala` footer). A session is any
directory whose `case/meta.json` exists: the harness in
`training/TrainingTests/` discovers it automatically and requires
`starter/transform.xsl`, `solution/transform.xsl`, and
`case/expected.xml` (or `case/expected.txt`). The starter must compile and run but
produce non-golden output — the harness fails the build if a starter is
accidentally already green. Session stylesheets stay self-contained: standard
XSLT 3.0 only, no includes of `src/`. A numbered directory *without*
`case/meta.json` — like `00-setup` — is a non-exercise session (setup guide,
reference material); it needs the branded README but no starter/solution/case.

---

## About FYTALA

**FYTALA — Feeling Young, Thriving, Active, Learning Always** — is a personal initiative founded after retirement, driven by the belief that curiosity, enthusiasm, and learning have no age limit.

It is about staying engaged, exploring new ideas, and sharing the excitement of technology and innovation with others. A special ambition of FYTALA is to spark that enthusiasm in young people and encourage them to discover how fascinating technology can be—not just by talking about technology, but by making it visible, tangible, surprising, and fun.

My dream captures that ambition perfectly: **to walk into a classroom one day, side by side with a humanoid robot, and make my enthusiasm for technology and innovation contagious.**

If that experience inspires even a few young minds to start asking questions, experimenting, building, programming, or imagining what might be possible, FYTALA has achieved something worthwhile.

Technology, after all, is not just about machines, electronics, or software. It is about curiosity, creativity, and turning ideas into reality. FYTALA therefore takes a deliberately broad perspective, embracing software, electronics, engineering, science, artificial intelligence, robotics, and whatever comes next.

> Experimenting matters.
>
> Making mistakes matters.
>
> Understanding *why* something works matters even more.

Every project is an opportunity to learn something new and, hopefully, to help someone else learn as well.

The cable-stayed bridge in the FYTALA logo represents that philosophy. A bridge connects places, but it can also connect people, ideas, generations, and fields of knowledge. Its strength comes from many individual elements working together—much like technology itself.

FYTALA wants to help build those bridges: between experience and youthful curiosity, theory and practice, and imagination and real-world creation. It encourages looking beyond the obvious, asking questions, taking things apart, and building them again in new ways.

Above all, FYTALA is about keeping the desire to discover alive—and passing that desire on to the next generation.

> Because we never have to stop being curious.
>
> We never have to stop creating.
>
> And we are never too old—or too young—to learn something new.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
