# Test fixture attribution

Golden fixtures in `tests/cases/` are derived from upstream EXSLT test corpora.
Every case records its own provenance in `meta.json`; this file is the summary and
the rulebook.

## Sources

| Project | License | Upstream path pattern | Used for |
|---------|---------|-----------------------|----------|
| [libxslt](https://gitlab.gnome.org/GNOME/libxslt) (GNOME) | MIT | `tests/exslt/<module>/<name>.{xml,xsl,out}` | All 15 current cases |

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

"Library included" means an `xsl:include` of the corresponding
`src/<module>.xsl` was added; no template, input, or expected content was
otherwise altered unless listed.

## Known divergences pinned by (or visible in) the corpus

1. **`date/duration.1`, input `3599.99999999999`**: libxslt computes in binary
   floating point and prints `PT1H`; this library computes with `xs:decimal` and
   produces `PT59M59.99999999999S`. The golden line for that input was deliberately
   re-goldened to the decimal-exact value (see the case's `meta.json`); all other
   lines remain verbatim libxslt output.
2. **`common/object-type.1`**: libxslt reports `RTF` for result tree fragments;
   XSLT 3.0 has no such type, so that check was removed rather than faked.

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
