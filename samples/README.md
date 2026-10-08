<div align="center">
  <img src="../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala Bosak.Exslt sample gallery">
  <br><br>
  <h1>Bosak.Exslt — Sample gallery</h1>
  <p>“Learn Bosak XSLT by reading real code”, made runnable: one migration sample per EXSLT module — the XSLT 1.0 + EXSLT legacy form, the idiomatic XSLT 3.0 modern form, and the outputs of both as produced by actually running the transforms.</p>
</div>

---

Every sample lives in `samples/<module>/`:

| File | Purpose |
|------|---------|
| `legacy.xsl` | The task written the way a migrating consumer writes it: XSLT 1.0 idiom, importing the library master `<xsl:import href="../../src/exslt.xsl"/>`. |
| `modern.xsl` | The same task rewritten in idiomatic XSLT 3.0 / XPath 3.1 — **without** the library. This is the migration target. |
| `input.xml` | A small, realistic source document (when the task needs one). |
| `output.legacy.xml` / `output.legacy.txt` | What `legacy.xsl` actually produces on the Bosak engine — captured by running it, never written by hand. |
| `output.modern.xml` / `output.modern.txt` | The same for `modern.xsl`. |

`SamplesTests` (in `tests/Bosak.Exslt.Tests`) reruns both transforms of every sample on every test run and compares against the captured outputs, so a library change that alters any sample breaks the build immediately.

---

## common — re-opening a result tree fragment

`exsl:node-set` was the defining EXSLT workaround: in XSLT 1.0 a variable built
from instructions is an opaque result tree fragment (RTF) that XPath cannot
navigate, so you re-opened it with `exsl:node-set`. The sample collects
back-ordered items into an RTF, then counts and copies them.
[`legacy.xsl`](common/legacy.xsl) · [`modern.xsl`](common/modern.xsl) ·
[`input.xml`](common/input.xml) · [`output.legacy.xml`](common/output.legacy.xml) ·
[`output.modern.xml`](common/output.modern.xml)

The modern version has nothing to re-open: the variable holds an ordinary node
sequence and is selected directly. Note the captured legacy `<type>` — on an
XSLT 3.0 engine the “RTF” is just a document node, so `exsl:object-type`
honestly reports `node-set` (the XSLT 1.0 `RTF` type no longer exists; see
`docs/COMPATIBILITY.md`).

## math — maximum and arg-max over a node-set

`math:max`/`math:highest` find the top price and the order that carries it.
[`legacy.xsl`](math/legacy.xsl) · [`modern.xsl`](math/modern.xsl) ·
[`input.xml`](math/input.xml) · [`output.legacy.xml`](math/output.legacy.xml) ·
[`output.modern.xml`](math/output.modern.xml)

The modern version is `fn:max` plus a direct predicate; untyped attribute values
are converted explicitly with `number()` — a habit worth keeping when you leave
the library behind.

## strings — splitting and replacing

A product catalog keeps keywords in a comma-separated attribute: `str:tokenize`
splits it, `str:replace` normalizes the SKU separator.
[`legacy.xsl`](strings/legacy.xsl) · [`modern.xsl`](strings/modern.xsl) ·
[`input.xml`](strings/input.xml) · [`output.legacy.txt`](strings/output.legacy.txt) ·
[`output.modern.txt`](strings/output.modern.txt)

The modern version is the native `fn:tokenize`/`fn:replace`. (The outputs are
stored as `.txt` because the transform emits one element per input product —
a fragment, not a single document.)

## date — summing ISO 8601 durations

A meeting schedule lists each task with an ISO 8601 duration: `date:sum` totals
them, `date:date` extracts the calendar date.
[`legacy.xsl`](date/legacy.xsl) · [`modern.xsl`](date/modern.xsl) ·
[`input.xml`](date/input.xml) · [`output.legacy.xml`](date/output.legacy.xml) ·
[`output.modern.xml`](date/output.modern.xml)

Two honest engine notes, both recorded in the file headers. First, the legacy
stylesheet declares `version="3.0"`: on Bosak 0.12.3-beta a `version="1.0"`
caller evaluates the library’s typed internals under 1.0 double arithmetic and
every `date:*` function fails with XTTE0570 — so the legacy *idiom* is shown
with a 3.0 version declaration. Second, the modern version cannot lean on
`xs:duration` arithmetic (rejected by this engine build) or
`seconds-from-duration` (returns 0); it parses the fixed `PTnHnM` shape with a
small sample-local function — which is exactly the kind of code `date:sum`
exists to replace.

## sets — distinct values and set difference

Two shelves hold overlapping book categories: `set:distinct` lists every
category once, `set:difference` finds the desk-only ones.
[`legacy.xsl`](sets/legacy.xsl) · [`modern.xsl`](sets/modern.xsl) ·
[`input.xml`](sets/input.xml) · [`output.legacy.xml`](sets/output.legacy.xml) ·
[`output.modern.xml`](sets/output.modern.xml)

The modern version is `fn:distinct-values` and the `except` operator — the
tier-1 wrappers are literal one-liners over these.

## dynamic — the tier-3 wall

An order file lists lines with quantity and price; the legacy stylesheet
evaluates a computed expression per line with `dyn:evaluate`.
[`legacy.xsl`](dynamic/legacy.xsl) · [`modern.xsl`](dynamic/modern.xsl) ·
[`input.xml`](dynamic/input.xml) · [`output.legacy.xml`](dynamic/output.legacy.xml) ·
[`output.modern.xml`](dynamic/output.modern.xml)

`dyn:evaluate` cannot be implemented in pure XSLT 3.0 (tier 3 — see
`docs/COMPATIBILITY.md` and ADR-001). The library slot raises
`xsl:message terminate="yes"`; on Bosak 0.12.3-beta the terminate does not
abort the transform (a known engine quirk), and through the
`TransformToString` API the message itself is swallowed — the call silently
returns the empty sequence. That is why the captured legacy output shows
empty `<line>` elements: the honest result of hitting the tier-3 wall on this
engine. The real migration path is `xsl:evaluate` once the engine’s
context-item gap is fixed (REQ-004, tracked in `docs/FEATURE_REQUESTS.md`);
meanwhile the modern version demonstrates the static-dispatch pattern from
training session 10 — most `dyn:evaluate` call sites evaluate an expression the
stylesheet could have written literally, and here the arithmetic is just
`number(@qty) * number(@price)`.

---

## Honest notes

- **Outputs are harness-captured.** Every `output.*` file was produced by running its transform through the Bosak engine (`Bosak.Xslt` 0.12.3-beta) and is re-verified on every test run by `SamplesTests`. Nothing was written by hand.
- **Determinism.** No sample uses `current-date`, randomness, or any other non-deterministic function.
- **Static site rendering** (a consumer-facing HTML gallery generated from these samples) is deliberately out of scope here and remains future work.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt sample gallery
  </p>
</div>
