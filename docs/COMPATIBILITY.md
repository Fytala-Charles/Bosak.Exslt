<div align="center">
  <img src="../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala EXSLT compatibility matrix">
  <br><br>
  <h1>EXSLT Compatibility Matrix</h1>
  <p>Every EXSLT function across the seven namespaces, classified per the
  <a href="../README.md">three-tier compatibility model</a></p>
</div>

Status values:

- **implemented** — genuine pure-XSLT 3.0 implementation (tier 2)
- **wrapper** — thin `xsl:function` wrapper over native XPath 3.1 (tier 1)
- **documented** — not implementable in pure XSLT 3.0; slot raises a terminating
  `xsl:message` (tier 3) or the construct is superseded by an XSLT 3.0 feature

Namespace URIs: `exsl` = `http://exslt.org/common`, `math` = `http://exslt.org/math`,
`str` = `http://exslt.org/strings`, `date` = `http://exslt.org/dates-and-times`,
`set` = `http://exslt.org/sets`, `dyn` = `http://exslt.org/dynamic`,
`func` = `http://exslt.org/functions`.

## exsl — Common (`src/exsl.xsl`)

| Function | Tier | Status | Native equivalent / notes | Tests |
|----------|------|--------|---------------------------|-------|
| `exsl:node-set` | 1 | wrapper | Identity in XSLT 3.0 — variables already hold node sequences. `exsl:node-set($x)` ≡ `$x`. | `cases/common/node-set.1` |
| `exsl:object-type` | 2 | implemented | Returns `string`/`number`/`boolean`/`node-set`/`external`. XSLT 3.0 cannot distinguish a result-tree fragment from any other document node, so the XSLT 1.0 answer `RTF` is reported as `node-set` (documented divergence from libxslt). Maps, arrays, and functions report as `external`. | `cases/common/object-type.1` |
| `exsl:document` | 3 | documented | Extension *element* for multiple output documents. Superseded by `xsl:result-document` (XSLT 2.0+). Not a function slot; use the native element. | — |

## math — Math (`src/math.xsl`)

| Function | Tier | Status | Native equivalent / notes | Tests |
|----------|------|--------|---------------------------|-------|
| `math:min` | 1 | wrapper | `min($nodes ! number(.))` | `cases/math/min.1`, `cases/math/min.2` |
| `math:max` | 1 | wrapper | `max($nodes ! number(.))` | `cases/math/max.1`, `cases/math/max.2` |
| `math:highest` | 1 | wrapper | `$nodes[number(.) eq max($nodes ! number(.))]` | `cases/math/highest.1`, `cases/math/highest.2`, `cases/math/highest.5` |
| `math:lowest` | 1 | wrapper | `$nodes[number(.) eq min($nodes ! number(.))]` | `cases/math/lowest.1`, `cases/math/lowest.2` |
| `math:sqrt` | 1 | wrapper | XPath 3.1 `math:sqrt` | `cases/math/sqrt.1` |
| `math:power` | 1 | wrapper | `math:exp($e * math:log($b))`. Diverges from libxslt `pow()` for negative bases (NaN here) and `power(0, 0)`; documented — pinned by `cases/math/power.1`. | `cases/math/power.1` |
| `math:constant` | 1 | wrapper | `math:pi()`, `math:exp`, `math:log`, `math:sqrt` | `cases/math/constant.1` |
| `math:log` | 1 | wrapper | XPath 3.1 `math:log` | `cases/math/log-exp.1` |
| `math:sin` / `math:cos` / `math:tan` | 1 | wrapper | XPath 3.1 `math:sin` etc. | `cases/math/trig.1` |
| `math:asin` / `math:acos` / `math:atan` / `math:atan2` | 1 | wrapper | XPath 3.1 `math:asin` etc. | `cases/math/trig.1` |
| `math:exp` | 1 | wrapper | XPath 3.1 `math:exp` | `cases/math/log-exp.1` |

## str — Strings (`src/strings.xsl`)

