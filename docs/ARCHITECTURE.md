<div align="center">
  <img src="../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala Bosak.Exslt architecture">
  <br><br>
  <h1>Bosak.Exslt — Architecture</h1>
  <p>Module layout, dependency rules, harness architecture, data flow</p>
</div>

> **Status:** pre-release skeleton, fully green — 7 library modules on the three-tier
> compatibility model, golden-file harness 15/15 against published Bosak.Xslt
> 0.12.3-beta packages. The three-tier model itself is the load-bearing architectural
> decision; it is recorded in [ADR-001](./ADR-001-three-tier-compatibility-model.md).

---

## 1. Overview

Bosak.Exslt is a **pure-XSLT 3.0 implementation of EXSLT** for the Bosak XPath 3.1 /
XSLT 3.0 engine — and for any other conformant XSLT 3.0 processor. It serves three
roles at once, and every architectural choice serves at least one of them:

| Role | What it demands |
|------|-----------------|
| **Legacy-migration aid** | Legacy XSLT 1.0 + EXSLT call sites (`math:max`, `str:tokenize`, `set:distinct`, `date:*`) must keep working via `xsl:import`/`xsl:include`, while doc comments point call sites at their native XPath 3.1 equivalents for progressive modernization. |
| **Training/showcase codebase** | Tier-2 functions must be *genuine* implementations in readable, standard, vendor-neutral XSLT 3.0 — recursive string scanning, duration component arithmetic, document-order reasoning. No processor conditionals, no vendor extensions. |
| **Golden-file test corpus** | Every function is pinned by an executable golden: input document, transform, expected output, provenance metadata. Expected outputs are seeded from the libxslt EXSLT suite (MIT; see `tests/ATTRIBUTION.md`), so compatibility is measured against the de-facto reference implementation. |

The product spine is the **three-tier compatibility model**: every EXSLT function
belongs to exactly one tier — (1) thin wrapper over native XPath 3.1, (2) genuine
pure-XSLT implementation, (3) documented-only with a terminating `xsl:message` slot.
See ADR-001 for the decision record and `docs/COMPATIBILITY.md` for the per-function
matrix.

## 2. Repository Layout

```
Bosak.Exslt/
├── src/                    Library modules — the product (pure XSLT 3.0)
│   ├── exslt.xsl           Master: includes every module; import this for the whole library
│   ├── exsl.xsl            exsl  — http://exslt.org/common
│   ├── math.xsl            math  — http://exslt.org/math
│   ├── strings.xsl         str   — http://exslt.org/strings
│   ├── dates-and-times.xsl date  — http://exslt.org/dates-and-times
│   ├── sets.xsl            set   — http://exslt.org/sets
│   └── dynamic.xsl         dyn   — http://exslt.org/dynamic (tier-3 slots only)
├── tests/
│   ├── cases/<ns>/<case>/  Golden corpus: transform.xsl + expected.xml|expected.txt
│   │                       + meta.json (+ input.xml); 15 cases (math 3, strings 5,
│   │                       sets 3, common 2, date 2)
│   ├── Bosak.Exslt.Tests/  xUnit harness (net10.0) on published Bosak.Xslt packages
│   ├── ATTRIBUTION.md      Upstream provenance (libxslt, MIT) + divergence log
├── training/
│   ├── README.md           Curriculum index (branded, self-paced; About FYTALA)
│   ├── 00-setup/           Setup session: install guide, check-setup.ps1
│   │                       configuration check, VS Code mini-guide (no exercise)
│   ├── NN-slug/            Session: branded lesson README + starter/ + solution/
│   │                       + input.xml + case/ (meta.json + expected.xml|expected.txt)
│   ├── xpath/              XPath foundations track (parallel curriculum; same
│   │   │                   RED→GREEN method, exercises are raw .xpath expressions)
│   │   ├── README.md       Track index
│   │   ├── NN-slug/        XPath session: lesson + exercise.xpath + case/
│   │   └── XPathTrainingTests/  xUnit harness on published Bosak.XPath.Api
│   └── TrainingTests/      xUnit harness: Solution_matches_golden + Starter_differs_from_golden per session
├── docs/                   Architecture, compatibility matrix, feature registry,
│                           style guides, ADRs, agent handover
├── assets/                 Fytala Docs Kit brand assets (logos, CSS, brand swatches) —
│                           synced from the Prime docs-kit; hash-pinned by docs-kit/manifest.json
├── docs-kit/               FYTALA Documentation Kit manifest (asset integrity hashes)
├── .fytala-docs.json       Kit adoption marker (kit v1.2.0)
├── .crossnote/ + .vscode/  Markdown renderer integration (kit-managed)
├── tools/                  check-docs.ps1 documentation hygiene + branding checker
├── ROADMAP.md              Release stages, milestones, known limitations (root)
└── LICENSE                 Apache-2.0, copyright Fytala (Charles Korthout)
```

