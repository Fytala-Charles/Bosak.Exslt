<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 11 — capstone: ship a function">
  <br><br>
  <h1>Session 11 — Capstone: Ship a Function</h1>
  <p>The full contribution workflow in miniature — golden case first, then implementation</p>
</div>

> **Time:** ~60–90 minutes · **Prerequisites:** every prior session — the
> capstone uses the recursion of session 03, the headers of the whole
> library, the tier model of session 10, and the honesty habits of
> sessions 08–09; [session 00](../00-setup/README.md) for tooling
> **Vehicle:** a *proposed* new function, `str:repeat` (tier 2) — or your own choice (section 2)

---

## 1. The one-way bridge

Sessions 01–10 stayed inside the sandbox by rule: training stylesheets are
self-contained and never include `src/`, so the library artifact can never
break because a lesson did. This session crosses the bridge — in
**rehearsal**. You will execute every step of the real contribution
workflow on `str:repeat`, a plausible new EXSLT function, producing real
artifacts in this session directory. The rehearsal is full-fidelity: the
file shapes, the metadata shape, the gate order, and the documentation
sync are exactly the real ones. Only the locations differ, and the mapping
is one table:

| Rehearsal artifact (this session) | Real contribution location |
|-----------------------------------|----------------------------|
| §2 proposal + Appendix A mini-REQ | `docs/FEATURE_REQUESTS.md` — registry row + detail section |
| `case/meta.json` + `case/expected.xml` + `input.xml` | `tests/cases/strings/repeat.1/` — golden case **first**, same layout |
| `solution/transform.xsl` (header + function) | `src/strings.xsl` — the module file, house header appended to |
| Appendix B mini-matrix row | `docs/COMPATIBILITY.md` — the authoritative per-function matrix |
| Appendix C mini-attribution entry | `tests/ATTRIBUTION.md` — fixture provenance + divergence log |
| `dotnet test ../TrainingTests` (2 tests/session) | `dotnet test tests/Bosak.Exslt.Tests` **and** `pwsh tools/check-docs.ps1` |
| §6 doc-sync walk-through | `AGENTS.md` §7 checklist — run after **every** successful step, no exceptions |

Work the steps in order. Each step says what the real workflow does at the
real location, so that when you contribute for true, nothing is new.

## 2. Step 1 — Propose: `str:repeat`

Every deterministic EXSLT function is already implemented in `src/`, so a
real proposal adds something new. Here it is:

> **`str:repeat($input, $count)`** — repeat `$input` `$count` times and
> return the concatenation. Tier 2 (genuine implementation in pure XSLT
> 3.0; one tail-recursive worker, session 03's pattern). Contract: `$count`
> is a lexical integer; absent, non-integer, or negative `$count`, or empty
> `$input`, yields `''` — invalid input is data, per the EXSLT convention
> for string functions. No upstream spec or libxslt reference exists, so
> the contract is the proposal's own (recorded honestly in the case's
> `meta.json`).

In the real workflow this paragraph becomes a REQ entry: the registry row
(ID, summary, motivation, status, target version) plus a detail section
with Problem Statement / Proposed Solution / Acceptance Criteria — the
shape of every REQ in `docs/FEATURE_REQUESTS.md`. **Appendix A** is this
proposal filled in, in that exact shape.

> **Learner's choice:** the curriculum row says "learner's choice", and it
> means it. Any tier-1 or tier-2 function you can state a contract for
> works as the vehicle — swap yours in at every step (the steps don't
> change). Pick one small enough to finish: two parameters, one recursion.

## 3. Step 2 — Golden case FIRST

The house rule is test-first with golden files: **write the case before
the implementation** (`AGENTS.md` §5 — one golden case minimum per
function, happy path *and* one edge case). In rehearsal that is this
session's `case/`:

1. `case/meta.json` — the **exact** `tests/cases/` shape (function,
   namespace URI, tier, `source` — hand-written cases use
   `{"project": "hand-written", "license": "Apache-2.0"}` — plus
   `adaptations` and `notes`; see `docs/XSLT_STYLE_GUIDE.md` §2). Read the
   committed `case/meta.json` here and compare it against
   `tests/cases/strings/padding.1/meta.json`: same fields, same nesting.
2. `input.xml` — the request rows. This session's set covers the contract's
   corners: multi-char happy path (`ab` × 3), count 0, count 1, a longer
   run (`-` × 10), an input containing a space, empty input, a
   non-integer count, and a negative count.
