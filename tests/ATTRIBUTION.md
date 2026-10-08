# Test fixture attribution

Golden fixtures in `tests/cases/` are derived from upstream EXSLT test corpora.
Every case records its own provenance in `meta.json`; this file is the summary and
the rulebook.

## Sources

| Project | License | Upstream path pattern | Used for |
|---------|---------|-----------------------|----------|
| [libxslt](https://gitlab.gnome.org/GNOME/libxslt) (GNOME) | MIT | `tests/exslt/<module>/<name>.{xml,xsl,out}` | 35 cases (15 seed + 9 REQ-001 batch 1 + 11 REQ-001 batch 2) |
| hand-written (this project, Fytala) | Apache-2.0 | — | 7 REQ-008 date cases |

libxslt's EXSLT test suite is the de-facto reference behavior for EXSLT
(implemented by the libexslt library). The MIT license permits reuse with
attribution; the libxslt copyright notice is reproduced below per its license
terms. Xalan-J's EXSLT tests (Apache-2.0, `apache/xalan-j` on GitHub) are the
sanctioned second source for cases the libxslt corpus does not cover; none are
imported yet (see `../ROADMAP.md`, Stage 1).

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
| `date/date.1` | hand-written (Apache-2.0) | REQ-008 repair case: post-fix behavior of `date:date` (happy + invalid-input edge); semantics per EXSLT 1.0 spec |
| `date/month-name.1` | hand-written (Apache-2.0) | REQ-008 repair case: post-fix `date:month-name` (happy + gYear/invalid edges) |
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

## Known divergences pinned by (or visible in) the corpus

1. **`date/duration.1`, input `3599.99999999999`**: libxslt computes in binary
   floating point and prints `PT1H`; this library computes with `xs:decimal` and
   produces `PT59M59.99999999999S`. The golden line for that input was deliberately
   re-goldened to the decimal-exact value (see the case's `meta.json`); all other
   lines remain verbatim libxslt output.
2. **`common/object-type.1`**: libxslt reports `RTF` for result tree fragments;
   XSLT 3.0 has no such type, so that check was removed rather than faked.

> **Not a divergence — REQ-008 (2026-10-06):** the seven hand-written
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
