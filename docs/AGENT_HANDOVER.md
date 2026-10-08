# Agent Handover — Bosak.Exslt

> **Canonical handover document** for coding agents working on the Bosak.Exslt project.  
> There is no session scratchpad convention in this repository: this file is the single handover surface. Update it at the end of every session.

---

## 1. Project Identity

- **What:** A pure-XSLT 3.0 implementation of EXSLT for the [Bosak](https://github.com/Fytala) XPath 3.1 / XSLT 3.0 engine — Apache-2.0, copyright Fytala (Charles Korthout). Three roles at once: **legacy-migration aid** (XSLT 1.0 + EXSLT stylesheets keep working via import/include), **training/showcase codebase** (genuine, readable XSLT 3.0), and **golden-file test corpus** ("TDD for XSLT").
- **Spine:** the **three-tier compatibility model** ([ADR-001](./ADR-001-three-tier-compatibility-model.md)) — tier 1 = thin wrappers over native XPath 3.1; tier 2 = genuine pure-XSLT implementations; tier 3 = documented-only (`dyn:evaluate`), slot terminates with `xsl:message`. Never a fake implementation.
- **Repo:** initialized 2026-10-06 on explicit owner request — branch `main` tracks `origin/main`, remote `git@github.com:Fytala-Charles/Bosak.Exslt.git` (public), two commits pushed. Location: `D:/Development/Bosak.Exslt`. Note: this machine's SSH key authenticates as collaborator account `poco-irrilevante` (same setup as the Bosak core repo); the collaborator invite was accepted 2026-10-06, so SSH push/pull works as usual.
- **Language:** XSLT 3.0 stylesheets (the product) + one xUnit test harness (net10.0).
- **Status:** **Pre-release skeleton, fully green.** 7 library modules; golden-file harness **103/103** against published `Bosak.Xslt` **0.12.3-beta`; **REQ-002 Implemented 2026-10-08** (Xalan-J second corpus: 30 cases from `apache/xalan-test`, Apache-2.0 — 22 matched upstream verbatim, 8 documented adaptations, 10 skips recorded; dual-corpus pins for the `math:power` and `exsl:object-type` divergences; two new divergence classes recorded: Xalan `StrictMath` float noise and XPath 3.1 number formatting; no library bugs found); **REQ-004 Accepted 2026-10-08** (`dyn:evaluate` decision recorded: thin wrapper over standard `xsl:evaluate` per the ADR-001 amendment — no native/commercial engine function needed; probe found the instruction present but the context item never propagated (XPDY0002), so the slot stays terminating until the core fix lands against core REQ-121; full wrapper design in the ADR); **REQ-006 Implemented 2026-10-08** (CI workflow live: `.github/workflows/build.yml` on ubuntu-latest — build + 3 test projects + `check-docs.ps1 -Strict`; six backslash literals in the checker made cross-platform for it; first live run green after fixing a Linux-only broken-reference bug in the checker — see gotcha §4.8); **REQ-001 Implemented 2026-10-08** (deterministic libxslt corpus fully imported: 61 libxslt-derived + 12 hand-written cases, every implemented/wrapper function golden-pinned; three repairs landed during import — `strings.xsl` 1.1 UTF-8 `decode-uri` + `encode-uri` mark restoration, `sets.xsl` 1.1 `set:trailing` first-node anchor, `dates-and-times.xsl` v1.3 libexslt `date.c` port); **REQ-008 fixed 2026-10-06** (seven `format-date`-family functions repaired); full house documentation set (`ARCHITECTURE.md`, `FEATURE_REQUESTS.md`, `AGENT_HANDOVER.md`, kit style guide, ADR-000/001, root `ROADMAP.md`) landed 2026-10-06; **Fytala Docs Kit v1.2.0 branding adopted** (assets, banners, About FYTALA, footers, checker section 6) same day; **repository bootstrapped same day** (`main` live at `Fytala-Charles/Bosak.Exslt`, initial commit pushed); `tools/check-docs.ps1` ALL CHECKS PASSED. **Training curriculum (REQ-007) scaffolded same day:** branded self-paced index `training/README.md`, sessions 00–02 (`00-setup` install guide + configuration check, `01-xslt-basics` processing model + templates, `02-first-stylesheet` with the RED→GREEN exercise on `math:highest`, `03-recursion` with the `str:padding`/`str:align` tail-recursion exercise, `04-regular-expressions` with the `str:tokenize`/`str:split`/`str:encode-uri` regex exercise, `05-stateful-scanning` with the `str:replace` single-pass scanner exercise, `06-nodes-and-grouping` with the `set:has-same-node`/`set:distinct`/`set:difference` node-identity exercise, `07-result-trees-and-types` with the `exsl:node-set`/`exsl:object-type` document-node exercise, `08-dates-parsing-formatting` with the `date:year`/`date:leap-year`/`date:month-name` exercise — its authoring exposed the latent REQ-008 `format-date` defect, fixed the same day and now told as the session's bug story, `09-duration-arithmetic` with the `date:duration`/`date:add-duration`/`date:sum` exercise — decimal-exact divergence and the add vs add-duration distinction taught; native `xs:duration` arithmetic found rejected on 0.12.3-beta, `10-limits-of-pure-xslt` with the safe-dispatcher exercise — function items/HOFs verified working, the tier-3 `dyn:evaluate` slot taught as the wall pure XSLT cannot climb, `11-capstone-ship-a-function` — the full contribution workflow rehearsed in miniature on a proposed `str:repeat`; **REQ-007 Implemented 2026-10-06**), the unnumbered addendum `ADDENDUM-xslt-and-functional-languages.md` (XSLT's FP concepts named in F#/Haskell terms: immutability, tail recursion, pattern-directed dispatch, HOFs, purity, divergences), the independent `training/TrainingTests` harness (22/22, session-directory discovery; widened 2026-10-06 from `0*` to a meta.json marker so sessions 10+ are discovered), plus the companion **XPath foundations track — COMPLETE 2026-10-06** (`training/xpath/`: branded index, sessions `01-values-and-paths`, `02-predicates-and-sequences`, `03-functions-and-operators`, `04-flwor-expressions`, `05-putting-it-together` (composition + bridge into XSLT session 02), `XPathTrainingTests` harness 10/10 on published `Bosak.XPath.Api`; `every`/`satisfies` verified working) — training is a self-contained sandbox that never includes `src/`. **REQ-007 fully met: all acceptance criteria satisfied 2026-10-06.**
- **Relation to the core roadmap:** tracked against **core REQ-121** (EXSLT / legacy migration) — the core engine stays standards-only; EXSLT compatibility lives here. The host-backed tier question (`dyn:evaluate`, `math:random`, `func:function` commercial option) is REQ-004 in `docs/FEATURE_REQUESTS.md`.

---

## 2. What Exists Today

| Item | Location |
|------|----------|
| Library modules (all `version="3.0"`, standard XSLT only): `exslt.xsl` (master, includes all) + `exsl.xsl`, `math.xsl`, `strings.xsl`, `dates-and-times.xsl`, `sets.xsl`, `dynamic.xsl` | `src/` |
| Golden-file harness: xUnit, case discovery under `cases/`, Bosak `XsltCompiler` + `XDocumentNode` + `TransformToString`, whitespace-normalized XML / token-stream text comparison | `tests/Bosak.Exslt.Tests/` |
| Golden corpus: **103 cases** across math (29), strings (15), sets (12), common (13), date (34 — 32 libxslt-derived + 2 legacy with re-goldened divergence lines), each `transform.xsl` + `expected.xml`/`.txt` + `meta.json` (+ `input.xml`); 91 imported (61 libxslt MIT + 30 Xalan-J Apache-2.0 from `apache/xalan-test`, REQ-002) + 12 hand-written (Apache-2.0); skips recorded in `tests/ATTRIBUTION.md` | `tests/cases/` |
| Per-function compatibility matrix (tier, status, native equivalent, test pointer, divergences) — **authoritative** | `docs/COMPATIBILITY.md` |
| Feature-request registry (REQ-001…006) | `docs/FEATURE_REQUESTS.md` |
| Architecture reference + dependency rules + harness architecture | `docs/ARCHITECTURE.md` |
| Doc/style rules incl. XSLT-specific contracts | `docs/XSLT_STYLE_GUIDE.md` |
| Fytala Docs Kit branding contract (kit-managed — sync from Prime, never hand-edit) | `docs/DOCUMENTATION_STYLE_GUIDE.md` |
| Docs-kit brand assets + integrity manifest + renderer config (all kit-managed) | `assets/`, `docs-kit/manifest.json`, `.fytala-docs.json`, `.crossnote/`, `.vscode/settings.json` |
| Three-tier ADR | `docs/ADR-001-three-tier-compatibility-model.md` |
| Fixture provenance + verbatim libexslt MIT notice + import rules | `tests/ATTRIBUTION.md` |
| Case-layout contract | `tests/Bosak.Exslt.Tests/README.md` |
| Training curriculum: branded self-paced index (11-session plan, RED→GREEN method, golden rule) | `training/README.md` |
| Training session 01 (XSLT basics): lesson + starter + solution + case (templates, `for-each`, value-of, AVTs) | `training/01-xslt-basics/` |
| Training session 02: lesson + starter + solution + case (`math:min`/`math:max` given, implement `math:highest`) | `training/02-first-stylesheet/` |
| Training session 03: lesson + starter + solution + case (recursion with an accumulator; implement `str:padding`, then `str:align` composed on it) | `training/03-recursion/` |
| Training session 04: lesson + starter + solution + case (regex tokenizing; implement `str:tokenize`, `str:split`, `str:encode-uri`; engine-quirk workarounds taught honestly) | `training/04-regular-expressions/` |
| Training session 05: lesson + starter + solution + case (single-pass stateful scan; implement `str:replace` with earliest-position/tie-break/no-rescan semantics) | `training/05-stateful-scanning/` |
| Training session 06: lesson + starter + solution + case (node identity vs value equality; implement `set:has-same-node`, `set:distinct`, `set:difference`) | `training/06-nodes-and-grouping/` |
| Training session 07: lesson + starter + solution + case (XSLT 1.0 RTF wound; implement `exsl:node-set`, `exsl:object-type`; RTF→`node-set` divergence pinned deliberately) | `training/07-result-trees-and-types/` |
| Training session 08: lesson + starter + solution + case (date parsing ladder, leap-year rules, `format-date` pictures; implement `date:year`, `date:leap-year`, `date:month-name`; lesson tells the REQ-008 defect-and-repair story) | `training/08-dates-parsing-formatting/` |
| Training session 09: lesson + starter + solution + case (duration component arithmetic, carry/normalization, decimal precision; implement `date:duration`, `date:add-duration`, `date:sum`) | `training/09-duration-arithmetic/` |
| Training session 10: lesson + starter + solution + case (function items, `fold-left`/`map`/`filter`; safe-operation-dispatcher exercise; tier-3 `dyn:evaluate` slot as the pure-XSLT wall) | `training/10-limits-of-pure-xslt/` |
| Addendum: XSLT and functional programming languages (F#/Haskell names for the curriculum's FP concepts; lesson-only, no exercise) | `training/ADDENDUM-xslt-and-functional-languages.md` |
| Training session 11 (capstone): lesson + starter + solution + case (full contribution workflow rehearsed in miniature — proposal, golden-first, house header, mini matrix + attribution, gates; vehicle: proposed tier-2 `str:repeat`) | `training/11-capstone-ship-a-function/` |
| Training harness: per-session `Solution_matches_golden` / `Starter_differs_from_golden` on published Bosak packages, no `src/` copies | `training/TrainingTests/` |
| XPath foundations track: branded index + session 01 (`01-values-and-paths`, exercise on raw `.xpath` files) | `training/xpath/README.md`, `training/xpath/01-values-and-paths/` |
| XPath training harness: evaluates expressions via published `Bosak.XPath.Api`, renders results per track README, same RED/GREEN contract | `training/xpath/XPathTrainingTests/` |
| House conventions + documentation sync checklist | `AGENTS.md` |

Implementation status (full detail: `docs/COMPATIBILITY.md`):

- **Tier 1 wrappers:** `exsl:node-set`, `math:min/max/highest/lowest/sqrt/power/constant/log/sin/cos/tan/asin/acos/atan/atan2/exp`, `str:tokenize`, `set:intersection/difference/has-same-node`.
- **Tier 2 genuine:** `exsl:object-type`; `str:replace` (one-pass positional scan returning a real text node), `str:padding`, `str:align`, `str:split`, `str:encode-uri`, `str:decode-uri` (hand-rolled %XX decode); `set:distinct`, `set:leading`/`set:trailing` (libxml2 containment quirk faithfully reproduced); the **entire date module** (component extraction, `date:duration`/`date:add-duration`/`date:sum` with libxslt-exact component normalization, `date:add`/`date:difference`/`date:seconds`).
- **Tier 3:** `dyn:evaluate` slot terminates; `func:function` and `exsl:document` documented as superseded by `xsl:function` / `xsl:result-document`.

---

## 3. The Governing Contract

Hard rules — violated work is rejected regardless of test color:

1. **`src/` is standard XSLT 3.0 only.** No vendor extensions, no processor conditionals, no engine-specific workarounds that are not themselves conformant XSLT 3.0. (The three engine-bug workarounds in §4 are all conformant.)
2. **The three-tier rules are absolute.** Tier 1 = thin wrapper + native-equivalent doc pointer; tier 2 = genuine implementation with correct EXSLT semantics; tier 3 = documented-only + terminating slot. Never stub a fake implementation to make a case pass.
3. **Golden-file TDD.** Every function change needs a golden case; a golden case may only be *changed* (never deleted) when the implementation diverges from EXSLT/libxslt deliberately, and the divergence must be recorded in the case's `meta.json`, `tests/ATTRIBUTION.md`, and `docs/COMPATIBILITY.md` in the same step.
4. **Attribution is mandatory for imported tests.** Project, license, upstream path in `meta.json` **and** `tests/ATTRIBUTION.md`. Never fabricate provenance; hand-written cases from the spec are attributed as such.
5. **`docs/COMPATIBILITY.md` is the per-function authority.** Any function added, re-tiered, or re-statused updates the matrix in the same step.
6. **Git discipline.** Never run `git init`/commit/push/reset/rebase or create remotes unless the owner explicitly asks (AGENTS.md §8). History was bootstrapped by the owner on 2026-10-06; the owner owns history.

---

## 4. Gotchas

1. **Bosak 0.12.3-beta engine bugs (worked around conformantly; report to core):**
   - `fn:tokenize` keeps zero-length tokens (spec drops them) → filtered in `str:make-tokens`.
   - `xsl:analyze-string` content instructions serialize literally inside `xsl:function` bodies → `str:split` is built on `fn:tokenize` instead; `date:_parse-duration` uses only `select`-valued `matching-substring`, which works.
   - FLWOR: only ONE `for`/`let` clause per expression, and **`order by` is not supported at all** — even `for $b in //book order by … return …` fails at compile time (`XPST0003: XPath does not allow an order by clause`; two clauses: `XPST0003: … does not allow multiple for/let clauses`). Verified 2026-10-06 (XPath session 04; stricter than previously recorded). Workarounds: `fn:sort($seq, (), $keyfn)` (inline functions work), `reverse(...) ! …`; beware `reverse($nodes)/@id` silently re-sorts into document order — only `!` preserves the reversal. Library precedent: flattened single-clause FLWORs in `src/strings.xsl`, `try/catch`-guarded multi-clause FLWOR in `src/dates-and-times.xsl`.
   - Date/time arithmetic rejects plain `xs:duration` operands (`XPTY0004: A plain xs:duration value is not allowed … xs:dayTimeDuration or xs:yearMonthDuration required`) → duration arithmetic is done in component space (`date:add-duration`, `date:sum`); `date:seconds` special-cases its casts. Found 2026-10-06 during session 09 authoring.
   - Map lookup of a missing key returns the empty sequence, and calling the empty sequence as a function raises `XPTY0004` → guard registry lookups with `map:contains` before calling (session 10, verified 2026-10-06). Anonymous functions, named references, `function-lookup`, `for-each`/`filter`/`fold-left`, and function items as parameters all verified working.
   - `xsl:message terminate="yes"` **emits the message but does not abort the transform** on 0.12.3-beta (verified 2026-10-06, session 11) — the tier-3 slot in `src/dynamic.xsl` therefore reports-and-continues on this engine; candidate core gap, report to core. Also verified: `()` as the fallback value of a function declared `as="xs:string"` fails XTTE0780 (slot functions returning empty must declare `item()*` — as `src/dynamic.xsl` already does).
   - Untyped element text is NOT auto-converted for numeric comparison (`//book[year lt 1900]` → `XPTY0004: Comparison between xs:string and numeric operands is not defined`) → cast explicitly (`xs:integer(year) lt 1900`); also portable good style. Verified 2026-10-06 via XPath session 02; candidate core gap, report to core.
   - Stylesheet whitespace-only text nodes adjacent to comments (before AND after) are NOT stripped by the 0.12.3-beta stylesheet parser, unlike libxslt → corpus imports needed per-case whitespace workarounds (REQ-001 batches 2–3). Candidate core gap, report to core.
2. **`str:replace` must return a text node, not a string** — legacy call sites run path steps on the result (`$result/self::text()`); built via a variable + `$result/text()`.
3. **`set:leading`/`set:trailing` quirk:** the libxml2 reference returns the empty set unless the leader/trailer node is itself a member of the first node set; empty second set returns the first set unchanged. The golden case `sets/leading.1` pins this — do not "fix" it to the naive reading.
4. **Documented divergences from libxslt** (all recorded in `docs/COMPATIBILITY.md` + `tests/ATTRIBUTION.md`): `exsl:object-type` reports XSLT 1.0 `RTF` as `node-set`; `date:duration` is decimal-exact (`duration.1` golden line for `3599.99999999999` deliberately re-goldened to `PT59M59.99999999999S` vs libxslt's float-rounded `PT1H`); `math:power` is `exp/log`-based (NaN for negative bases, `power(0,0)` = NaN); `date:add` uses calendar arithmetic, not libxslt's component normalization.
5. **Case paths:** transforms include library modules via `../../../src/<module>.xsl` — three levels up from `tests/cases/<ns>/<case>/` reach the output-directory root, where the csproj copies `src/`. Adding a nesting level breaks every include.
6. **Latent library defect — RESOLVED 2026-10-06 (REQ-008):** seven date-formatting functions (`date:date`, `date:month-name`, `date:month-abbreviation`, `date:week-in-year`, `date:day-in-year`, `date:day-name`, `date:day-abbreviation`) once passed `date:_as-datetime(...)` — always an `xs:dateTime` — to `format-date`, whose first parameter is `xs:date?`. Signature-enforcing engines raised `err:XPTY0004`, swallowed by the defensive `try/catch` → silent `''`/`NaN` for every input. Fixed by the `xs:date(substring(string(...), 1, 10))` cast (`date:time`'s existing pattern), one golden case per function. **Not an engine bug:** `format-date`/`format-dateTime` verified working on 0.12.3-beta (numeric and name pictures). Lesson retained in training session 08.
7. **Harness discovery quirk:** after adding/removing case directories, build before filtering on new case names (`dotnet test --no-build --filter` can miss freshly copied cases).
8. **`tools/check-docs.ps1` must stay cross-platform** (it runs in CI on ubuntu): resolved paths must be tested with `[System.IO.Path]::IsPathRooted`, never a Windows-only `^[A-Za-z]:` drive regex — a sibling link resolved via `Join-Path $file.DirectoryName` is POSIX-absolute on Linux and used to get re-joined onto the project root, producing doubled paths and false "broken reference" failures (found by the first CI run, fixed 2026-10-08). The checker's pass locally on Windows does NOT prove it passes on Linux — always let CI confirm.
9. **`xsl:evaluate` on Bosak 0.12.3-beta (probed 2026-10-08, REQ-004):** the instruction EXISTS and handles static-string `xpath`, `with-params` with `xs:QName` map keys (string keys are correctly rejected per spec, XTTE3165), and `as` coercion. Two conformance gaps: the context item is NEVER propagated (any expression touching `.` fails `XPDY0002` — even `name(/*)` at document level inside `match="/"`), and `with-params` + `with-params-names` leaves the variables unbound (`XTDE3160` — avoidable by using the QName-map form). Gap 1 is the hard blocker for the REQ-004 `dyn:evaluate` wrapper; both reported against core REQ-121. Also noted for later verification: `namespace-context` support is unprobed.

---

## 5. Gates

All four must be green before any task is considered complete:

1. `dotnet build tests/Bosak.Exslt.Tests/Bosak.Exslt.Tests.csproj` — 0 warnings (TreatWarningsAsErrors), 0 errors.
2. `dotnet test tests/Bosak.Exslt.Tests/Bosak.Exslt.Tests.csproj` — all golden cases pass.
3. `dotnet test training/TrainingTests/TrainingTests.csproj` — all sessions green (solution GREEN, starter RED).
4. `dotnet test training/xpath/XPathTrainingTests/XPathTrainingTests.csproj` — all XPath sessions green.
5. `pwsh tools/check-docs.ps1 -ProjectPath .` — ALL CHECKS PASSED.
6. Documentation sync checklist in `AGENTS.md` §7 satisfied for the files touched.

---

## 6. Immediate Next Steps (in order)

1. **REQ-002 Implemented 2026-10-08** (Xalan-J second corpus, 103/103). Remaining backlog: **REQ-003** (`xsl:package` packaging), **REQ-005** (sample gallery) — post-v0.1.0 candidates.
2. **REQ-004 (Accepted 2026-10-08, awaiting core):** when the core fixes `xsl:evaluate` context-item propagation (reported against core REQ-121; see gotcha §4.9), swap the `src/dynamic.xsl` terminating slot for the wrapper designed in the ADR-001 amendment (one-arg inherits caller focus; two-arg wraps `xsl:evaluate` in `xsl:for-each select="$context"`), add golden cases (arithmetic, node-set return, context-node form), re-tier the matrix row 3→2, then close REQ-004.

---

## 7. Conventions

- Follow root `AGENTS.md`: file headers on every `.xsl`/`.cs`, tier rules, golden-file TDD, documentation sync checklist.
- XML/XSLT doc rules (function doc blocks, header shape, matrix authority): `docs/XSLT_STYLE_GUIDE.md`; branding contract: kit-managed `docs/DOCUMENTATION_STYLE_GUIDE.md` (see `AGENTS.md` §6a).
- File headers reference `LICENSE` (Apache-2.0).

---

## 8. Related Documents

| Document | Purpose |
|----------|---------|
| `docs/ARCHITECTURE.md` | Module layout, dependency rules, harness architecture, data flow |
| `docs/COMPATIBILITY.md` | Authoritative per-function matrix |
| `docs/FEATURE_REQUESTS.md` | REQ-001…006 backlog registry |
| `docs/ADR-001-three-tier-compatibility-model.md` | The product's spine, decided |
| `docs/DOCUMENTATION_STYLE_GUIDE.md` | Fytala Docs Kit branding contract (kit-managed) |
| `docs/XSLT_STYLE_GUIDE.md` | Doc + XSLT style contracts |
| `ROADMAP.md` | Release stages & milestones |
| `AGENTS.md` | Coding conventions + sync checklist |
| `tests/ATTRIBUTION.md` | Fixture provenance |

---

*Last updated: 2026-10-08*

