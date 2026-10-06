<div align="center">
  <img src="assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala Bosak.Exslt EXSLT library">
  <br><br>
  <h1>Bosak.Exslt</h1>
  <p>A pure-XSLT 3.0 implementation of EXSLT for the Bosak XPath 3.1 / XSLT 3.0 / XQuery 3.1 engine — and for any other conformant XSLT 3.0 processor</p>
</div>

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

> **Status: pre-release.** The repository skeleton, library modules, and golden-file test corpus are being built out. Semantics may shift until the first tagged release.

---

## What it is

Bosak.Exslt serves three purposes at once:

1. **Legacy-migration aid.** Stylesheets written for XSLT 1.0 + EXSLT (libxslt, Xalan-J, MSXML-era code) can keep calling `math:max`, `str:tokenize`, `set:distinct`, `date:sum`, and friends after an `xsl:import` or `xsl:include` of the relevant module — while the rest of the stylesheet is progressively modernized to XSLT 3.0.
2. **Training and showcase codebase.** Every module is written in standard, vendor-neutral XSLT 3.0 with full documentation. Tier-2 functions are *genuine* implementations (recursive string scanning, duration component arithmetic, character-level URI decoding) — real code worth reading to learn modern XSLT.
3. **Golden-file test corpus ("TDD for XSLT").** Each function is pinned by an executable golden case: input document, transform, expected output, and provenance metadata. The expected outputs are seeded from the libxslt EXSLT test suite (MIT-licensed; see `tests/ATTRIBUTION.md`), so compatibility is measured against the de-facto reference implementation.

## The three-tier compatibility model

EXSLT was designed for XSLT 1.0. Under XSLT 3.0 its functions fall into three tiers:

| Tier | Meaning | Examples |
|------|---------|----------|
| **1. Native in XPath 3.1** | The function exists natively (possibly under another name). We provide a thin `xsl:function` wrapper in the EXSLT namespace so legacy call sites keep working, plus documentation pointing to the native form. | `exsl:node-set` (identity in 3.0), `str:tokenize`, `math:max`/`math:min`, `math:sqrt`, `math:log`, `set:intersection`, `set:difference` |
| **2. Implementable in pure XSLT 3.0** | No native equivalent, but a correct implementation is expressible in standard XSLT 3.0. These are implemented for real — they carry the training value. | `str:padding`, `str:align`, `str:replace`, `str:split`, `str:decode-uri`, `set:distinct`, `set:leading`/`set:trailing`, `exsl:object-type`, most of `date:*` |
| **3. Not implementable in pure XSLT 3.0** | Requires engine support (dynamic XPath evaluation, extension elements). **No fake stubs**: the function slot raises `xsl:message terminate="yes"` with a clear message, and the compatibility matrix marks it as a candidate for a native/commercial engine extension. | `dyn:evaluate` |

The full matrix — every EXSLT function, its tier, status, and test coverage — lives in [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md).

## Usage

Import the whole library:

```xml
<xsl:import href="path/to/Bosak.Exslt/src/exslt.xsl"/>
```

Or include only the namespaces a stylesheet actually uses:

```xml
<xsl:include href="path/to/Bosak.Exslt/src/strings.xsl"/>
<xsl:include href="path/to/Bosak.Exslt/src/math.xsl"/>
```

Then call EXSLT functions as before:

```xml
<xsl:value-of select="math:max(item/price)"/>
<xsl:for-each select="str:tokenize($csv, ',')"> ... </xsl:for-each>
```

For tier-1 functions the documentation comment above each `xsl:function` names the native XPath 3.1 form, so migration can proceed call-site by call-site.

## Learn Bosak XSLT by reading real code

If you are learning XSLT 3.0 (or evaluating the Bosak engine), the tier-2 modules are the reading material:

- `src/strings.xsl` — recursive string scanning (`str:replace`), regex-driven tokenization (`str:split` via `xsl:analyze-string`), character-level percent decoding.
- `src/dates-and-times.xsl` — parsing partial ISO 8601 forms, duration component arithmetic with borrowing/carrying, `xsl:try`/`xsl:catch` error semantics that mirror EXSLT's NaN/`''` contract.
- `src/sets.xsl` — document-order reasoning, node identity (`is`), and a faithful reproduction of libxml2's quirky `set:leading`/`set:trailing` containment rule.

## Running the tests

```bash
dotnet test tests/Bosak.Exslt.Tests/Bosak.Exslt.Tests.csproj
```

The harness discovers every directory under `tests/cases/`, compiles `transform.xsl` with the published Bosak XSLT packages, runs it against `input.xml` (when present), normalizes whitespace, and compares with the golden `expected.xml` / `expected.txt`. See `tests/Bosak.Exslt.Tests/README.md` for the case-layout contract and `tests/ATTRIBUTION.md` for upstream provenance.

## Repository layout

```
src/       Library modules: exslt.xsl (master), exsl.xsl, math.xsl, strings.xsl,
           dates-and-times.xsl, sets.xsl, dynamic.xsl
tests/     Golden-file corpus (tests/cases/) + xUnit runner (tests/Bosak.Exslt.Tests/)
           + fixture provenance (tests/ATTRIBUTION.md)
docs/      Architecture, compatibility matrix, feature registry, style guides, ADRs
assets/    Fytala Docs Kit brand assets (logos, CSS, brand swatches) — synced from
           the Prime docs-kit; integrity pinned in docs-kit/manifest.json
docs-kit/  FYTALA Documentation Kit manifest (.fytala-docs.json records kit v1.2.0)
tools/     check-docs.ps1 documentation hygiene checker
ROADMAP.md Release stages, milestones, known limitations (repository root)
```

## Documentation

| Document | Purpose |
|----------|---------|
| [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) | **Authoritative** per-function matrix: tier, status, native equivalent, test coverage, divergences |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Module layout, dependency rules, harness architecture, data flow |
| [docs/ADR-001-three-tier-compatibility-model.md](docs/ADR-001-three-tier-compatibility-model.md) | The three-tier decision record (ADR) |
| [ROADMAP.md](ROADMAP.md) | Release stages, milestones, known limitations |
| [docs/FEATURE_REQUESTS.md](docs/FEATURE_REQUESTS.md) | Living feature-request registry (REQ-001…006) |
| [docs/DOCUMENTATION_STYLE_GUIDE.md](docs/DOCUMENTATION_STYLE_GUIDE.md) | Fytala Docs Kit branding contract (kit-managed) |
| [docs/XSLT_STYLE_GUIDE.md](docs/XSLT_STYLE_GUIDE.md) | XSLT file, function-doc, and test-fixture style rules |
| [docs/AGENT_HANDOVER.md](docs/AGENT_HANDOVER.md) | Session state for AI agents |
| [tests/ATTRIBUTION.md](tests/ATTRIBUTION.md) | Upstream fixture provenance (libxslt, MIT) |

## Project hygiene

`AGENTS.md` holds the canonical agent conventions (headers, tiers, testing, and the
documentation sync checklist). Before handing over any change, run:

```bash
pwsh tools/check-docs.ps1 -ProjectPath .
```

It verifies file presence, XSLT header markers and well-formedness, documentation
date freshness, cross-references, and golden-case integrity.

## License

Apache-2.0, copyright Fytala (Charles Korthout) — consistent with the core Bosak engine. Imported test fixtures from the libxslt project are MIT-licensed and attributed in `tests/ATTRIBUTION.md`.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt
  </p>
</div>