## 3. Module Layout

One module per EXSLT namespace, plus a master that includes all. `src/` contains no
C# and no buildable project — the modules are data consumed by any XSLT 3.0
processor.

| Module | Namespace | Contents | Composition |
|--------|-----------|----------|-------------|
| `exslt.xsl` | — (master) | `xsl:include` of every module | — |
| `exsl.xsl` | `http://exslt.org/common` | `node-set` (wrapper), `object-type` (tier 2) | 1 × tier 1, 1 × tier 2 |
| `math.xsl` | `http://exslt.org/math` | `min`, `max`, `highest`, `lowest`, `sqrt`, `power`, `constant`, `log`, trig | all tier 1 |
| `strings.xsl` | `http://exslt.org/strings` | `tokenize` (wrapper); `replace`, `padding`, `align`, `split`, `encode-uri`, `decode-uri` | 1 × tier 1, 6 × tier 2 |
| `dates-and-times.xsl` | `http://exslt.org/dates-and-times` | full `date:*` surface (largest module) | all tier 2 |
| `sets.xsl` | `http://exslt.org/sets` | `intersection`, `difference`, `has-same-node` (wrappers); `distinct`, `leading`, `trailing` | 3 × tier 1, 3 × tier 2 |
| `dynamic.xsl` | `http://exslt.org/dynamic` | `evaluate` slot → terminating `xsl:message` | tier 3 |

Tier totals: 7 tier-1 wrappers, 20+ tier-2 genuine implementations, 1 tier-3
documented slot. `docs/COMPATIBILITY.md` is the authoritative per-function registry
and must stay in sync with `src/`.

## 4. Dependency Rules

| Layer | May depend on | Must not depend on |
|-------|---------------|--------------------|
| `src/*.xsl` (the library) | Standard XSLT 3.0 / XPath 3.1 + F&O only | Vendor extensions, processor conditionals, any engine-specific feature, any C#/package reference |
| `tests/cases/` | `src/*.xsl` via relative `xsl:include` (`../../../src/<module>.xsl`) | Anything outside the repo |
| `tests/Bosak.Exslt.Tests` (harness) | Published **Bosak.Xslt** and **Bosak.XPath.Providers** NuGet packages only (currently 0.12.3-beta); copies cases and `src/*.xsl` to its output via `<None Include>` links | Project references into `src/` (there is no project there), un-published engine builds |
| `training/*/starter/`, `training/*/solution/*.xsl` (training material) | Standard XSLT 3.0 / XPath 3.1 + F&O only; a session's own `input.xml` + `case/` files | `src/*.xsl` via `xsl:include`/`xsl:import` — training is a sandbox; the library appears only as read-along reference after the learner's attempt |
| `training/xpath/*/starter/`, `training/xpath/*/solution/exercise.xpath` (XPath training material) | Pure XPath 3.1 + F&O only; a session's own `input.xml` + `case/` files | XSLT instructions, extension functions, `src/*.xsl` |
| `training/TrainingTests` (training harness) | Published **Bosak.Xslt** and **Bosak.XPath.Providers** NuGet packages only (same versions as the golden harness); copies `training/NN-*/` sessions to its output | `tests/cases/`, `src/` — it copies nothing from either tree |
| `training/xpath/XPathTrainingTests` (XPath training harness) | Published **Bosak.XPath.Api**, **Bosak.XPath.Core**, and **Bosak.XPath.Providers** packages only; copies `training/xpath/NN-*/` sessions to its output | `src/`, `tests/` — it copies nothing from either tree |

Rationale: the library must run unmodified on any conformant XSLT 3.0 processor —
that *is* the compatibility claim. The harness, conversely, must run against the
**published** Bosak packages so green test runs certify compatibility with what
consumers actually install, not with a local engine build.

## 5. Harness Architecture

`tests/Bosak.Exslt.Tests` (xUnit, net10.0, one test class) implements the
golden-file pattern:

1. **Case discovery** — enumerates every directory under `cases/` that contains a
   `transform.xsl`; the relative path (e.g. `math/min.1`) becomes the xUnit display
   name. Adding a case directory is the only step needed to add a test.
2. **Compilation** — `transform.xsl` is read as text and compiled with
   `new XsltCompiler().Compile(xsl, new Uri(transformPath).AbsoluteUri)`. Passing the
   absolute base URI is what lets each case's `xsl:include href="../../../src/<module>.xsl"`
   resolve the library from its copied location in the test output.
