<div align="center">
  <img src="assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala Bosak.Exslt roadmap">
  <br><br>
  <h1>Bosak.Exslt — Roadmap</h1>
  <p>Release stages, milestones, and known limitations</p>
</div>

> Versions are produced from git tags by MinVer (git initialized 2026-10-06;
> REQ-006 in `docs/FEATURE_REQUESTS.md`).
>
> Module change-history so far:
> - `src/dates-and-times.xsl` 1.0 → 1.1 (2026-10-06): REQ-008 — seven `xs:date`
>   casts at the `format-date` call sites; the family moved from always-empty
>   to correct EXSLT answers. Bug fix, not a divergence.
> - `src/dates-and-times.xsl` 1.2 → 1.3 (2026-10-06): REQ-001 batch 3 — full
>   rewrite on the libexslt `date.c` algorithms; the 26-case libxslt date
>   battery passes verbatim.

---

## 1. Release Stages

### Stage 1 — Skeleton and common/math/strings/sets (current)

- [x] Repository skeleton with house conventions (headers, docs, license).
- [x] `exsl`, `math`, `strings`, `sets` modules covering every spec function in
      those namespaces (wrappers where native, genuine implementations elsewhere).
- [x] Golden-file harness (`tests/Bosak.Exslt.Tests`) running on the published
      Bosak.Xslt packages.
- [x] Starter golden corpus (15 libxslt-derived cases; 22 total after 7
      hand-written REQ-008 date cases) imported/written per
      (`tests/ATTRIBUTION.md`) — the full suite is green against the published
      Bosak.Xslt 0.12.3-beta packages.
- [x] Full import of the deterministic, license-compatible remainder of the
      libxslt EXSLT corpus — **done 2026-10-08 (REQ-001 Implemented)**: 61
      libxslt-derived cases total (46 conversions from batches 1–3, all matched
      upstream verbatim; 5 deterministic cases skip-recorded in
      `tests/ATTRIBUTION.md`).
      *(REQ-001)*
- [x] Xalan-J EXSLT tests as the second legal corpus source — **done 2026-10-08
      (REQ-002 Implemented)**: 30 cases from `apache/xalan-test` (Apache-2.0;
      22 matched upstream verbatim, 8 with documented adaptations; 10 upstream
      cases skip-recorded). Divergences between the two reference corpora are
      pinned by dual cases and recorded in `tests/ATTRIBUTION.md` +
      `docs/COMPATIBILITY.md` (divergences 5–6). Source: `tests/exslt/` +
      `tests/exslt-gold/` in `apache/xalan-test`.
      *(REQ-002)*
- [x] Hand-written edge-case goldens for functions without upstream coverage
      — **done 2026-10-08 (REQ-001 batch 4)**: six engine-verified cases
      (`math/sqrt.1`, `math/power.1`, `math/constant.1`, `math/log-exp.1`,
      `math/trig.1`, `sets/intersection.1`); the earlier edge list
      (`str:decode-uri`/`str:encode-uri`, `set:trailing`, `math:lowest`,
      `date:seconds`, `date:sum`, `date:difference`) is covered by the
      converted upstream cases. Corpus 73/73.
