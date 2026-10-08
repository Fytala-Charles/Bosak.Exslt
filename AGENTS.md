# Bosak.Exslt — Agent Guide

> Canonical agent instructions for the Bosak.Exslt repository. Follows the Fytala
> house conventions of the Bosak core (`D:/Development/Bosak`) and Bosak.Schema
> (`D:/Development/Bosak.Schema`) repositories.

---

## 1. Project Identity

**Bosak.Exslt** — a pure-XSLT 3.0 implementation of EXSLT for the Bosak XPath 3.1 /
XSLT 3.0 engine. Roles: legacy-migration aid, training/showcase codebase, golden-file
test corpus. Apache-2.0, copyright Fytala (Charles Korthout).

- The library in `src/` must remain **standard XSLT 3.0** — no vendor extensions,
  no processor conditionals.
- Compatibility is defined against EXSLT 1.0 (exslt.org) and the libxslt reference
  implementation (the source of the golden corpus).

## 2. Build & Test

```bash
# Golden-file corpus against the published Bosak XSLT packages
dotnet test tests/Bosak.Exslt.Tests/Bosak.Exslt.Tests.csproj

# Training curriculum harness (sessions under training/)
dotnet test training/TrainingTests/TrainingTests.csproj

# XPath foundations harness (sessions under training/xpath/)
dotnet test training/xpath/XPathTrainingTests/XPathTrainingTests.csproj
```

XPath training expressions (`training/xpath/*/starter|solution/exercise.xpath`)
must be **pure XPath 3.1** — no XSLT instructions, no extension functions.

**Rule:** all tests must pass before a task is considered complete. A golden case may
only be *changed* (not deleted) when the implementation diverges from EXSLT/libxslt
deliberately and the divergence is recorded in `tests/ATTRIBUTION.md` and
`docs/COMPATIBILITY.md`. Training cases are not golden cases: they live under
`training/` and are exercised only by the TrainingTests harness, never by
`tests/cases/` — and training stylesheets must stay self-contained (no
`xsl:include`/`xsl:import` of `src/`) so the training sandbox can never break the
library artifact.

## 3. File Headers

Every `.xsl` and `.cs` file begins with a header carrying at minimum:

```
AUTHOR, CREATE DATE, PURPOSE, COPYRIGHT (Fytala), LICENSE (Apache-2.0)
```

`.xsl` files express this as an XML comment before the `xsl:stylesheet` element;
`.cs` files use the house C# header shape (see Bosak core `AGENTS.md`). When
modifying an existing file, append a change-history row with the current date, a
bumped version, and a brief note.

## 4. The Three-Tier Compatibility Model

Every EXSLT function belongs to exactly one tier — this is the product's spine:

1. **Native in XPath 3.1** — thin `xsl:function` wrappers in the EXSLT namespace,
   with doc comments naming the native equivalent.
2. **Implementable in pure XSLT 3.0** — genuine implementations with correct EXSLT
   semantics.
3. **Not implementable in pure XSLT 3.0** — documented in the matrix; function
   slots raise `xsl:message terminate="yes"`. Never ship a fake implementation.

`docs/COMPATIBILITY.md` is the authoritative registry; keep it in sync with `src/`.

## 5. Testing Requirements

- One golden case minimum per implemented function: happy path **and** one edge case.
- Case layout: `tests/cases/<namespace>/<case>/` with `transform.xsl`,
  `expected.xml` **or** `expected.txt`, optional `input.xml`, and `meta.json`
  (function, namespace URI, tier, source attribution).
- Fixtures imported from upstream corpora must be attributed in
  `tests/ATTRIBUTION.md` (project, license, upstream path). Never fabricate
  attribution.

## 6. Versioning

- Semantic Versioning; tags produced by MinVer once git is initialized.
- Bump `Minor` for new functions/namespaces, `Patch` for bug fixes.
- Record bumps in file headers and `ROADMAP.md`.

## 6a. Documentation Style (Fytala Docs Kit)

Public-facing Markdown follows the Fytala branding contract in
`docs/DOCUMENTATION_STYLE_GUIDE.md` (the FYTALA Documentation Kit, kit v1.2.0,
recorded in `.fytala-docs.json`; canonical manifest in `docs-kit/manifest.json`,
canonical assets under `assets/`, renderer settings in `.vscode/settings.json`
and `.crossnote/`).

