<div align="center">
  <img src="../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala Bosak.Exslt feature requests">
  <br><br>
  <h1>Bosak.Exslt Feature Requests</h1>
  <p>Living registry of feature requests and backlog items</p>
</div>

> **Living Registry** — Last updated: 2026-10-06 (**skeleton complete: 7 library modules (6 namespace modules + master) on the three-tier model, golden-file harness green (22/22 cases: 15 libxslt-derived + 7 hand-written REQ-008 date cases) against Bosak.Xslt 0.12.3-beta; Fytala Docs Kit branding adopted; repository bootstrapped 2026-10-06 and live at `Fytala-Charles/Bosak.Exslt` — REQ-006 git part done, CI workflow pending; REQ-008 implemented 2026-10-06**)
> This document tracks feature requests and backlog items for the Bosak.Exslt library. It is the single source of truth for cross-cutting work that spans modules, tests, or packaging.

---

## 1. Purpose

Bosak.Exslt is a shared asset: a legacy-migration aid for consumers of the Bosak engine, a training/showcase codebase, and a golden-file test corpus. When new work is proposed — more corpus imports, packaging, engine-backed functions — it is recorded here first. This prevents duplicate work, enables prioritization, and keeps the relation to the Bosak core roadmap (REQ-121) explicit.

**Who can request:** Any consumer of the Bosak engine, any Fytala project, or a maintainer/agent working in this repo.  
**Who implements:** Bosak.Exslt maintainers, or contributing teams via PR.  
**Who updates this file:** Agents (on any project) and human maintainers, in the same step as the work it describes.

---

## 2. How to Submit a Feature Request

### 2.1 Quick Add (for Agents)

Append a new row to the **Request Registry** below using this format:

```markdown
| `<REQ-XXX>` | `<Requester>` | `<One-line summary>` | `<Motivation>` | `Pending` | `TBD` | `Unassigned` | `YYYY-MM-DD` |
```

Then create a detail section in **Request Details** following the template in §3.

### 2.2 Human-Submitted Requests

1. Open a PR adding your request to this file.
2. Tag the PR with `feature-request`.
3. Discuss in the PR thread; maintainers will update **Status** and **Decision Log**.

---

## 3. Request Detail Template

Every request in the registry must have a matching detail section. Copy this template:

```markdown
### REQ-XXX: <Title>

**Requesting Party:** `<Name>`  
**Submitted:** `YYYY-MM-DD`  
**Status:** `Pending | Accepted | Declined | In Progress | Implemented | Superseded`

#### Problem Statement
<What is being tried to achieve?>

#### Proposed Solution
<What should Bosak.Exslt provide?>

#### Acceptance Criteria
- [ ] <Criterion 1>
- [ ] <Criterion 2>

#### Impact Analysis
| Layer | Impact | Notes |
|-------|--------|-------|
| src/ modules | None / New function / New module | |
| golden corpus | None / New cases / Re-golden | |
| docs | None / Matrix update | |

#### Related Requests
- <Link to related REQ-YYY, core REQ-121, or an ADR>

#### Decision Log
| Date | Actor | Decision | Rationale |
|------|-------|----------|-----------|
| YYYY-MM-DD | `<Name/Kimi>` | Accepted | <Why> |
```

> **Large requests:** when a REQ grows phases or assessments, move deep detail to a dedicated dossier `docs/REQ-NNN-<slug>.md` and link it. The registry row and a summary detail section here remain mandatory.

---

## 4. Request Registry