| Function | Tier | Status | Native equivalent / notes | Tests |
|----------|------|--------|---------------------------|-------|
| `str:tokenize` | 1 | wrapper | Built on `fn:tokenize`; delimiters are *literal characters* (escaped to regex), unlike `fn:tokenize`. Returns `token` elements per the EXSLT spec and libxslt — when migrating, prefer `fn:tokenize` (returns strings). | `cases/strings/tokenize.1` |
| `str:replace` | 2 | implemented | No native equivalent. One-pass, left-to-right scan; `$from` entries map by position to `$to` entries (missing → `''`); empty search string inserts between characters. Search strings are literal. | `cases/strings/replace.1` |
| `str:padding` | 2 | implemented | Repeat/truncate padding to exactly `$length` characters. | `cases/strings/padding.1` |
| `str:align` | 2 | implemented | `left` (default) / `right` / `center`; truncates the string when longer than the padding. | `cases/strings/align.1` |
| `str:split` | 2 | implemented | Split on a regex `$pattern` (built on `fn:tokenize`); returns `token` elements; empty tokens dropped; `$pattern = ''` splits into characters; no `$pattern` splits on whitespace runs. | `cases/strings/split.1` |
| `str:encode-uri` | 2 | implemented | `$encode-reserved`: `fn:encode-for-uri`, then restore `%21 %2A %27 %28 %29 %40` → `! * ' ( ) @` — libxslt's full mode leaves the RFC 2396 mark characters and `@` (a hardcoded libxml2 `xmlURIEscapeStr` exception) unencoded. Else `fn:iri-to-uri` with every literal `%` pre-escaped to `%25` (`iri-to-uri` leaves `%` alone; libxslt escapes it). Exact: `encode-for-uri` always encodes `%` itself, so the restore tokens can only come from the literal characters. | `cases/strings/uri` |
| `str:decode-uri` | 2 | implemented | No native XPath 3.1 decode. Scans for maximal runs of consecutive `%XX` escapes and decodes each run as a UTF-8 byte sequence (matching libxslt, so `decode-uri(encode-uri(x))` round-trips non-ASCII); a `%` not followed by two hex digits passes through. Malformed UTF-8 inside a run (stray continuation byte, bad/truncated sequence) is **not** an error: the offending byte is passed through as a raw codepoint and decoding resumes at the next byte (structural validation only, no overlong/surrogate check). | `cases/strings/uri` |

## date — Dates and Times (`src/dates-and-times.xsl`)

All functions take an ISO 8601 string (dateTime, date, gYearMonth, gYear, gMonthDay,
gMonth, gDay, or time), returning `NaN`/`''` on invalid input exactly as the EXSLT
spec demands. The module is a pure-XSLT port of the libexslt `date.c` algorithms
(v1.3, 2026-10-06): regex parsing and integer/decimal arithmetic with C-like
truncation — no `xs:date`/`xs:dateTime` casts and no `format-date` on the
golden-tested paths, so libxslt's exact output (including number formatting and
BC-year handling) is reproduced.

The 14 libxslt *extraction battery* cases — `cases/date/{date.1, date.2,
datetime.1, datetime.2, gday.1, gday.2, gmonth.1, gmonth.2, gmonthday.1,
gmonthday.2, gyear.1, gyear.2, gyearmonth.1, gyearmonth.2}` — each call all
sixteen extraction functions against one input type; they are referenced as
"battery" below.

> **REQ-008 repair (2026-10-06), superseded by the v1.3 rewrite:** the seven
> `format-date` call sites originally handed `date:_as-datetime`'s
> `xs:dateTime` to a parameter typed `xs:date?`; the surrounding `try`/`catch`
> masked the resulting `XPTY0004`, so all seven returned `''` for every valid
> date. The repair cast the argument (`xs:date(substring(string(…), 1, 10))`);
> the v1.3 rewrite then replaced the whole cast-based implementation with the
> libexslt port described above, so extraction functions now follow libxslt's
> per-type validity contracts exactly (e.g. `date:month-in-year` accepts
> gMonthDay; `date:week-in-year` accepts only dateTime/date). Bug fix, not a
> divergence.