**Rules:**
- Canonical docs (`README.md`, root `ROADMAP.md`, `docs/ARCHITECTURE.md`,
  `docs/COMPATIBILITY.md`, `docs/FEATURE_REQUESTS.md`) carry the branded banner
  header with meaningful `alt` text, and repo-owned ones close with the
  `© Fytala` footer. `README.md` additionally carries the verbatim About FYTALA
  statement. Internal notes (`docs/AGENT_HANDOVER.md`, `docs/ADR-*.md`,
  `tests/ATTRIBUTION.md`) may use a compact heading. The training curriculum
  (`training/README.md` and every `training/NN-*/README.md`) is public-facing
  material: same banner and footer contract, and the curriculum index carries
  the About FYTALA statement.
- Do not hand-edit kit-managed files (`docs/DOCUMENTATION_STYLE_GUIDE.md`,
  `docs/DOCUMENTATION_RENDERER_TEST.md`, `docs-kit/manifest.json`, `assets/**`,
  `.crossnote/**`, `.vscode/settings.json`); sync them from the Prime docs-kit
  and keep SHA-256 hashes matching `docs-kit/manifest.json`.
- XSLT- and fixture-specific style rules live in `docs/XSLT_STYLE_GUIDE.md`.
- `tools/check-docs.ps1` section 6 verifies the branding contract (kit marker,
  asset hashes, banners, footers, About FYTALA).

## 7. Documentation Sync Checklist (Mandatory)

After **every** successful implementation step, update the following canonical documents before concluding the step or session:

| File | Purpose | Update when |
|------|---------|-------------|
| `README.md` | Human-facing project overview | Structure, usage, or dependency changes |
| `ROADMAP.md` (root) | Release stages, milestones, known limitations | Stage or milestone change |
| `docs/ARCHITECTURE.md` | Module layout, dependency rules, harness architecture, data flow | New modules, new cases, harness changes |
| `docs/COMPATIBILITY.md` | **Authoritative** per-function matrix | Any function status/tier change, new function |
| `docs/FEATURE_REQUESTS.md` | Living REQ registry | Any REQ status change, new REQ, completed item |
| `docs/AGENT_HANDOVER.md` | Session state and canonical agent context | End of every session |
| `docs/DOCUMENTATION_STYLE_GUIDE.md` | Fytala Docs Kit branding contract (kit-managed — sync from Prime, never hand-edit) | Kit version change, kit-managed asset sync |
| `docs/XSLT_STYLE_GUIDE.md` | XSLT file, function-doc, and test-fixture style rules | Any XSLT/fixture style-rule change |
| `docs/ADR-*.md` | Architecture decision records | Any significant decision (one new file per decision) |
| `tests/ATTRIBUTION.md` | Fixture provenance and divergence log | Any fixture import or divergence note |
| `training/README.md` + `training/NN-*/README.md` | Self-paced curriculum index and session lessons | New session, curriculum structure change |

**Rule:** if a file was modified during the step, its documentation counterpart must be updated in the same step. No exceptions.

### Pre-Handover Checklist

- [ ] `README.md` — repository layout and quick-start are current.
- [ ] `ROADMAP.md` — stage and milestone status reflect reality.
- [ ] `docs/ARCHITECTURE.md` — layout tree and module table match `src/`.
- [ ] `docs/COMPATIBILITY.md` — matrix matches `src/`; test pointers resolve.
- [ ] `docs/FEATURE_REQUESTS.md` — registry and detail sections accurate; "Last updated" date is today.
- [ ] `docs/AGENT_HANDOVER.md` — "What Exists Today" includes every feature/bugfix from the session.
- [ ] `tests/ATTRIBUTION.md` — every imported fixture listed; divergences recorded.
- [ ] `training/` — index and session READMEs branded and current; sessions intact (starter RED, solution GREEN).
- [ ] `pwsh tools/check-docs.ps1 -ProjectPath .` — ALL CHECKS PASSED.

## 8. Git Rules

- Never run `git init`, `git commit`, `git push`, or create remotes unless the
  repository owner explicitly asks.
- Never modify files outside this repository (in particular not in
  `D:/Development/Bosak` or `D:/Development/Bosak.Schema`).

## 9. Related Documents

| Document | Purpose |
|----------|---------|
| `README.md` | Human-readable quick start |
| `ROADMAP.md` | Release stages, milestones, known limitations |
| `docs/ARCHITECTURE.md` | Module layout, dependency rules, harness architecture |
| `docs/COMPATIBILITY.md` | Authoritative per-function compatibility matrix |
| `docs/FEATURE_REQUESTS.md` | Living registry of feature requests |
| `docs/DOCUMENTATION_STYLE_GUIDE.md` | Fytala Docs Kit branding contract (kit-managed) |
| `docs/XSLT_STYLE_GUIDE.md` | XSLT file, function-doc, and test-fixture style rules |
| `docs/AGENT_HANDOVER.md` | Session state for AI agents |

---

*Last updated: 06 October 2026*