| ID | Requesting Party | Summary | Motivation | Status | Target Version | Owner | Submitted |
|----|------------------|---------|------------|--------|----------------|-------|-----------|
| `REQ-001` | `Bosak.Exslt` | Import the remaining deterministic libxslt EXSLT corpus (math, strings, sets, common, date directories) into the golden-file layout | 15 seed cases exist; the remaining deterministic cases (~60 files across 5 directories) pin the rest of the implemented surface against the reference implementation | Accepted | v0.1.0 | Unassigned | 2026-10-06 |
| `REQ-002` | `Bosak.Exslt` | Import Xalan-J EXSLT tests (Apache-2.0) as the second legal corpus source | libxslt does not exercise every EXSLT semantic; Xalan-J's suite covers alternate reference behavior for divergent functions | Pending | v0.1.0 | Unassigned | 2026-10-06 |
| `REQ-003` | `Bosak.Exslt` | Ship namespace modules as `xsl:package` artifacts consumable via `xsl:use-package`, alongside the plain import/include files | Versioned packages give consumers dependency ranges; plain files remain the primary distribution | Pending | v0.2.0 | Unassigned | 2026-10-06 |
| `REQ-004` | `Fytala` | Resolve the `dyn:evaluate` engine-support question: host-backed tier in the Bosak core (free or commercial option) and a thin wrapper here | Tier-3 functions cannot exist in pure XSLT 3.0; `xsl:evaluate` or a native engine function is the only path (tracked against core REQ-121; see ADR-001) | Pending | TBD | Unassigned | 2026-10-06 |
| `REQ-005` | `Fytala` | Sample gallery / documentation site: runnable example stylesheets per module, rendered output, "learn Bosak XSLT" walkthrough | The training/showcase role needs a consumer-facing surface beyond the repo; amplifies the engine's public demonstration value | Pending | v0.3.0 | Unassigned | 2026-10-06 |
| `REQ-006` | `Fytala` (owner) | Repository bootstrap: `git init`, first commit, CI workflow (build + `tools/check-docs.ps1` + `dotnet test`) | Files existed on disk only; the owner reviewed and initialized git on 2026-10-06 (house rule: agents run `git init`/commit/push only on explicit owner request) | In Progress (git done 2026-10-06 — repo live at `Fytala-Charles/Bosak.Exslt`; CI workflow pending) | Pre-v0.1.0 | Owner | 2026-10-06 |
| `REQ-007` | `Fytala` | Training curriculum under `training/`: eleven self-paced, Fytala-branded sessions, each teaching one XSLT 3.0 technique by test-first re-creation of an EXSLT function | The training/showcase role needs structured, self-explorable learning material; training is a sandbox that must never jeopardize the library artifact | In Progress (sessions 00–10 scaffolded 2026-10-06) | Pre-v0.1.0 | Unassigned | 2026-10-06 |
| `REQ-008` | `Bosak.Exslt` (maintainers) | Fix the latent date-formatting type defect: `date:date`, `date:month-name`, `date:month-abbreviation`, `date:week-in-year`, `date:day-in-year`, `date:day-name`, `date:day-abbreviation` pass an `xs:dateTime` to `format-date` (first parameter `xs:date?`) → `XPTY0004` → silent `''`/`NaN` for every input on signature-enforcing engines | Found while authoring training session 08 (2026-10-06); `date:time` already applies the correct cast pattern (`xs:time(substring(string(...), 12))`) — the fix is that same one-line cast per function, each with a new golden case per the TDD rule | Implemented | Pre-v0.1.0 | Unassigned | 2026-10-06 — seven `xs:date` casts landed in `dates-and-times.xsl`, seven new golden cases (`tests/cases/date/`), harness 22/22 |

> **Legend:**
> - `Pending` — Under review, no decision yet.
> - `Accepted` — Approved for implementation, awaiting scheduling.
> - `In Progress` — Actively being developed.
> - `Implemented` — Done and verified by the gates in `docs/AGENT_HANDOVER.md` §5.
> - `Declined` — Rejected with rationale recorded.
> - `Superseded` — Replaced by another request.

---

## 5. Request Details

### REQ-001: Import the remaining libxslt EXSLT corpus

**Requesting Party:** `Bosak.Exslt` (maintainers)  
**Submitted:** `2026-10-06`  
**Status:** `Accepted`

#### Problem Statement

The golden corpus seeds 15 of the deterministic libxslt EXSLT cases (3 math, 5 strings, 3 sets, 2 common, 2 date). The upstream `tests/exslt/` tree holds ~60 more deterministic cases across the same five directories, plus `dynamic/`, `functions/`, and `saxon/` directories whose content is not golden-material (error-path, engine-specific, or processor-specific). Functions implemented in `src/` but not yet golden-pinned include `math:lowest`, `math:constant`, `math:power`, `set:trailing`, `set:difference`, `set:intersection`, `date:seconds`, `date:sum`, `date:difference`, `date:add`, and the whole date component-extraction family (`date:year` … `date:day-abbreviation`).

