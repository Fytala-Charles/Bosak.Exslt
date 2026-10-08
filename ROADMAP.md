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
- [ ] Full import of the deterministic, license-compatible remainder of the
      libxslt EXSLT corpus (math, strings, sets, common, date directories) and, as a
      second legal source, Xalan-J's EXSLT tests (Apache-2.0) for coverage of cases
      libxslt does not exercise. *(REQ-001, REQ-002)*
- [ ] Hand-written edge-case goldens for `str:decode-uri`, `str:encode-uri`,
      `set:trailing`, `math:lowest`, `math:constant`, `date:seconds`, `date:sum`,
      `date:difference` (functions without upstream coverage yet).
- [ ] Training curriculum: eleven self-paced branded sessions under `training/`,
      one XSLT 3.0 technique per session taught test-first on an EXSLT function,
      with the independent RED/GREEN harness in `training/TrainingTests/` —
      sessions 00–10 scaffolded 2026-10-06, plus a lesson-only addendum
      comparing XSLT with functional programming languages (F#, Haskell).
      *(REQ-007)*

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

`dyn:evaluate` cannot be implemented in pure XSLT 3.0 (tier 3; see
`docs/ADR-001-three-tier-compatibility-model.md`). Open decision:

- [ ] Bosak core grows a native (possibly commercial-tier) dynamic evaluation
      function, and Bosak.Exslt's `dynamic.xsl` becomes a thin wrapper over it
      (tracked as REQ-004 in `docs/FEATURE_REQUESTS.md`); or
- [ ] Bosak.Exslt documents `dyn:evaluate` as permanently unavailable and provides a
      migration guide (typically: replace dynamic evaluation with `xsl:evaluate` —
      the XSLT 3.0 feature that supersedes EXSLT dynamic — once Bosak supports
      `xsl:evaluate`).

This decision is tracked against REQ-121 (EXSLT support / legacy migration) in the
Bosak core feature registry; `docs/COMPATIBILITY.md` records the interim
terminating-message behavior.

### Stage 4 — Packaging and release

- [ ] Evaluate `xsl:package` so each namespace module can ship as a versioned
      package consumable via `xsl:use-package`, alongside the plain
      import/include files (which remain the primary distribution). *(REQ-003)*
- [ ] First tagged release (0.1.0) once the corpus covers every implemented
      function and `dotnet test` is green in CI.
- [ ] Publish as a Fytala open-source artifact next to the Bosak engine packages.

## 2. Milestones

| Milestone | Contents | Status |
|-----------|----------|--------|
| M0 — Skeleton | Repo conventions, headers, license, docs | Done (2026-10-06) |
| M1 — Library core | 7 namespace modules + master on the three-tier model | Done (2026-10-06) |
| M2 — Golden harness | xUnit harness on published Bosak.Xslt packages | Done (2026-10-06) |
| M3 — Starter corpus | 15 libxslt-derived cases, 15/15 green | Done (2026-10-06) |
| M3a — REQ-008 date goldens | 7 hand-written cases for the repaired `format-date` family; corpus 22/22 green | Done (2026-10-06) |
| M4 — Full corpus | Remaining deterministic libxslt cases + Xalan-J supplements; edge-case goldens for uncovered functions | Pending (REQ-001, REQ-002) |
| M5 — Date hardening | Divergence decisions pinned with goldens; non-deterministic case support | Pending |
| M6 — Release | First tag (0.1.0), CI green, artifact published | Pending (REQ-006) |
| M7 — Training curriculum | 11 self-paced branded sessions with RED→GREEN harness; sessions 00–10 scaffolded | In Progress (REQ-007) |

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

- `dyn:evaluate` is unavailable by design (tier 3) until the host-backed decision
  (Stage 3) lands.
- Several date functions have no golden coverage yet; their semantics are
  implemented but not pinned by executable evidence (see §1 Stage 1 checklist).
- Git initialized 2026-10-06 (REQ-006 git part done); CI workflow and first tag
  still pending.

## 4. Relation to REQ-121

Bosak.Exslt is the reference implementation artifact of REQ-121 (EXSLT /
legacy-migration support) from the Bosak core roadmap: the core engine stays
standards-only, while EXSLT compatibility — where it is possible in standard XSLT —
lives here, in the open, with an executable compatibility contract.

---

*Last updated: 2026-10-06*

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Roadmap
  </p>
</div>