3. `case/expected.xml` — predict it from the contract *before* looking at
   any implementation, then let the GREEN run verify: the harness compares
   your solution's output against this file. (Sessions 08–10 used the same
   golden-TDD shortcut; the prediction is the exercise, the engine is the
   referee.)

In the real workflow the case lives at `tests/cases/strings/repeat.1/`
with a `transform.xsl` that `xsl:include`s `../../../src/strings.xsl` —
the include path is part of the fixture rules. Here the transform is the
session stylesheet itself (self-contained rule still applies in training).

## 4. Steps 3–4 — Implement, with the house header

Open `starter/transform.xsl`. The function is a **slot** — the tier-3
shape from session 10: a loud `xsl:message` instead of a fake answer, and
a CHANGE HISTORY table waiting for you. Replace the slot with the genuine
tier-2 implementation and fill in the header:

- **House header** (`docs/XSLT_STYLE_GUIDE.md` §1.1): the XML comment
  before `xsl:stylesheet` with `AUTHOR`, `CREATE DATE`, `PURPOSE`,
  `SPECIAL NOTES`, `COPYRIGHT (Fytala)`, `LICENSE (Apache-2.0)` — the
  canonical shape is the header of `src/strings.xsl`. New work carries a
  `CHANGE HISTORY` block with a `1.0.0` creation row (the shape used by
  `src/dates-and-times.xsl`); modifications append a row with the current
  date and a bumped version.
- **Function doc block** (§1.2): purpose, parameters and return, edge
  posture, tier. The solution's comments are the reference.
- **Language rules** (§1.3): standard XSLT 3.0 / XPath 3.1 + F&O only —
  no vendor extensions, no processor conditionals; a kebab-case private
  helper with a leading underscore (`str:_repeat`); two-space indent.

Two engine observations from building this session, both worth keeping:

- The slot's fallback must satisfy the declared return type: with
  `as="xs:string"`, a `()` fallback fails with `XTTE0780` *before* the
  message can matter — `''` is the type-correct slot tail. (In
  `src/dynamic.xsl` the slot may return `()` because it declares
  `item()*`.)