- [ ] Training curriculum: eleven self-paced branded sessions under `training/`,
      one XSLT 3.0 technique per session taught test-first on an EXSLT function,
      with the independent RED/GREEN harness in `training/TrainingTests/` —
      sessions 00–11 complete 2026-10-06 (REQ-007 Implemented), plus a
      lesson-only addendum comparing XSLT with functional programming
      languages (F#, Haskell). *(REQ-007)*

### Stage 2 — Dates and times hardening

The `date` module is the largest surface and the most semantics-dense:

- [ ] Decide, per function and *documented in `docs/COMPATIBILITY.md`*, where
      calendar arithmetic (`xs:dateTime + xs:duration`) and libxslt component
      normalization must diverge; pin each decision with a golden case.
- [ ] Non-deterministic functions (`date:date-time`, `date:date`, `date:time`,
      `date:seconds` on current time) get schema-only cases or harness support for
      pattern assertions instead of goldens.
- [ ] Year < 1 and year > 9999 handling aligned with whatever representation the
      Bosak engine settles on (see Bosak core known limitations).

### Stage 3 — The `dyn:evaluate` question

**Decision recorded 2026-10-08 (REQ-004, ADR-001 amendment):** `dyn:evaluate`
becomes a thin wrapper over standard `xsl:evaluate` — no native/commercial
engine function is needed; the context written below is kept as history.

Probe of Bosak 0.12.3-beta (2026-10-08) found `xsl:evaluate` already present in
the engine: static-string evaluation, QName-map `with-params`, and `as` coercion
work. Two conformance gaps block the wrapper (both reported against core
REQ-121):

- [ ] Engine propagates the context item into `xsl:evaluate` (today any
      expression touching `.` fails `XPDY0002` — even `name(/*)` at document
      level). **The one hard blocker.**
- [ ] `with-params-names` binds its variables (today `XTDE3160` — avoidable by
      using QName-map `with-params` only).

When the first gap lands, swap the `src/dynamic.xsl` slot for the wrapper
(design in the ADR-001 amendment), add golden cases, and re-tier the matrix row
from tier 3 to tier 2. Until then the slot keeps its terminating message.

### Stage 4 — Packaging and release

- [x] `xsl:package` per namespace module — **done 2026-10-08 (REQ-003
      Implemented)**: six package descriptors in `src/pkg/`
      (`urn:fytala:exslt:{common,math,strings,date,sets,dynamic}`,
      `package-version="1.0.0"`) wrap the plain modules via `xsl:include` +
      explicit-names `xsl:expose`; package-mode golden case
      `tests/cases/packages/use-package.1` proves cross-package calls with a
      prefix version range. Plain import/include files remain the primary
      distribution. Known engine deviation: intra-package helper calls resolve
      against the public-exposure table only, so strings/date internals are
      exposed `public` and marked as implementation details (candidate core
      gap, report with the REQ-004 findings). Package location is host-API
      (`XsltFunctionLibrary.RegisterPackage`) — implementation-defined per the
      spec.
      *(REQ-003)*
- [ ] First tagged release (0.1.0) once the corpus covers every implemented
      function and `dotnet test` is green in CI.
- [ ] Publish as a Fytala open-source artifact next to the Bosak engine packages.
- [ ] Static-HTML rendering of the sample gallery — the `samples/` tree and
      branded `samples/README.md` gallery are live (REQ-005 Implemented
      2026-10-08); a site generator on top is future work. *(REQ-005 follow-up)*

## 2. Milestones

| Milestone | Contents | Status |
|-----------|----------|--------|
| M0 — Skeleton | Repo conventions, headers, license, docs | Done (2026-10-06) |
| M1 — Library core | 7 namespace modules + master on the three-tier model | Done (2026-10-06) |
| M2 — Golden harness | xUnit harness on published Bosak.Xslt packages | Done (2026-10-06) |
| M3 — Starter corpus | 15 libxslt-derived cases, 15/15 green | Done (2026-10-06) |
| M3a — REQ-008 date goldens | 7 hand-written cases for the repaired `format-date` family; corpus 22/22 green | Done (2026-10-06) |
| M4 — Full corpus | Remaining deterministic libxslt cases + Xalan-J supplements; edge-case goldens for uncovered functions | Done 2026-10-08 (REQ-001: 61 libxslt-derived cases + 6 hand-written gap cases; REQ-002: 30 Xalan-J cases from apache/xalan-test; REQ-003: +1 package-mode case — corpus 104/104, all Implemented) |
| M5 — Date hardening | Divergence decisions pinned with goldens; non-deterministic case support | Pending (divergence pinning done 2026-10-06 in REQ-001 batch 3 + `month-name.1` re-golden; non-deterministic `current.xsl` skip-recorded; year-range item still awaits the Bosak engine representation decision) |
| M6 — Release | First tag (0.1.0), CI green, artifact published | Pending (CI workflow live 2026-10-08 per REQ-006; first tag + artifact publish open) |
| M7 — Training curriculum | 11 self-paced branded sessions with RED→GREEN harness; sessions 00–11 + addendum complete | Done (2026-10-06, REQ-007) |
| M8 — Sample gallery | Runnable legacy/modern pair per module with harness-captured outputs; branded gallery README; SamplesTests in the harness | Done (2026-10-08, REQ-005; static-HTML rendering follow-up) |

## 3. Known Limitations

### Engine compatibility (Bosak 0.12.3-beta)

Limitations hit while building the library, and how the modules work around them
(all workarounds are standards-compliant XSLT 3.0):

- `fn:tokenize` retains zero-length tokens; the library filters them out in
  `str:make-tokens` (which is the EXSLT-required behavior anyway). Candidate core
  bug to report upstream.
- `xsl:analyze-string` content instructions are not executed when the stylesheet
  runs them from inside an `xsl:function` body (they serialize literally), so
  `str:split` is built on `fn:tokenize` instead. `date:_parse-duration` does use
  `xsl:analyze-string`, but only with `select`-valued `matching-substring`, which
  works. Candidate core bug to report upstream.
- FLWOR expressions support only a single `for`/`let` clause, so multi-clause
  expressions in the library are flattened. Candidate core gap to report upstream.

### Product

- `dyn:evaluate` keeps its terminating slot (tier 3) until the engine's
  `xsl:evaluate` context-item gap is fixed; the Stage-3 decision (wrapper over
  standard `xsl:evaluate`, no commercial function) was recorded 2026-10-08.
- Git initialized 2026-10-06 (REQ-006 git part done); CI workflow added
  2026-10-08 — `.github/workflows/build.yml` (ubuntu-latest) gates build,
  all three test projects, and `check-docs.ps1 -Strict` on push/PR
  (REQ-006 Implemented). First tag still pending (MinVer activates from tags).

## 4. Relation to REQ-121

Bosak.Exslt is the reference implementation artifact of REQ-121 (EXSLT /
legacy-migration support) from the Bosak core roadmap: the core engine stays
standards-only, while EXSLT compatibility — where it is possible in standard XSLT —
lives here, in the open, with an executable compatibility contract.

---

*Last updated: 2026-10-08*

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Roadmap
  </p>
</div>