3. **Execution** — the transform runs against `input.xml` when present (wrapped in a
   `XDocumentNode`), else an empty document, producing a string via
   `TransformToString`.
4. **Normalization and comparison** —
   - XML goldens (`expected.xml`): both sides are parsed with insignificant
     whitespace discarded (`XDocument.Parse(..., LoadOptions.None)`) and re-serialized
     without formatting (`ToString(DisableFormatting)`); canonical strings must match.
   - Text goldens (`expected.txt`): both sides are reduced to their
     whitespace-separated token stream, so line endings and indentation never flake.

**Training harness.** `training/TrainingTests` (xUnit, net10.0) reuses the pattern
above against a second, independent corpus. A *session* is any `training/NN-*`
directory holding `case/meta.json` (the same marker `tools/check-docs.ps1` uses for
integrity checks). Two tests per session:

- `Solution_matches_golden` — the session's `solution/transform.xsl` must match
  `case/expected.xml`/`expected.txt`; this guards the teaching material itself.
- `Starter_differs_from_golden` — the session's `starter/transform.xsl` (which must compile and
  run) must **not** match the golden; a starter that already solves the exercise
  fails the build, protecting the lesson for the next learner.

Session transforms are self-contained (never include `src/`), so the training
harness copies no library files — unlike the golden harness, whose `src/*.xsl`
copy-link exists precisely so case `xsl:include` hrefs resolve.

**XPath training harness.** `training/xpath/XPathTrainingTests` applies the same
contract to the XPath foundations track, where the artifact under test is a raw
expression: a session is `training/xpath/NN-*` with `case/meta.json`; the harness
evaluates `starter|solution/exercise.xpath` against the session's `input.xml`
through `XPath31Expression.Compile(...).Evaluate(...)` (published
**Bosak.XPath.Api**) and compares the rendered result with `case/expected.txt` as
a token stream. Rendering follows the track README: atomic values as themselves,
sequences item-by-item joined with ` | `, the empty sequence as `()`. The
`Starter_differs_from_golden` test again fails the build if a starter stops being a stub.

## 6. Data Flow

```
tests/cases/<ns>/<case>/
    transform.xsl ──xsl:include──► ../../../src/<module>.xsl  (library)
         │                              │
         ▼                              ▼
   XsltCompiler.Compile(xsl, baseUri)   (pure XSLT 3.0, standard only)
         │
         ▼
   XDocumentNode(input.xml | empty doc)
         │
         ▼
   TransformToString ──► actual string
         │
         ▼
   normalize ──┬── XML:  whitespace-insensitive canonical re-serialization
               └── text: whitespace-token stream
         │
         ▼
   expected.xml / expected.txt  ──► xUnit assertion
```

A case fails loudly and diffably: the canonicalized expected and actual are both
printed on mismatch.

## 7. Key Design Decisions

Minor, reversible decisions live here; the cross-cutting three-tier decision is
ADR-001. ADR numbering starts at 000 (template) and increments without reuse.

| Decision | Rationale | Consequence |
|----------|-----------|-------------|
| One module per EXSLT namespace | Matches how legacy stylesheets include EXSLT; keeps each file readable; mirrors libxslt's module split | `exslt.xsl` master exists only for whole-library imports |
| Library files carry no `.csproj`; `src/` is pure data | The product is stylesheets, not an assembly; consumers import/include the files | Harness consumes `src/*.xsl` via `<None Include>` copy-links, not project references |
| Tier-1 wrappers return *exact* EXSLT shapes (e.g. `str:tokenize` returns `token` elements), not native shapes | Legacy call sites must keep working unchanged | Migration aid lives in doc comments naming the native form, not in return-shape changes |
| Goldens normalize whitespace rather than byte-compare | XML layout (indentation, line endings) is not part of EXSLT semantics; byte-compare would flake across serializers | `expected.xml` is compared after canonical re-serialization; text as token stream |
| Case provenance lives in `meta.json` beside each case, mirrored in `tests/ATTRIBUTION.md` | Per-case provenance survives case moves/copies; the attribution file carries licenses and the verbatim upstream notice | `tools/check-docs.ps1` validates `meta.json` parses and carries a `source` field |
| Deliberate libxslt divergences are recorded in `docs/COMPATIBILITY.md`, `tests/ATTRIBUTION.md`, and the case's `meta.json` notes — never silently | The corpus claims compatibility *measured against the reference implementation*; silent divergence would void that claim | A golden may be re-goldened only together with the divergence records |

---

*Last updated: 2026-10-06*

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Architecture
  </p>
</div>
