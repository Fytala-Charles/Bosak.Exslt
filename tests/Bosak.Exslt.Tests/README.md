# Golden-file case layout

Each case is a directory under `tests/cases/<namespace>/<case>/` containing:

| File | Required | Purpose |
|------|----------|---------|
| `transform.xsl` | yes | The stylesheet under test. Compiled with the Bosak `XsltCompiler`; relative `xsl:import`/`xsl:include` hrefs resolve against this file. |
| `input.xml` | no | Source document. When absent, an empty root node is used as the source. |
| `expected.xml` | one of `expected.xml` / `expected.txt` | Golden result for XML output. Compared after insignificant-whitespace normalization. |
| `expected.txt` | one of `expected.xml` / `expected.txt` | Golden result for text output. Compared as a whitespace-separated token stream. |
| `meta.json` | yes | Provenance: function under test, namespace URI, compatibility tier, and source attribution. |

`meta.json` schema:

```json
{
  "function": "math:max",
  "namespace": "http://exslt.org/math",
  "tier": 1,
  "source": {
    "project": "libxslt",
    "license": "MIT",
    "path": "tests/exslt/math/max.1"
  },
  "adaptations": "version attribute bumped from 1.0 to 3.0; library module included",
  "notes": "optional free-form remarks"
}
```

The harness discovers cases automatically; adding a directory is enough. See
`../ATTRIBUTION.md` for the upstream corpora and per-case provenance rules.
