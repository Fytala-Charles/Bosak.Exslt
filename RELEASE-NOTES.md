<div align="center">
  <img src="assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala Bosak.Exslt release notes">
  <br><br>
  <h1>Bosak.Exslt — Release notes</h1>
  <p>A pure-XSLT 3.0 implementation of EXSLT for the Bosak XPath 3.1 / XSLT 3.0 engine.</p>
</div>

---

## 0.1.0 — 2026-10-08 (first tagged release)

Legacy-migration aid, training/showcase codebase, and golden-file test corpus —
all three roles fully green on the published Bosak `0.12.3-beta` engine packages.

### Library (`src/`, standard XSLT 3.0 only)

- Seven modules on the three-tier compatibility model (ADR-001): master
  `exslt.xsl` plus `exsl.xsl`, `math.xsl`, `strings.xsl`, `dates-and-times.xsl`,
  `sets.xsl`, `dynamic.xsl`.
- **Tier 1 wrappers** over native XPath 3.1 (`exsl:node-set`, the math suite,
  `str:tokenize`, `set:intersection/difference/has-same-node`), **tier 2 genuine
  implementations** (the entire date module with libxslt-exact component
  normalization, `str:replace/padding/align/split/encode-uri/decode-uri`,
  `set:distinct/leading/trailing`, `exsl:object-type`), and **tier 3 documented
  slots** (`dyn:evaluate` terminates with a clear message — never a fake
  implementation).
- **Package descriptors** (`src/pkg/`): every module also consumable via
  `xsl:use-package` (`urn:fytala:exslt:*`, version 1.0.0); plain files remain
  the primary distribution.

### Golden corpus (`tests/cases/` — 104 cases, 104/104)

- 61 libxslt-derived cases (MIT) + 30 Xalan-J-derived cases from
  `apache/xalan-test` (Apache-2.0) — two legal reference corpora; every
  implemented or wrapper function is golden-pinned, divergences dual-pinned and
  recorded in `tests/ATTRIBUTION.md` and `docs/COMPATIBILITY.md`.

### Training (`training/`)

- Eleven-session self-paced XSLT curriculum + addendum (XSLT's functional
  programming concepts in F#/Haskell terms) and a five-session XPath
  foundations track — all RED→GREEN harnessed (22/22 and 10/10).

### Samples (`samples/`)

- One runnable legacy→modern migration sample per module with
  engine-captured outputs, re-verified by `SamplesTests` on every run.

### Engineering

- CI on every push/PR (`.github/workflows/build.yml`, ubuntu): build
  (TreatWarningsAsErrors) → golden corpus → training → XPath track →
  `tools/check-docs.ps1 -Strict`.
- Six documented Bosak 0.12.3-beta engine quirks worked around conformantly
  and reported as candidate core gaps (see `docs/AGENT_HANDOVER.md` §4),
  including the REQ-004 finding that `xsl:evaluate` exists but never
  propagates a context item — the `dyn:evaluate` wrapper is designed and
  parked on that core fix.

### Known limitations

- `dyn:evaluate` terminates by design until the engine's `xsl:evaluate`
  context-item gap is fixed (REQ-004, decision recorded in ADR-001).
- Engine last-ulp trig results differ across host platforms; affected goldens
  are pinned at 14 decimal places (see `tests/ATTRIBUTION.md`, divergence 4).

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt release notes
  </p>
</div>
