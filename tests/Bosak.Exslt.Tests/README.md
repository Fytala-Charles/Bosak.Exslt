# Golden-file case layout

Each case is a directory under `tests/cases/<namespace>/<case>/` containing:

| File | Required | Purpose |
|------|----------|---------|
| `transform.xsl` | yes | The stylesheet under test. Compiled with the Bosak `XsltCompiler`; relative `xsl:import`/`xsl:include` hrefs resolve against this file. |
| `input.xml` | no | Source document. When absent, an empty root node is used as the source. |
| `expected.xml` | one of `expected.xml` / `expected.txt` | Golden result for XML output. Compared after insignificant-whitespace normalization. |
| `expected.txt` | one of `expected.xml` / `expected.txt` | Golden result for text output. Compared as a whitespace-separated token stream. |
| `meta.json` | yes | Provenance: function under test, namespace URI, compatibility tier, and source attribution. A `"mode": "package"` entry marks a case whose transform consumes the library via `xsl:use-package` — the harness then registers the `src/pkg/*.package.xsl` descriptors with the engine before compiling. |

`meta.json` schema:

```json
{
  "function": "math:max",
  "namespace": "http://exslt.org/math",
  "tier": 1,
  "mode": "package",
  "source": {
    "project": "libxslt",
    "license": "MIT",
    "path": "tests/exslt/math/max.1"
  },
  "adaptations": "version attribute bumped from 1.0 to 3.0; library module included",
  "notes": "optional free-form remarks"
}
```

`"mode": "package"` is optional (plain include-mode is the default). When
present, the harness scans `src/pkg/*.package.xsl` in the output directory and
registers each descriptor via `Bosak.Xslt.Api.XsltFunctionLibrary.RegisterPackage`
before compiling the case — required because `xsl:use-package` cannot resolve a
package the engine has not been told where to find.

The harness discovers cases automatically; adding a directory is enough. See
`../ATTRIBUTION.md` for the upstream corpora and per-case provenance rules.
