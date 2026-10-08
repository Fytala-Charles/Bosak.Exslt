# Test fixture attribution

Golden fixtures in `tests/cases/` are derived from upstream EXSLT test corpora.
Every case records its own provenance in `meta.json`; this file is the summary and
the rulebook.

## Sources

| Project | License | Upstream path pattern | Used for |
|---------|---------|-----------------------|----------|
| [libxslt](https://gitlab.gnome.org/GNOME/libxslt) (GNOME) | MIT | `tests/exslt/<module>/<name>.{xml,xsl,out}` | 61 cases (15 seed + 9 REQ-001 batch 1 + 11 REQ-001 batch 2 + 26 REQ-001 batch 3) |
| [Xalan-J](https://github.com/apache/xalan-test) (Apache) | Apache-2.0 | `tests/exslt/<module>/<name>.{xml,xsl}` (+ golden `tests/exslt-gold/<module>/<name>.out`) | 30 cases (REQ-002) |
| hand-written (this project, Fytala) | Apache-2.0 | — | 12 cases: 6 REQ-008 date cases (`date.1` converted to the libxslt battery in batch 3) + 6 REQ-001 batch-4 gap cases for functions with no upstream coverage |

libxslt's EXSLT test suite is the de-facto reference behavior for EXSLT
(implemented by the libexslt library). The MIT license permits reuse with
attribution; the libxslt copyright notice is reproduced below per its license
terms. Xalan-J's EXSLT tests (Apache-2.0, `apache/xalan-test` on GitHub) are
the sanctioned second source for cases the libxslt corpus does not cover; 30
were imported under REQ-002 (see "Xalan-J provenance" below).

## Per-case provenance

| Case | Upstream (libxslt) | Adaptations |
|------|--------------------|-------------|
| `math/max.1` | `tests/exslt/math/max.1` | version 1.0 → 3.0; library included |
| `math/min.1` | `tests/exslt/math/min.1` | version 1.0 → 3.0; library included |
| `math/highest.1` | `tests/exslt/math/highest.1` | version 1.0 → 3.0; library included |
| `strings/tokenize.1` | `tests/exslt/strings/tokenize.1` | version 1.0 → 3.0; library included |
| `strings/padding.1` | `tests/exslt/strings/padding.1` | version 1.0 → 3.0; library included |
| `strings/align.1` | `tests/exslt/strings/align.1` | version 1.0 → 3.0; library included |
| `strings/replace.1` | `tests/exslt/strings/replace.1` | version 1.0 → 3.0; library included |
| `strings/split.1` | `tests/exslt/strings/split.1` | version 1.0 → 3.0; library included |
| `sets/distinct.1` | `tests/exslt/sets/distinct.1` | version 1.0 → 3.0; library included |
| `sets/leading.1` | `tests/exslt/sets/leading.1` | version 1.0 → 3.0; library included |
| `sets/has-same-node.1` | `tests/exslt/sets/has-same-node.1` | version 1.0 → 3.0; library included |
| `common/node-set.1` | `tests/exslt/common/node-set.1` | version 1.0 → 3.0; library included |
| `common/object-type.1` | `tests/exslt/common/object-type.1` | version 1.0 → 3.0; library included; XSLT 1.0 RTF check and Saxon-only external check dropped (XSLT 3.0 cannot distinguish result tree fragments — see `docs/COMPATIBILITY.md`); golden adjusted to match |
| `date/duration.1` | `tests/exslt/date/duration.1` | version 1.0 → 3.0; library included; expected output kept verbatim from libxslt — see "Known divergences" |
| `date/add-duration.1` | `tests/exslt/date/add-duration.1` | version 1.0 → 3.0; library included |
| `date/date.1` | `tests/exslt/date/date.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` (text output) — matched upstream verbatim; replaces the earlier hand-written REQ-008 case of the same name |
| `date/date.2` | `tests/exslt/date/date.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/datetime.1` | `tests/exslt/date/datetime.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/datetime.2` | `tests/exslt/date/datetime.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/gday.1` | `tests/exslt/date/gday.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/gday.2` | `tests/exslt/date/gday.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/gmonth.1` | `tests/exslt/date/gmonth.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/gmonth.2` | `tests/exslt/date/gmonth.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/gmonthday.1` | `tests/exslt/date/gmonthday.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/gmonthday.2` | `tests/exslt/date/gmonthday.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/gyear.1` | `tests/exslt/date/gyear.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/gyear.2` | `tests/exslt/date/gyear.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/gyearmonth.1` | `tests/exslt/date/gyearmonth.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/gyearmonth.2` | `tests/exslt/date/gyearmonth.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/time.1` | `tests/exslt/date/time.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/time.2` | `tests/exslt/date/time.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/add.1` | `tests/exslt/date/add.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/add.2` | `tests/exslt/date/add.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/add-duration.2` | `tests/exslt/date/add-duration.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/difference.1` | `tests/exslt/date/difference.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/difference.2` | `tests/exslt/date/difference.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/duration.2` | `tests/exslt/date/duration.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/seconds.1` | `tests/exslt/date/seconds.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/seconds.2` | `tests/exslt/date/seconds.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/sum.1` | `tests/exslt/date/sum.1` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/sum.2` | `tests/exslt/date/sum.2` | version 1.0 → 3.0; library included; golden stored as `expected.txt` — matched upstream verbatim |
| `date/month-name.1` | hand-written (Apache-2.0) | REQ-008 repair case pinning post-repair `date:month-name`; **re-goldened 2026-10-06 (line 3 only)**: `month-name('2026')` corrected from `'January'` to `''` — the EXSLT spec's permitted formats (dateTime, date, gYearMonth, gMonth) and modern libxslt 1.1.45 (probed via lxml: `''`) both reject `xs:gYear`; libxslt's own `gyear.1` case requires `''`. See "Known divergences" |
| `math/sqrt.1` | hand-written (Apache-2.0) | REQ-001 batch 4 gap case for `math:sqrt` (no upstream coverage): perfect squares and exact fractions pinned exactly, `sqrt(2)` pinned to the engine-verified IEEE double, negative input → `NaN`. Goldens are engine-verified output |
| `math/power.1` | hand-written (Apache-2.0) | REQ-001 batch 4 gap case for `math:power` (upstream `math/power.1` skipped as binary-float): pins the documented exp/log implementation — `power(0,0)` and negative bases → `NaN` (divergence 3 in `docs/COMPATIBILITY.md`), `power(10,-2)` pins the exp/log float path (`0.009999999999999995`), not decimal-exact `0.01`. Goldens are engine-verified output |
| `math/constant.1` | hand-written (Apache-2.0) | REQ-001 batch 4 gap case for `math:constant` (no upstream coverage): significant-digit rounding of every recognized name incl. the spec spelling `SQRRT2`, precision < 1 passthrough, unknown name → `NaN`. Goldens are engine-verified output |
| `math/log-exp.1` | hand-written (Apache-2.0) | REQ-001 batch 4 gap case for `math:log`/`math:exp` (no upstream coverage): exact identities (`log(1)=0`, `exp(0)=1`), `log(0)` → `-INF`, `exp(1000)` → `INF`, `log(E)` pins engine double noise. Goldens are engine-verified output |
| `math/trig.1` | hand-written (Apache-2.0) | REQ-001 batch 4 gap case for the seven trigonometric wrappers (no upstream coverage): canonical-angle pins, inverse-function double noise (`tan(pi/4)=0.9999999999999999`), domain edge `asin(2)` → `NaN`, `atan2(0,0)` pins `0` (the IEEE-754/XPath 3.1 defined result). Goldens are engine-verified output |
| `sets/intersection.1` | hand-written (Apache-2.0) | REQ-001 batch 4 gap case for `set:intersection` (libxslt's sets suite has no dedicated case): identity overlap via name predicates over one flat node list (same technique as `sets/difference.1`), superset intersection, empty-vs-root edge, document-order preservation. Goldens are engine-verified output |
| `date/month-abbreviation.1` | hand-written (Apache-2.0) | REQ-008 repair case: post-fix `date:month-abbreviation` incl. `*-3` width edge |
| `date/week-in-year.1` | hand-written (Apache-2.0) | REQ-008 repair case: post-fix `date:week-in-year` (ISO week edge) |
| `date/day-in-year.1` | hand-written (Apache-2.0) | REQ-008 repair case: post-fix `date:day-in-year` (leap-year edge) |
| `date/day-name.1` | hand-written (Apache-2.0) | REQ-008 repair case: post-fix `date:day-name` (happy + invalid edge) |
| `date/day-abbreviation.1` | hand-written (Apache-2.0) | REQ-008 repair case: post-fix `date:day-abbreviation` (happy + invalid edge) |
| `math/highest.2` | `tests/exslt/math/highest.2` | version 1.0 → 3.0; library included; pins empty-input edge (`Highest: `) |
| `math/highest.5` | `tests/exslt/math/highest.5` | version 1.0 → 3.0; library included; pins `math:lowest` + `math:highest` with duplicate extrema (tie order) |
| `math/lowest.1` | `tests/exslt/math/lowest.1` | version 1.0 → 3.0; library included |
| `math/lowest.2` | `tests/exslt/math/lowest.2` | version 1.0 → 3.0; library included; pins empty-input edge (`Lowest: `) |
| `math/max.2` | `tests/exslt/math/max.2` | version 1.0 → 3.0; library included; pins empty-input edge (`Maximum: NaN`) |
| `math/max.5` | `tests/exslt/math/max.5` | version 1.0 → 3.0; library included; pins `math:min` + `math:max` over attribute nodes |
| `math/min.2` | `tests/exslt/math/min.2` | version 1.0 → 3.0; library included; pins empty-input edge (`Minimum: NaN`) |
| `strings/tokenize.2` | `tests/exslt/strings/tokenize.2` | version 1.0 → 3.0; library included; `exclude-result-prefixes="str"` added (XSLT 3.0 ignores `extension-element-prefixes` for function namespaces — without it the `str` namespace leaked onto literal result elements); golden stored as `expected.txt` (fragment output, not a single document) |
| `strings/tokenize.3` | `tests/exslt/strings/tokenize.3` | version 1.0 → 3.0; library included; golden stored as `expected.txt` (bare text lines); pins empty-token dropping on consecutive/adjacent delimiters — matched upstream verbatim |
| `strings/uri` | `tests/exslt/strings/uri` | version 1.0 → 3.0; library included; pins the `src/strings.xsl` 1.1 libxslt-parity repairs: `str:decode-uri` decodes percent-escape runs as UTF-8 bytes (was Latin-1 per byte) and `str:encode-uri` full mode leaves the mark characters `! * ' ( )` and `@` unencoded and both modes escape a literal `%` to `%25` — matched upstream verbatim |
| `sets/difference.1` | `tests/exslt/sets/difference.1` | version 1.0 → 3.0; library included; documentation comment and preceding whitespace-only text node removed (the Bosak engine does not strip whitespace-only text nodes adjacent to comments; libxslt does) — matched upstream verbatim |
| `sets/trailing.1` | `tests/exslt/sets/trailing.1` | version 1.0 → 3.0; library included; pins `set:trailing` anchoring on the first node of the second argument in document order (libxml2 `xmlXPathNodeSetItem(arg2, 0)`) — matched upstream verbatim |
| `common/node-set.2` | `tests/exslt/common/node-set.2` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `common/node-set.3` | `tests/exslt/common/node-set.3` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `common/node-set.4` | `tests/exslt/common/node-set.4` | version 1.0 → 3.0; library included; inert `mode` attribute dropped from the named template (XSLT 3.0 `XTSE0500` forbids `mode` on a matchless template; the golden reads `@mode` from the input document, which is a copy of the stylesheet); golden stored as `expected.txt` (two root elements, not one well-formed document) — matched upstream verbatim |
| `common/node-set.5` | `tests/exslt/common/node-set.5` | version 1.0 → 3.0; library included; whitespace-only text node between the stylesheet comment and the `xsl:for-each` end tag removed (Bosak does not strip it; libxslt does) — matched upstream verbatim |
| `common/node-set.6` | `tests/exslt/common/node-set.6` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `common/node-set.7` | `tests/exslt/common/node-set.7` | version 1.0 → 3.0; library included; golden stored as `expected.txt` (bare text output `A`, not a well-formed XML document) — matched upstream verbatim |
| `common/node-set.8` | `tests/exslt/common/node-set.8` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `common/node-set.9` | `tests/exslt/common/node-set.9` | version 1.0 → 3.0; library included; `exclude-result-prefixes="exslt"` added (XSLT 1.0 `extension-element-prefixes` suppressed the namespace; under XSLT 3.0 `xsl:function` it leaks onto the result without the exclude) — matched upstream verbatim |

### Xalan-J provenance (REQ-002)

Upstream base names are kept (Xalan's `math12`, `strings1`, …); they do not
collide with the libxslt-derived names above (`max.1`, `align.1`, …). The
`datetime` module maps to the `date` namespace. All transforms carry the
upstream ASF license comment blocks verbatim; goldens are stored as
`expected.xml`.

| Case | Upstream (Xalan-J, `apache/xalan-test`) | Adaptations |
|------|-----------------------------------------|-------------|
| `common/common1` | `tests/exslt/common/common1` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `common/common2` | `tests/exslt/common/common2` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `common/common3` | `tests/exslt/common/common3` | version 1.0 → 3.0; library included; `exslt:object-type($tree)` RTF line dropped (XSLT 3.0 cannot distinguish result tree fragments — divergence 2, cf. `common/object-type.1`); golden adjusted to remove the `RTF` token |
| `math/math2` | `tests/exslt/math/math2` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added; one golden line adapted (`acos(0.253)` StrictMath last-ulp noise) — see "Known divergences" 4 |
| `math/math3` | `tests/exslt/math/math3` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added; one golden line adapted (`asin(0.253)` StrictMath last-ulp noise) — divergence 4 |
| `math/math4` | `tests/exslt/math/math4` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added — matched upstream verbatim |
| `math/math7` | `tests/exslt/math/math7` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added; two golden lines adapted (StrictMath argument-reduction/last-ulp noise, incl. large-argument `cos(5223849703457)`) — divergence 4 |
| `math/math8` | `tests/exslt/math/math8` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added; undefined bareword constant name → `'UNDEFINED'` (Xalan evaluated it as NaN); `$input3` block dropped and golden tail truncated (upstream golden aborts mid-document on undefined `$zero`); four golden lines adapted (exp float noise, XPath 3.1 large-double formatting, `Infinity` → `INF`) — divergences 4 and 5 |
| `math/math9` | `tests/exslt/math/math9` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added — matched upstream verbatim |
| `math/math10` | `tests/exslt/math/math10` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added; illegal `xsl:param` inside `xsl:for-each` (XTSE0010) replaced by direct context-item use — matched upstream verbatim |
| `math/math11` | `tests/exslt/math/math11` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added — matched upstream verbatim |
| `math/math12` | `tests/exslt/math/math12` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math common"` added; declared-but-unused `xmlns:common` dropped from the golden root (Xalan leaks it) — matched upstream verbatim |
| `math/math13` | `tests/exslt/math/math13` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added — matched upstream verbatim |
| `math/math14` | `tests/exslt/math/math14` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added; golden re-generated from engine output — Xalan pins `StrictMath.pow` semantics that diverge from the documented exp/log implementation (divergence 3, second-corpus pin; cf. `math/power.1`) — divergence 5 |
| `math/math16` | `tests/exslt/math/math16` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added; one golden line adapted (large-argument `sin(5223849703457)` argument-reduction noise) — divergence 4 |
| `math/math17` | `tests/exslt/math/math17` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added; two golden lines adapted for XPath 3.1 `xs:double` string formatting (scientific notation for large magnitudes) — divergence 5 |
| `math/math18` | `tests/exslt/math/math18` | version 1.0 → 3.0; library included; `exclude-result-prefixes="math"` added; one golden line adapted (large-argument `tan(5223849703457)` argument-reduction noise) — divergence 4 |
| `sets/sets1` | `tests/exslt/sets/sets1` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `sets/sets2` | `tests/exslt/sets/sets2` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `sets/sets3` | `tests/exslt/sets/sets3` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `sets/sets4` | `tests/exslt/sets/sets4` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `sets/sets5` | `tests/exslt/sets/sets5` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `sets/sets6` | `tests/exslt/sets/sets6` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `strings/strings1` | `tests/exslt/strings/strings1` | version 1.0 → 3.0; library included; `exclude-result-prefixes="str"` added — matched upstream verbatim |
| `strings/strings3` | `tests/exslt/strings/strings3` | version 1.0 → 3.0; library included; `exclude-result-prefixes="str"` added; `xml:space="preserve"` added to the input root (Xalan-J preserves source whitespace-only text nodes by default; XSLT 3.0 strips them) — matched upstream verbatim |
| `strings/strings5` | `tests/exslt/strings/strings5` | version 1.0 → 3.0; library included; UTF-16 → UTF-8 (upstream file is UTF-16) — matched upstream verbatim |
| `strings/strings7` | `tests/exslt/strings/strings7` | version 1.0 → 3.0; library included; UTF-16 → UTF-8 — matched upstream verbatim |
| `strings/strings8` | `tests/exslt/strings/strings8` | version 1.0 → 3.0; library included; UTF-16 → UTF-8 — matched upstream verbatim |
| `strings/strings10` | `tests/exslt/strings/strings10` | version 1.0 → 3.0; library included — matched upstream verbatim |
| `strings/strings11` | `tests/exslt/strings/strings11` | version 1.0 → 3.0; library included — matched upstream verbatim |

"Library included" means an `xsl:include` of the corresponding
`src/<module>.xsl` was added; no template, input, or expected content was
otherwise altered unless listed.

## Skipped upstream cases (REQ-001)

Recorded per REQ-001's acceptance criterion — every upstream case is either
converted above or skipped here with a reason.

| Upstream case | Reason |
|---------------|--------|
| `tests/exslt/math/max.3` | Exercises `func:function`/`func:result` (EXSLT functions module — tier 3 documented, superseded by `xsl:function`); the `func:` machinery, not `math:max`, is the subject of the case |
| `tests/exslt/math/power.1` | Golden pins libxslt binary-float formatting (`2.85311670611e+11`); our decimal-exact `math:power` cannot reproduce it without faking the value — see divergence 3 in `docs/COMPATIBILITY.md` |
| `tests/exslt/common/dynamic-id` | Golden pins `generate-id()` values, which are processor-dependent by definition; no meaningful cross-engine comparison |
| `tests/exslt/common/import-test1` | Exercises `func:function`/`func:result` (EXSLT functions module — tier 3 documented, superseded by `xsl:function`) plus `xsl:import` of `.imp` fragments; the `func:` machinery, not `exslt:node-set`, is the subject of the case |
| `tests/exslt/date/current.xsl` | Time-dependent: exercises `date:date()`/`date:time()` with no argument (default today/now) and `date:date-time()`; output cannot be pinned to a golden |

The remaining upstream directories are out of scope for the golden corpus (REQ-001 covers only the five imported namespaces): `tests/exslt/dynamic/` (exercises `dyn:evaluate`, tier 3 documented), `tests/exslt/functions/` (the XSLT 1.0 `func:function` machinery, tier 3 documented), `tests/exslt/saxon/` (Saxon-processor-specific), and `tests/exslt/crypto/` (the `crypto` module is not part of EXSLT 1.0 and no module ships for it).

## Skipped upstream cases (REQ-002, Xalan-J)

Recorded per the REQ-002 acceptance criterion — every upstream case is either
converted above or skipped here with a reason.

| Upstream case (`apache/xalan-test`) | Reason |
|-------------------------------------|--------|
| `tests/exslt/datetime/datetime1` | `date:date-time()` — time-dependent, output cannot be pinned (same reason libxslt's `date/current.xsl` is skipped) |
| `tests/exslt/dynamic/dynamic1` | Exercises `dyn:evaluate` (tier 3 documented) |
| `tests/exslt/math/math1` | Exercises `math:abs` — not part of EXSLT 1.0 and no slot ships in `src/math.xsl` |
| `tests/exslt/math/math15` | Exercises `math:random` — not part of EXSLT 1.0 and non-deterministic |
| `tests/exslt/math/math19` | No upstream golden (`.out`) exists; also `method="html"` |
| `tests/exslt/math/math5` | Calls one-argument `math:atan2($y)` — a Xalan-specific overload (EXSLT 1.0 specifies two arguments); golden also carries StrictMath argument-reduction noise. The spec arity is covered by hand-written `math/trig.1` |
| `tests/exslt/math/math6` | Xalan's `math:constant` systematically diverges: it emits N+1 significant digits (`constant('PI',1)` → `3.1` vs the spec's `3`), returns `NaN` at precision 0, and returns `0` at large precisions. Nearly every golden line would need re-goldening; the function is covered by hand-written `math/constant.1` |
| `tests/exslt/strings/strings2` | Exercises `str:concat` — not part of EXSLT 1.0 and no slot ships in `src/strings.xsl` |
| `tests/exslt/strings/strings4` | No upstream golden (`.out`) exists |
| `tests/exslt/strings/strings6`, `tests/exslt/strings/strings9` | Non-spec third `$encoding` argument (`decode-uri($uri, $encoding)`, `encode-uri($uri, $encode-reserved, $encoding)`); the shipped arities are 1-arg/2-arg (XTSE0760) |

## Known divergences pinned by (or visible in) the corpus

1. **`date/duration.1`, input `3599.99999999999`**: libxslt computes in binary
   floating point and prints `PT1H`; this library computes with `xs:decimal` and
   produces `PT59M59.99999999999S`. The golden line for that input was deliberately
   re-goldened to the decimal-exact value (see the case's `meta.json`); all other
   lines remain verbatim libxslt output.
2. **`common/object-type.1`**: libxslt reports `RTF` for result tree fragments;
   XSLT 3.0 has no such type, so that check was removed rather than faked.
3. **`date/month-name.1` (hand-written)**: the original golden claimed
   `month-name('2026') = 'January'`, encoding the pre-rewrite cast-based
   behavior, which accepted `xs:gYear`. The EXSLT spec's permitted formats
   for `month-name` (dateTime, date, gYearMonth, gMonth) and the modern
   libxslt reference (1.1.45, probed via lxml: `''`) both reject gYear —
   and libxslt's own `gyear.1` case requires `''` for a gYear input. The
   golden line was re-goldened to `''` (all other lines unchanged).
4. **Xalan StrictMath float noise (REQ-002)**: Xalan-J's goldens encode
   `StrictMath` last-ulp and argument-reduction noise that a different
   conforming IEEE-754 engine cannot reproduce bit-for-bit. The affected
   golden lines were adapted to this engine's values (all other lines
   remain verbatim Xalan output): `math/math2` (`acos(0.253)`),
   `math/math3` (`asin(0.253)`), `math/math7` (`cos`, two lines incl. the
   large-argument `cos(5223849703457)`), `math/math8` (`exp(5)`,
   `exp(-3)`), `math/math16` (`sin(5223849703457)`), `math/math18`
   (`tan(5223849703457)`). For arguments of magnitude ~5×10¹², sin/cos/tan
   results are inherently reduction-sensitive: both engines agree to 7+
   significant digits, which is the meaningful cross-implementation bound.
5. **XPath 3.1 number formatting (REQ-002)**: XPath 3.1 `xs:double` string
   conversion prints large magnitudes in scientific notation
   (`5223849703457` → `5.223849703457E12`) and spells the overflow value
   `INF` (Xalan prints `Infinity`). Goldens echoing such values were
   adapted: `math/math8`, `math/math17`, and the re-generated
   `math/math14` golden. This is the same class as the libxslt
   binary-float formatting skips; it is formatting, not value, divergence.

> **Not a divergence — REQ-008 (2026-10-06):** the six remaining hand-written
> `date/*.1` cases above pin the behavior of the `format-date` family *after*
> the REQ-008 repair. Before the repair those functions returned `''`/`NaN`
> for every input (an `xs:dateTime` handed to `format-date`'s `xs:date?`
> parameter raised `XPTY0004`, which the defensive `try`/`catch` swallowed).
> The repair moved them from always-empty to the correct EXSLT answers — a bug
> fix, so no divergence entry applies; it is recorded here as an adaptation
> note only.

## Import rules for future fixtures

1. Only fetch from the two sanctioned sources above (or another corpus the project
   owner approves). Record project, license, and exact upstream path per case in
   `meta.json` **and** in the table above.
2. Convert to the case layout mechanically first; keep adaptations minimal and
   list every one.
3. Never invent upstream attribution. A hand-written case derived from the EXSLT
   spec's own examples is attributed as `{"project": "hand-written", "license":
   "Apache-2.0", "path": "EXSLT 1.0 spec, <function> examples"}`.

## libexslt copyright notice (MIT)

The imported fixtures come from the libexslt test suite; its license notice
(from the libxslt repository's `Copyright` file) is:

```
Licence for libexslt
----------------------------------------------------------------------
 Copyright (C) 2001-2002 Thomas Broyer, Charlie Bozeman and Daniel Veillard.
 All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is fur-
nished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FIT-
NESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CON-
NECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of the authors shall not
be used in advertising or otherwise to promote the sale, use or other deal-
ings in this Software without prior written authorization from him.
----------------------------------------------------------------------
```