| Function | Tier | Status | Notes | Tests |
|----------|------|--------|-------|-------|
| `date:date-time` | 2 | implemented | Current date/time as `YYYY-MM-DDThh:mm:ss`. Non-deterministic; not golden-tested (libxslt's `current.xsl` is skipped for the same reason — see `tests/ATTRIBUTION.md`). | — |
| `date:date` | 2 | implemented | Date portion of argument (default: today). | battery |
| `date:time` | 2 | implemented | Time portion of argument (default: now). | `cases/date/time.1`, `cases/date/time.2`, battery |
| `date:year` | 2 | implemented | | battery |
| `date:leap-year` | 2 | implemented | Returns the strings `'true'`/`'false'`/`'NaN'` (libxslt XPath 1.0 number output), not `xs:boolean`. | battery |
| `date:month-in-year` | 2 | implemented | Accepts gMonthDay per libxslt's type contract. | battery |
| `date:month-name` / `date:month-abbreviation` | 2 | implemented | English names. gYear is rejected (`''`), per the EXSLT spec's permitted formats and modern libxslt — see "Known divergences". | `cases/date/month-name.1`, `cases/date/month-abbreviation.1`, battery |
| `date:week-in-year` | 2 | implemented | ISO week number; accepts only dateTime/date. | `cases/date/week-in-year.1`, battery |
| `date:day-in-year` | 2 | implemented | | `cases/date/day-in-year.1`, battery |
| `date:day-in-month` | 2 | implemented | | battery |
| `date:day-of-week-in-month` | 2 | implemented | Ordinal week of month (1–5). | battery |
| `date:day-in-week` | 2 | implemented | 1 = Sunday, per EXSLT; accepts only dateTime/date. | `cases/date/day-name.1`, battery |
| `date:day-name` / `date:day-abbreviation` | 2 | implemented | English names; accept only dateTime/date. | `cases/date/day-name.1`, `cases/date/day-abbreviation.1`, battery |
| `date:hour-in-day` / `date:minute-in-hour` / `date:second-in-minute` | 2 | implemented | Accept only dateTime/time. | battery |
| `date:duration` | 2 | implemented | Seconds → `PnDTnHnMnS`. Decimal-exact (`xs:decimal`); libxslt's binary-float rounding edge (e.g. `3599.99999999999` → `PT1H`) is a documented divergence. | `cases/date/duration.1`, `cases/date/duration.2` |
| `date:add-duration` | 2 | implemented | Port of libexslt `_exsltDateAddDurCalc`: months carry into years, seconds carry into days, days do **not** carry into months; opposite-sign component sums are indeterminate → `''` (matches libxslt). | `cases/date/add-duration.1`, `cases/date/add-duration.2` |
| `date:add` | 2 | implemented | Port of libexslt `_exsltDateAdd` component arithmetic (not calendar arithmetic); result type is the less specific of the operands' types, and promoted dateTime results always print a timezone (`Z` when zero). Matches libxslt verbatim. | `cases/date/add.1`, `cases/date/add.2` |
| `date:difference` | 2 | implemented | Port of libexslt `_exsltDateDifference`; both operands truncate to the less specific type, gYear/gYearMonth differences yield an exact month count, and day-level differences are exact day arithmetic with timezone offsets folded in. Matches libxslt verbatim. | `cases/date/difference.1`, `cases/date/difference.2` |
| `date:seconds` | 2 | implemented | Total seconds of a duration, or epoch seconds of a dateTime. | `cases/date/seconds.1`, `cases/date/seconds.2` |
| `date:sum` | 2 | implemented | Sum of a node-set of durations; ignores non-duration nodes (empty string on error, per libxslt). | `cases/date/sum.1`, `cases/date/sum.2` |

## set — Sets (`src/sets.xsl`)

| Function | Tier | Status | Native equivalent / notes | Tests |
|----------|------|--------|---------------------------|-------|
| `set:intersection` | 1 | wrapper | XPath 3.1 `intersect` operator | `cases/sets/intersection.1` |
| `set:difference` | 1 | wrapper | XPath 3.1 `except` operator | `cases/sets/difference.1` |
| `set:has-same-node` | 1 | wrapper | `some $a in $ns1, $b in $ns2 satisfies $a is $b` | `cases/sets/has-same-node.1` |
| `set:distinct` | 2 | implemented | Nodes with distinct string values, document order, first occurrence kept. | `cases/sets/distinct.1` |
| `set:leading` | 2 | implemented | Reproduces the libxml2 reference rule: nodes in `$ns1` preceding the document-first node of `$ns2`, **empty unless that node is itself in `$ns1`**; `$ns2` empty → `$ns1`. | `cases/sets/leading.1` |
| `set:trailing` | 2 | implemented | Symmetric to `set:leading`: nodes in `$ns1` **following the document-first node of `$ns2`** (libxml2 anchors on `xmlXPathNodeSetItem(arg2, 0)`, not the last node), **empty unless that node is itself in `$ns1`**; `$ns2` empty → `$ns1`. | `cases/sets/trailing.1` |

## dyn — Dynamic (`src/dynamic.xsl`)

| Function | Tier | Status | Notes | Tests |
|----------|------|--------|-------|-------|
| `dyn:evaluate` | 3 | documented | Dynamic XPath evaluation requires engine support; **not implementable in pure XSLT 3.0**. The function slot raises a terminating `xsl:message`. Candidate for a Bosak native/commercial extension — see `../ROADMAP.md`. | — |

## func — Functions (no module)

| Construct | Tier | Status | Notes |
|-----------|------|--------|-------|
| `func:function` / `func:result` | 3 | documented | XSLT 1.0 mechanism for defining extension functions inside a stylesheet. Fully superseded by `xsl:function` (XSLT 2.0+). No module provided — migrating stylesheets should mechanically rewrite `func:function` as `xsl:function`. |

## Known divergences from the libxslt reference

Recorded here and in `tests/ATTRIBUTION.md`:

1. `exsl:object-type` reports XSLT 1.0 `RTF` values as `node-set` (XSLT 3.0 has no
   result-tree-fragment type).
2. `date:duration` is decimal-exact; libxslt's binary-float rounding of near-integer
   second counts (e.g. `3599.99999999999`) is not reproduced.
3. `math:power` uses `exp/log` and returns NaN for negative bases; libxslt's `pow()`
   returns real powers there.
4. `date/month-name.1` (hand-written case): the golden line `month-name('2026') =
   'January'` was re-goldened to `''` on 2026-10-06. The original encoded the
   pre-rewrite cast-based behavior, which accepted `xs:gYear`; the EXSLT spec's
   permitted formats for `month-name` (dateTime, date, gYearMonth, gMonth) and
   modern libxslt (1.1.45, probed: `''`) both reject gYear, and libxslt's own
   `gyear.1` case requires `''`. The library matches the corrected golden and the
   libxslt battery verbatim.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — EXSLT Compatibility Matrix
  </p>
</div>
