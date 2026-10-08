<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala XPath foundations training track">
  <br><br>
  <h1>XPath Foundations — Training Track</h1>
  <p>The expression language inside XSLT, XQuery, and the Bosak engine — learned test-first, one concept at a time</p>
</div>

---

## Why a separate XPath track?

Every XSLT instruction that does real work carries an XPath expression inside
it: `select="…"`, `match="…"`, `test="…"`. Weak XPath makes XSLT feel like
moving furniture in the dark; solid XPath makes it feel like asking precise
questions. So before (or alongside) the XSLT curriculum, this track builds
that foundation — and because XPath is also the expression language of XQuery
and the Bosak engine generally, it lives as its own reusable track rather
than being folded into the XSLT sessions.

The [XSLT curriculum](../README.md) references this track: each XSLT session
lists the XPath sessions it assumes.

## How a session works

Same RED→GREEN method as the XSLT curriculum, but the artifact under test is
a **raw XPath expression** instead of a stylesheet:

```
training/xpath/NN-slug/
  README.md                 the lesson: concept, runnable examples, exercise, hints
  input.xml                 source document the expression runs against
  case/
    meta.json               provenance metadata
    expected.txt            the golden result — token-for-token
  starter/exercise.xpath    the expression to complete — test is RED
  solution/exercise.xpath   the reference answer — test is GREEN
```

An expression file is plain text containing exactly one XPath 3.1 expression.
Run it live in VS Code with **Bosak: Evaluate XPath Expression** (see
[session 00 of the XSLT curriculum](../00-setup/README.md) for tooling
setup); the *graded* loop is:

```bash
dotnet test training/xpath/XPathTrainingTests/XPathTrainingTests.csproj
```

Two tests per session, mirroring the XSLT harness: `Solution_matches_golden` (the
reference expression yields the golden result) and `Starter_differs_from_golden` (the
exercise is still unsolved — the build fails if a starter accidentally
matches the golden).

**How results are rendered for comparison:** the harness prints atomic values
as themselves (`42`, `Emma`, `true`), and sequences item-by-item joined with
` | `. The empty sequence prints as `()`. Whitespace differences never
matter — comparison is on the token stream — but item order always does.

## Sessions

| # | Session | Concepts | Status |
|---|---------|----------|--------|
| 1 | [Values & paths](01-values-and-paths/README.md) | The tree model, sequences, `/`, `//`, `.`, child steps, attributes | Available |
| 2 | [Predicates & sequences](02-predicates-and-sequences/README.md) | `[...]` filters, positional predicates, `count`/`exists`/`empty`, union and concatenation | Available |
| 3 | [Functions & operators](03-functions-and-operators/README.md) | The `fn:*` library, arithmetic and comparisons, `!` simple map, `if`/`then`/`else` | Available |
| 4 | [FLWOR expressions](04-flwor-expressions/README.md) | `for`/`let`/`where`/`order by`/`return`, variable bindings | Available |
| 5 | [Putting it together](05-putting-it-together/README.md) | Multi-step expressions over richer documents; bridge to XSLT session 02 | Available |

All five sessions are Available. When you finish here, continue with the
[XSLT curriculum](../README.md) — its session 02 assumes this track's sessions 1
and 2, and later sessions lean on the rest.

## Pacing

30–45 minutes per session, self-paced, in order — each session's expressions
use the previous session's concepts.

## Authoring a new session

Same contract as the XSLT curriculum (see `training/README.md` §Authoring):
a numbered directory with a branded `README.md`; discovered by
`case/meta.json`; `starter/exercise.xpath` must compile and evaluate but not
match the golden. Expressions must be **pure XPath 3.1** — no XSLT
instructions, no extension functions.

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