#### Proposed Solution

Mechanically convert each deterministic case to the `tests/cases/<namespace>/<case>/` layout per `tests/Bosak.Exslt.Tests/README.md`, record every adaptation in `meta.json` + `tests/ATTRIBUTION.md`, and re-golden deliberately (never silently) where our documented divergence applies (decimal-exact durations, `object-type` RTF). Skip with a recorded reason: time-dependent cases (`date:current.xsl`), error-output cases (`recursion.err` style), and `math:power.1`-style cases whose golden values encode libxslt binary-float formatting.

#### Acceptance Criteria

- [ ] Every remaining deterministic libxslt case for the five imported directories is converted or has a recorded skip reason in `tests/ATTRIBUTION.md`.
- [ ] Every function listed in `docs/COMPATIBILITY.md` as "implemented" or "wrapper" has at least one golden case.
- [ ] `dotnet test` green; `pwsh tools/check-docs.ps1 -ProjectPath .` ALL CHECKS PASSED.

#### Impact Analysis
| Layer | Impact | Notes |
|-------|--------|-------|
| src/ modules | None | No module changes expected; divergences get documented, not patched around |
| golden corpus | New cases | ~40–60 new case directories |
| docs | Matrix update | Test-coverage column pointers in `docs/COMPATIBILITY.md` |

#### Related Requests
- REQ-002 (second corpus), core REQ-121 (EXSLT support), [ADR-001](./ADR-001-three-tier-compatibility-model.md)

#### Decision Log
| Date | Actor | Decision | Rationale |
|------|-------|----------|-----------|
| 2026-10-06 | Kimi | Accepted | Deterministic corpus is the cheapest compatibility evidence available |

---

### REQ-002: Import Xalan-J EXSLT tests as second corpus

**Requesting Party:** `Bosak.Exslt` (maintainers)  
**Submitted:** `2026-10-06`  
**Status:** `Pending`

#### Problem Statement

Where EXSLT implementations diverge (e.g. `str:tokenize` return shapes, `math:power` edge cases), libxslt is only one reference. Xalan-J's EXSLT tests (Apache-2.0, `apache/xalan-j` on GitHub) are a legally clean second source that exercises alternate semantics and would pin our *documented* choices with evidence.

#### Proposed Solution

Fetch a starter set from the Xalan-J repository, convert to the case layout with `source.project = "xalan-j"`, and where Xalan-J disagrees with libxslt, keep both cases and mark the divergence in `meta.json` notes.

#### Acceptance Criteria

- [ ] At least one Xalan-J-sourced case per namespace where that suite has EXSLT coverage.
- [ ] libxslt-vs-Xalan-J disagreements pinned by dual cases, not by silently picking one.

#### Impact Analysis
| Layer | Impact | Notes |
|-------|--------|-------|
| src/ modules | None expected | Possible documentation-only divergences |
| golden corpus | New cases | Cross-check value |
| docs | Matrix update | Divergence notes in `docs/COMPATIBILITY.md` |

#### Related Requests
- REQ-001 (primary corpus)

#### Decision Log
| Date | Actor | Decision | Rationale |
|------|-------|----------|-----------|
| — | — | Pending | Awaiting REQ-001 completion to avoid corpus churn |

---

### REQ-003: `xsl:package` packaging

**Requesting Party:** `Bosak.Exslt` (maintainers)  
**Submitted:** `2026-10-06`  
**Status:** `Pending`

#### Problem Statement

Today the library is consumed by `xsl:import`/`xsl:include` of plain files. XSLT 3.0 `xsl:package` gives versioned, named components with use-package version ranges — the natural distribution upgrade, and a dogfood of the Bosak engine's package support.

#### Proposed Solution

Add `xsl:package` wrappers per namespace module (keeping the plain files primary), verify against Bosak's package version-resolution behavior, document in `README.md`.