- On Bosak 0.12.3-beta the `terminate="yes"` message is emitted but does
  **not** abort the transformation — the template completes with empty
  results (a candidate core gap, in the style guide's category). That is
  why the starter runs-and-differs instead of crashing the harness; on a
  conformant engine the same file stops dead. Either way it never produces
  golden output, which is all the harness checks. Session 10's lesson
  applies to your own claims too: verify, then write down what you saw.

## 5. Steps 5–6 — Matrix row and attribution entry

The `docs/COMPATIBILITY.md` matrix is the **authoritative** registry of
what the library does (§4 of `AGENTS.md`): every function has exactly one
row — Function, Tier, Status, Notes, Tests — with a test pointer once a
golden exists. **Appendix B** is the `str:repeat` row in that exact column
shape, tier 2 / implemented, pointing at the case. A proposed function
with no golden yet would read `documented`, not `implemented` — the
matrix says what *is*, not what is planned.

`tests/ATTRIBUTION.md` records fixture provenance: imported corpora with
their license notices, hand-written cases marked `hand-written`, and the
divergence log. `str:repeat` is hand-written with **no** upstream
reference, so it gets a one-line provenance entry and — because there is
no reference behavior to diverge *from* — no divergence note.
**Appendix C** is that entry. Never fabricate attribution; when you do
re-golden against a deliberate divergence, record it in the case's
`meta.json`, the attribution file, and the matrix **in the same step**
(§2 of the style guide).

## 6. Steps 7–8 — Gates, then documentation sync

The gates, in the real workflow and here:

```bash
dotnet test ../TrainingTests/TrainingTests.csproj      # rehearsal harness (real: tests/Bosak.Exslt.Tests + check-docs)
```

Then the doc-sync checklist (`AGENTS.md` §7) — in the real workflow it
runs after every successful step; the rehearsal maps it like this:

| Checklist item (real) | Rehearsal counterpart |
|-----------------------|-----------------------|
| `README.md` current | the proposal text (§2) says what shipped |
| `ROADMAP.md` stages/milestones | Appendix A's target version |
| `docs/ARCHITECTURE.md` layout | nothing new in rehearsal (no new module) |
| `docs/COMPATIBILITY.md` matrix | Appendix B row |
| `docs/FEATURE_REQUESTS.md` registry | Appendix A entry; status `Implemented` |
| `tests/ATTRIBUTION.md` | Appendix C entry |
| `docs/AGENT_HANDOVER.md` | n/a here — the owner's log, never edited by training |
| `pwsh tools/check-docs.ps1` ALL CHECKS PASSED | the real gate set |

And the step that never appears in a diff: **git discipline** (`AGENTS.md`
§8). Agents never `git init`, commit, push, or create remotes unless the
owner explicitly asks; a contribution is files plus a request, and the
owner commits. When *you* contribute for real, the same rule protects you:
never commit unless asked.

## 7. What makes a contribution acceptable

The governing contract, collected from `AGENTS.md` §3–§8 and
`docs/XSLT_STYLE_GUIDE.md`:

1. **Standard XSLT 3.0 only** (§3, §1.3) — no vendor extensions, no
   processor conditionals; engine workarounds must be standards-compliant
   and noted.
2. **The three-tier model is the spine** (§4) — tier 1 thin wrappers naming
   the native equivalent; tier 2 genuine implementations; tier 3 loud
   slots. Never ship a fake implementation.
3. **Golden-first TDD** (§5) — case before code, happy path plus edge,
   fixtures in the exact layout, provenance recorded, divergences logged
   in the same step.
4. **The matrix is authoritative** (§4, §7) — `docs/COMPATIBILITY.md` says
   what the code does; keep them in lock-step.
5. **File headers everywhere** (§3, style guide §1.1) — the six markers on
   every `.xsl`, change-history rows on modification.
6. **Doc sync is mandatory** (§7) — the checklist after every step, no
   exceptions.
7. **Git discipline** (§8) — commits happen only on owner request.

## 8. Checking your work — and shipping for real

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

- `Starter_differs_from_golden` **passes** — the slot must never produce
  golden output. (If you edited the starter in place and it now fails,
  that means success — restore the stub for the next learner.)
- `Solution_matches_golden` is your gate: when your completed workflow
  matches `case/expected.xml`, you have shipped — in miniature, end to
  end.

**Go further — for real this time.** The training ends here; the library
is the destination. Real gaps waiting for a first contribution:
`docs/FEATURE_REQUESTS.md` REQ-001 (import the remaining deterministic
libxslt corpus) and the hand-written edge-case goldens listed in
`ROADMAP.md` Stage 1 (`set:trailing`, `str:decode-uri`, `date:seconds`,
`date:sum`, and friends). Pick one, and run this session's runbook at the
real locations. The path taught you the walk; the walk is yours now.

---

## Appendix A — mini-REQ (real location: `docs/FEATURE_REQUESTS.md`)

| ID | Requesting Party | Summary | Motivation | Status | Target Version | Submitted |
|----|------------------|---------|------------|--------|----------------|-----------|
| `REQ-TRAINING-11` | `Fytala` (capstone rehearsal) | Propose `str:repeat($input, $count)` for the EXSLT strings module: repeat a string N times, tier 2 | Plausible gap in the strings module; exercises the full contribution workflow | Implemented | Pre-v0.1.0 | 2026-10-06 |

**Acceptance criteria (filled):** golden case with happy path + edges,
written before the implementation ✓ · house header with CHANGE HISTORY ✓
· matrix row with test pointer ✓ · attribution entry ✓ · harness green ✓.

## Appendix B — mini-matrix row (real location: `docs/COMPATIBILITY.md`)

| Function | Tier | Status | Notes | Tests |
|----------|------|--------|-------|-------|
| `str:repeat` | 2 | implemented | Repeat `$input` `$count` times; `''` for absent/non-integer/negative `$count` or empty `$input`. Proposed function — no upstream reference; contract recorded in the case's `meta.json`. | `cases/strings/repeat.1` (rehearsal: this session's `case/`) |

## Appendix C — mini-attribution entry (real location: `tests/ATTRIBUTION.md`)

| Case | Upstream | Adaptations |
|------|----------|-------------|
| `strings/repeat.1` | hand-written (Apache-2.0) | Proposed function `str:repeat`; no upstream spec or libxslt reference exists, so the golden pins the proposal's own contract. No divergence entry applies. (Rehearsal: training session 11's `case/`.) |

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
