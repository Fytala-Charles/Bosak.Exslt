# Agent Handover — Bosak.Exslt

> **Canonical handover document** for coding agents working on the Bosak.Exslt project.  
> There is no session scratchpad convention in this repository: this file is the single handover surface. Update it at the end of every session.

---

## 1. Project Identity

- **What:** A pure-XSLT 3.0 implementation of EXSLT for the [Bosak](https://github.com/Fytala) XPath 3.1 / XSLT 3.0 engine — Apache-2.0, copyright Fytala (Charles Korthout). Three roles at once: **legacy-migration aid** (XSLT 1.0 + EXSLT stylesheets keep working via import/include), **training/showcase codebase** (genuine, readable XSLT 3.0), and **golden-file test corpus** ("TDD for XSLT").
- **Spine:** the **three-tier compatibility model** ([ADR-001](./ADR-001-three-tier-compatibility-model.md)) — tier 1 = thin wrappers over native XPath 3.1; tier 2 = genuine pure-XSLT implementations; tier 3 = documented-only (`dyn:evaluate`), slot terminates with `xsl:message`. Never a fake implementation.
- **Repo:** initialized 2026-10-06 on explicit owner request — branch `main` tracks `origin/main`, remote `git@github.com:Fytala-Charles/Bosak.Exslt.git` (public), two commits pushed. Location: `D:/Development/Bosak.Exslt`. Note: this machine's SSH key authenticates as collaborator account `poco-irrilevante` (same setup as the Bosak core repo); the collaborator invite was accepted 2026-10-06, so SSH push/pull works as usual.
- **Language:** XSLT 3.0 stylesheets (the product) + one xUnit test harness (net10.0).
- **Status:** **Pre-release skeleton, fully green.** 7 library modules; golden-file harness **15/15** against published `Bosak.Xslt` **0.12.3-beta**; full house documentation set (`ARCHITECTURE.md`, `FEATURE_REQUESTS.md`, `AGENT_HANDOVER.md`, kit style guide, ADR-000/001, root `ROADMAP.md`) landed 2026-10-06; **Fytala Docs Kit v1.2.0 branding adopted** (assets, banners, About FYTALA, footers, checker section 6) same day; **repository bootstrapped same day** (`main` live at `Fytala-Charles/Bosak.Exslt`, initial commit pushed); `tools/check-docs.ps1` ALL CHECKS PASSED.
- **Relation to the core roadmap:** tracked against **core REQ-121** (EXSLT / legacy migration) — the core engine stays standards-only; EXSLT compatibility lives here. The host-backed tier question (`dyn:evaluate`, `math:random`, `func:function` commercial option) is REQ-004 in `docs/FEATURE_REQUESTS.md`.

---

## 2. What Exists Today

| Item | Location |
|------|----------|
| Library modules (all `version="3.0"`, standard XSLT only): `exslt.xsl` (master, includes all) + `exsl.xsl`, `math.xsl`, `strings.xsl`, `dates-and-times.xsl`, `sets.xsl`, `dynamic.xsl` | `src/` |
| Golden-file harness: xUnit, case discovery under `cases/`, Bosak `XsltCompiler` + `XDocumentNode` + `TransformToString`, whitespace-normalized XML / token-stream text comparison | `tests/Bosak.Exslt.Tests/` |
| Golden corpus: **15 cases** across math (3), strings (5), sets (3), common (2), date (2), each `transform.xsl` + `expected.xml`/`.txt` + `meta.json` (+ `input.xml`) | `tests/cases/` |
| Per-function compatibility matrix (tier, status, native equivalent, test pointer, divergences) — **authoritative** | `docs/COMPATIBILITY.md` |
| Feature-request registry (REQ-001…006) | `docs/FEATURE_REQUESTS.md` |
| Architecture reference + dependency rules + harness architecture | `docs/ARCHITECTURE.md` |
| Doc/style rules incl. XSLT-specific contracts | `docs/XSLT_STYLE_GUIDE.md` |
| Fytala Docs Kit branding contract (kit-managed — sync from Prime, never hand-edit) | `docs/DOCUMENTATION_STYLE_GUIDE.md` |
| Docs-kit brand assets + integrity manifest + renderer config (all kit-managed) | `assets/`, `docs-kit/manifest.json`, `.fytala-docs.json`, `.crossnote/`, `.vscode/settings.json` |
| Three-tier ADR | `docs/ADR-001-three-tier-compatibility-model.md` |
| Fixture provenance + verbatim libexslt MIT notice + import rules | `tests/ATTRIBUTION.md` |
| Case-layout contract | `tests/Bosak.Exslt.Tests/README.md` |
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
   - FLWOR supports only a single `for`/`let` clause → library expressions are flattened.
2. **`str:replace` must return a text node, not a string** — legacy call sites run path steps on the result (`$result/self::text()`); built via a variable + `$result/text()`.
3. **`set:leading`/`set:trailing` quirk:** the libxml2 reference returns the empty set unless the leader/trailer node is itself a member of the first node set; empty second set returns the first set unchanged. The golden case `sets/leading.1` pins this — do not "fix" it to the naive reading.
4. **Documented divergences from libxslt** (all recorded in `docs/COMPATIBILITY.md` + `tests/ATTRIBUTION.md`): `exsl:object-type` reports XSLT 1.0 `RTF` as `node-set`; `date:duration` is decimal-exact (`duration.1` golden line for `3599.99999999999` deliberately re-goldened to `PT59M59.99999999999S` vs libxslt's float-rounded `PT1H`); `math:power` is `exp/log`-based (NaN for negative bases, `power(0,0)` = NaN); `date:add` uses calendar arithmetic, not libxslt's component normalization.
5. **Case paths:** transforms include library modules via `../../../src/<module>.xsl` — three levels up from `tests/cases/<ns>/<case>/` reach the output-directory root, where the csproj copies `src/`. Adding a nesting level breaks every include.
6. **Harness discovery quirk:** after adding/removing case directories, build before filtering on new case names (`dotnet test --no-build --filter` can miss freshly copied cases).

---

## 5. Gates

All four must be green before any task is considered complete:

1. `dotnet build tests/Bosak.Exslt.Tests/Bosak.Exslt.Tests.csproj` — 0 warnings (TreatWarningsAsErrors), 0 errors.
2. `dotnet test tests/Bosak.Exslt.Tests/Bosak.Exslt.Tests.csproj` — all golden cases pass.
3. `pwsh tools/check-docs.ps1 -ProjectPath .` — ALL CHECKS PASSED.
4. Documentation sync checklist in `AGENTS.md` §7 satisfied for the files touched.

---

## 6. Immediate Next Steps (in order)

1. **REQ-001** — import the remaining deterministic libxslt EXSLT corpus (see `docs/FEATURE_REQUESTS.md` for the acceptance criteria and skip rules).
2. **REQ-006 (remainder)** — add the CI workflow (`.github/workflows/build.yml`: build + `dotnet test` + `check-docs.ps1 -Strict`); the git bootstrap itself is done (2026-10-06).
3. **REQ-004** — decide the `dyn:evaluate` host-backed tier against core REQ-121; update ADR-001 status.
4. Hand-written edge-case goldens for functions without upstream coverage (`set:trailing`, `math:lowest`, `math:constant`, `str:decode-uri`, `date:seconds`, `date:sum`, `date:difference`) — list maintained in `ROADMAP.md` Stage 1.
5. **REQ-002 / REQ-003 / REQ-005** — Xalan-J corpus, `xsl:package` packaging, sample gallery (post-v0.1.0 candidates).

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

*Last updated: 2026-10-06*