#### Acceptance Criteria

- [ ] Each namespace consumable via `xsl:use-package` with a version range.
- [ ] Package-mode golden case proving cross-package function calls.

#### Impact Analysis
| Layer | Impact | Notes |
|-------|--------|-------|
| src/ modules | New files | `xsl:package` variants; plain `.xsl` files unchanged |
| golden corpus | New cases | Package-mode case(s) |
| docs | Usage section | `README.md` + `docs/ARCHITECTURE.md` |

#### Related Requests
- REQ-006 (bootstrap first — packages need a repo)

#### Decision Log
| Date | Actor | Decision | Rationale |
|------|-------|----------|-----------|
| — | — | Pending | Sequenced after bootstrap and corpus work |

---

### REQ-004: `dyn:evaluate` host-backed tier

**Requesting Party:** `Fytala`  
**Submitted:** `2026-10-06`  
**Status:** `Pending`

#### Problem Statement

`dyn:evaluate` (EXSLT dynamic module) requires dynamic XPath evaluation and is tier 3 — not implementable in pure XSLT 3.0. The current slot terminates with `xsl:message`. Consumers migrating libxslt stylesheets that use `dyn:evaluate` have no path today.

#### Proposed Solution

Decision recorded in [ADR-001](./ADR-001-three-tier-compatibility-model.md): either (a) the Bosak core grows `xsl:evaluate` support (XSLT 3.0's native replacement) and/or a native dynamic-evaluation function — free or as the seam-consistent commercial option — with `src/dynamic.xsl` becoming a thin wrapper; or (b) the slot stays terminating and we ship a migration guide. Tracked against core REQ-121.

#### Acceptance Criteria

- [ ] Decision (a) or (b) recorded in the ADR's status line and in `docs/COMPATIBILITY.md`.
- [ ] If (a): golden case for `dyn:evaluate` via the host function.

#### Impact Analysis
| Layer | Impact | Notes |
|-------|--------|-------|
| src/ modules | Possible rewrite of `dynamic.xsl` slot | From terminating message to wrapper |
| golden corpus | New case | Only under decision (a) |
| docs | Matrix update | Tier-3 status row changes |

#### Related Requests
- Core REQ-121, [ADR-001](./ADR-001-three-tier-compatibility-model.md)

#### Decision Log
| Date | Actor | Decision | Rationale |
|------|-------|----------|-----------|
| 2026-10-06 | Kimi (skeleton) | Slot terminates with clear message | No fake implementation per ADR-001 |

---

### REQ-005: Sample gallery / documentation site

**Requesting Party:** `Fytala`  
**Submitted:** `2026-10-06`  
**Status:** `Pending`

#### Problem Statement

The "learn Bosak XSLT by reading real code" role currently lives entirely inside the repo. A rendered gallery — example legacy stylesheet, import statement, before/after output — makes the showcase consumable and markets the engine.

#### Proposed Solution

Static site generated from runnable samples in a `samples/` tree (each sample = legacy XSLT 1.0 stylesheet + modernized XSLT 3.0 + captured output from the harness). Reuse the golden-file harness for output capture.

#### Acceptance Criteria

- [ ] One runnable sample per namespace module.
- [ ] Sample outputs produced by the harness, not hand-written.

#### Impact Analysis
| Layer | Impact | Notes |
|-------|--------|-------|
| src/ modules | None | |
| golden corpus | None (samples are not goldens) | |
| docs | New tree | `samples/` + site generator |

#### Related Requests
- REQ-006 (bootstrap; site publishing needs a repo)

#### Decision Log
| Date | Actor | Decision | Rationale |
|------|-------|----------|-----------|
| — | — | Pending | Post-v0.1.0 candidate |

---

### REQ-006: Repository bootstrap (git init + CI)

**Requesting Party:** `Fytala` (owner)  
**Submitted:** `2026-10-06`  
**Status:** `In Progress` — git bootstrap done 2026-10-06 on explicit owner request (initial commit on `main`, remote `git@github.com:Fytala-Charles/Bosak.Exslt.git`, repo public); CI workflow still pending.

#### Problem Statement

The repository existed on disk only. House rules forbid agents from running `git init`/commit/push without an explicit owner request; the owner reviewed and initialized on 2026-10-06. CI still needs to gate the two verification commands on every push.

#### Proposed Solution

1. ~~Owner: `git init`, review, first commit, remote.~~ Done 2026-10-06 (owner-requested; agent-executed).
2. Add `.github/workflows/build.yml`: restore/build, `dotnet test`, `pwsh tools/check-docs.ps1 -ProjectPath . -Strict`.

#### Acceptance Criteria

- [x] Repository initialized by the owner; history starts at the reviewed skeleton.
- [ ] CI workflow runs the test suite and the documentation checker on push/PR.

#### Impact Analysis
| Layer | Impact | Notes |
|-------|--------|-------|
| src/ modules | None | |
| golden corpus | None | |
| docs | Hygiene | Versioning section of `ROADMAP.md` activates (MinVer from tags) |

#### Related Requests
- Blocks REQ-003 (packaging) and REQ-005 (site publishing)

#### Decision Log
| Date | Actor | Decision | Rationale |
|------|-------|----------|-----------|
| 2026-10-06 | Kimi (skeleton) | Deferred to owner | House git rules |
| 2026-10-06 | Owner (via Kimi, explicit request) | Bootstrapped: `git init` on `main`, repo created public at `Fytala-Charles/Bosak.Exslt`, initial commit pushed. Identity: repo-local `Charles Korthout <charles.korthout@fytala.nl>` (matches Bosak core). Collaborator invite sent to the machine's SSH account (`poco-irrilevante`, matching the Bosak core setup). Kit-managed files pinned to LF via `.gitattributes` so `check-docs.ps1` SHA-256 checks survive Windows checkouts. CI workflow remains open. | House rule satisfied: owner explicitly asked for init/commit/push. |

---

### REQ-007: Training curriculum (learning XSLT with EXSLT)

**Requesting Party:** `Fytala`  
**Submitted:** `2026-10-06`  
**Status:** `In Progress` — sessions 00–02 scaffolded 2026-10-06: branded self-paced index `training/README.md`, session `00-setup` (install guide + `check-setup.ps1` configuration check), session `01-xslt-basics` (processing model, templates, literal result elements), session `02-first-stylesheet` (lesson + starter + solution + case on `math:highest`), `training/TrainingTests` harness green (4/4), `tools/check-docs.ps1` extended for session integrity and training branding. **Companion XPath foundations track scaffolded same day** (`training/xpath/` per owner decision: a separate, reusable base-knowledge training referenced from the XSLT curriculum): branded index, session `01-values-and-paths` (raw `.xpath` exercises), `XPathTrainingTests` harness green (2/2) on published `Bosak.XPath.Api`. Session `03-recursion` scaffolded 2026-10-06 (lesson + starter + solution + case on recursive `str:padding` and `str:align`; harness green 6/6 including the session's two discovery-generated tests). Session `04-regular-expressions` scaffolded 2026-10-06 (lesson + starter + solution + case on `str:tokenize`, `str:split`, and ASCII-scoped hand-rolled `str:encode-uri`; the lesson teaches around the three documented Bosak 0.12.3-beta engine quirks; harness green 8/8). Session `05-stateful-scanning` scaffolded 2026-10-06 (lesson + starter + solution + case on the left-to-right scanner behind `str:replace` — earliest-position wins, document-order tie-break, no re-scanning; harness green 10/10). Session `06-nodes-and-grouping` scaffolded 2026-10-06 (lesson + starter + solution + case on identity-based `set:has-same-node`, `set:distinct`, and `set:difference` — `is` vs `=`, `<<` document order, `except`; harness green 12/12). Session `07-result-trees-and-types` scaffolded 2026-10-06 (lesson + starter + solution + case on `exsl:node-set` as the XSLT 3.0 identity and `exsl:object-type` via `instance of`, pinning the documented RTF→`node-set` divergence; harness green 14/14). Session `08-dates-parsing-formatting` scaffolded 2026-10-06 (lesson + starter + solution + case on `date:year`, `date:leap-year`, and `date:month-name` over a shared lenient ISO 8601 parser; the scaffold exposed the latent `format-date` type defect later repaired as REQ-008, and session 08's golden was subsequently re-pinned to the post-repair world — its README now tells that bug story; harness green 16/16). Session `09-duration-arithmetic` scaffolded 2026-10-06 (lesson + starter + solution + case on `date:duration`, `date:add-duration`, and `date:sum` — component arithmetic with libxslt-exact carry/normalization, decimal-exact seconds formatting with the documented `PT59M59.99999999999S` divergence taught honestly, and the `date:add` vs `date:add-duration` calendar/component distinction; harness green 18/18). Session `10-limits-of-pure-xslt` scaffolded 2026-10-06 (lesson + starter + solution + case on the tier-3 `dyn:evaluate` wall — shown in the lesson via the terminating `src/dynamic.xsl` slot, never in the harness — and the pure-XSLT alternative the learner builds instead: a function-item operation registry with `map:contains` guard, a `fold-left` map-accumulator summary, and a `filter`+`for-each` rejected list; all HOF/function-item constructs empirically verified on Bosak 0.12.3-beta before authoring; the TrainingTests discovery was widened from `0*` to all directories with the `case/meta.json` marker so sessions 10+ are found; harness green 20/20).

#### Problem Statement

The repository's training/showcase role deserves structured learning material, not only "read the tier-2 sources". The owner defined the shape: **eleven sessions, rising difficulty — XSLT basics first, then each session taking one EXSLT function and teaching the XSLT techniques needed to implement it**, documented as Markdown, with starter stylesheets and a test to enable TDD. Crucially, training is **different from the library**: the training sources must never jeopardize the library artifact — a sandbox with a one-way, deliberately-taught bridge (capstone) into the real corpus.

#### Proposed Solution

Ten numbered sessions `training/NN-slug/`, each a self-contained, Fytala-branded, self-explorable unit:

- `README.md` — lesson: concept walkthrough ("naive attempt → why it fails → real implementation"), RED→GREEN exercise with progressive hints, library cross-reference (`src/…`) **after** the learner's attempt, "go further" section. No session assumes a trainer present.
- `starter/transform.xsl` — compiles and runs, but its output is non-golden (the `Starter_differs_from_golden` harness test fails the build if a starter accidentally solves the exercise).
- `solution/transform.xsl` — the reference answer; `Solution_matches_golden` pins it to the golden.
- `input.xml` + `case/` (`meta.json` in the golden-corpus shape + `expected.xml`/`expected.txt`).

Harness `training/TrainingTests` mirrors the golden harness (same published Bosak packages, same whitespace-normalized comparison) but copies **no** `src/` files — session stylesheets are self-contained by rule. Session 10 is the capstone: the learner executes the real contribution workflow into `src/` + `tests/cases/` + the documentation sync checklist. Full curriculum outline (dependency-ordered techniques and vehicle functions): `training/README.md`.

#### Acceptance Criteria

- [ ] All 11 sessions available; each has a branded lesson README, a RED starter, a GREEN solution, and valid case metadata.
- [ ] XPath foundations track (`training/xpath/`) available alongside: 4–5 sessions of pure XPath 3.1 on raw `.xpath` expression files, referenced as prerequisites from the XSLT sessions that assume them.
- [ ] Training stylesheets never `xsl:include`/`xsl:import` `src/` (isolation rule; `docs/ARCHITECTURE.md` §4 records it).
- [ ] `dotnet test training/TrainingTests/TrainingTests.csproj` green; training docs pass `tools/check-docs.ps1` session-integrity and branding checks.
- [ ] Session 10 teaches the full library contribution workflow (file headers, `docs/COMPATIBILITY.md`, `tests/ATTRIBUTION.md`, doc sync checklist).

#### Impact Analysis
| Layer | Impact | Notes |
|-------|--------|-------|
| src/ modules | None until session 10 | Capstone deliberately teaches the contribution path |
| golden corpus | None | Training cases live under `training/`, never in `tests/cases/` |
| docs | New tree + registry row | `training/` README + sessions are branded public-facing docs |

#### Related Requests
- REQ-005 (sample gallery is the consumer-facing sibling), core REQ-121

#### Decision Log
| Date | Actor | Decision | Rationale |
|------|-------|----------|-----------|
| 2026-10-06 | Owner (via Kimi) | Accepted; scaffold session 01 | Training as sandbox under root; branding contract applies; library must stay jeopardize-proof |

---

### REQ-008: Fix latent date-formatting type defect (`format-date` family)

**Requesting Party:** `Bosak.Exslt` (maintainers)
**Submitted:** `2026-10-06`
**Status:** `Implemented`
**Resolved:** `2026-10-06` — all seven functions repaired and golden-tested; harness 22/22.

#### Problem Statement

Seven date functions — `date:date`, `date:month-name`, `date:month-abbreviation`, `date:week-in-year`, `date:day-in-year`, `date:day-name`, `date:day-abbreviation` — pass `date:_as-datetime($date-time)` (always an `xs:dateTime`) directly to `fn:format-date`, whose first parameter is typed `xs:date?`. On any signature-enforcing processor (including Bosak 0.12.3-beta, verified empirically 2026-10-06) this raises `err:XPTY0004`, which the functions' defensive `try/catch` swallows — so they silently return `''` (or `NaN` for the numeric ones) for **every** input. The golden corpus does not cover them (the two date cases are `duration.1`/`add-duration.1`), so the matrix rows read "implemented" while the behavior is empty. Not an engine bug: `format-date`/`format-dateTime` were independently verified working on this engine (`[Y0001]-[M01]-[D01]`, `[MNn]`, `[H01]:[m01]` all correct). Found during training session 08 authoring; at filing time the session's golden deliberately pinned the then-current (always-empty) library behavior — it has since been re-pinned to the post-repair world (see Resolution).

#### Proposed Solution

Apply the cast pattern `date:time` already uses (`xs:time(substring(string(date:_as-datetime($date-time)), 12))`) to the seven functions — i.e. `format-date(xs:date(substring(string(...), 1, 10)), ...)`. This is a bug fix, not a divergence: the functions change from "always empty" to the correct EXSLT answer, so no `tests/ATTRIBUTION.md` divergence entry is required (record the repair as an adaptation note instead). Per the golden-file TDD rule, each fixed function gets at least one happy-path golden case plus an edge case; `docs/COMPATIBILITY.md` test pointers are updated in the same step.

#### Acceptance Criteria

- [x] All seven functions return the correct EXSLT values on Bosak 0.12.3-beta.
- [x] Each fixed function has at least one golden case (happy path + edge) under `tests/cases/date/`.
- [x] `docs/COMPATIBILITY.md` matrix and test pointers updated; no silent behavior change anywhere.
- [x] `dotnet test` green; `pwsh tools/check-docs.ps1 -ProjectPath .` ALL CHECKS PASSED.

#### Resolution

Implemented 2026-10-06. The seven `format-date` call sites in
`src/dates-and-times.xsl` now cast their argument
(`xs:date(substring(string(date:_as-datetime($date-time)), 1, 10))`), and
seven new hand-written golden cases under `tests/cases/date/` (one per
function, each with a happy path and an edge) pin the repaired behavior —
harness 22/22. `date:add`'s `format-dateTime` call site needed no change.
Training session 08's golden was re-pinned to the post-repair world, and its
README now tells this defect as the session's core lesson. Recorded as an
adaptation note in `tests/ATTRIBUTION.md`; deliberately **not** a
divergence (the functions moved from always-empty to the correct EXSLT
answers).

#### Impact Analysis
| Layer | Impact | Notes |
|-------|--------|-------|
| src/ modules | `dates-and-times.xsl` | Seven one-line casts; header change-history row |
| golden corpus | New cases | ≥7 case directories (one per function) |
| docs | Matrix update | Test-coverage pointers in `docs/COMPATIBILITY.md` |

#### Related Requests
- REQ-001 (corpus import overlaps the new golden cases), REQ-007 (found during session 08)

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Feature Requests
  </p>
</div>
