# ADR-001: The Three-Tier Compatibility Model

> **Status:** Accepted (amended 2026-10-08 — REQ-004 decision recorded, see below)
> **Date:** 2026-10-06
> **Deciders:** Fytala (Charles Korthout)

---

## Context

EXSLT was designed for XSLT 1.0 processors with extension mechanisms. Bosak.Exslt
must serve three roles at once: **legacy-migration aid** (XSLT 1.0 + EXSLT
stylesheets keep working), **training/showcase codebase** (readable, genuine XSLT
3.0), and **golden-file test corpus** (compatibility measured against libxslt, the
de-facto reference). Those roles conflict unless the compatibility surface is
classified honestly:

- Under XSLT 3.0, many EXSLT functions already exist natively (possibly renamed) —
  re-implementing them would duplicate the engine and bloat the training surface.
- Many functions have no native equivalent but are fully expressible in standard
  XSLT 3.0 — these carry the real implementation and training value.
- Some functions (`dyn:evaluate`, `math:random`, extension elements such as
  `exsl:document`) cannot be implemented in standard XSLT 3.0 at all. Shipping
  anything for them would mean fake implementations or vendor lock-in — both fatal
  to the "runs on any conformant XSLT 3.0 processor" claim.

The model is tracked against **REQ-121** (EXSLT / legacy-migration support) in the
Bosak core feature registry: the core engine stays standards-only, and EXSLT
compatibility lives here in the open.

## Decision

Every EXSLT function (and extension construct) belongs to exactly one tier:

1. **Native in XPath 3.1** — implemented as a thin `xsl:function` wrapper in the
   EXSLT namespace, returning the *exact* EXSLT result shape, with a doc comment
   naming the native XPath 3.1 equivalent for progressive migration.
2. **Implementable in pure XSLT 3.0** — implemented for real in standard XSLT 3.0,
   with correct EXSLT semantics. Deliberate divergences from the libxslt reference
   are documented in `docs/COMPATIBILITY.md`, `tests/ATTRIBUTION.md`, and the
   golden case's `meta.json` — never silent.
3. **Not implementable in pure XSLT 3.0** — documented in the compatibility matrix.
   Function slots raise `xsl:message terminate="yes"` with a clear message; never a
   fake or majority-vote implementation.

`docs/COMPATIBILITY.md` is the authoritative per-function registry of tiers and
statuses. A host-backed (native/commercial engine) option for tier-3 functions is
an open possibility, tracked as **REQ-004** — it would convert a tier-3 slot into a
tier-1 wrapper, without changing the model.

## Amendment 2026-10-08 — REQ-004 decision: `dyn:evaluate` via `xsl:evaluate`

**Decision (a) accepted: the `dyn:evaluate` slot becomes a thin wrapper over
`xsl:evaluate`** (XSLT 3.0's standard dynamic-evaluation instruction) once the
host engine evaluates it conformantly. No Bosak native or commercial extension
function is required at all — `xsl:evaluate` is the standards-native mechanism,
so the "host-backed tier" question reduces to a single engine conformance fix
rather than a new product surface. The three-tier model itself is unchanged;
the amendment corrects the tier classification of one function.

**Evidence (probed against Bosak 0.12.3-beta, 2026-10-08):** the engine already
recognizes `xsl:evaluate` — static-string evaluation, `with-params` with
`xs:QName` map keys, and `as` coercion all work. Two conformance gaps block the
wrapper today:

1. **Context item never propagated** — any expression touching `.` (even
   `name(/*)` at document level inside `match="/"`) fails `XPDY0002: The context
   item is absent`. XSLT 3.0 §10.2.2 requires the context item of the
   `xsl:evaluate` instruction to be the context item of the evaluated
   expression.
2. **`with-params-names` binding broken** — `with-params="21"
   with-params-names="'y'"` leaves `$y` unbound (`XTDE3160`).

**Interim state:** the terminating slot in `src/dynamic.xsl` is unchanged
(a context-free-only wrapper would be exactly the partial/fake implementation
this ADR forbids). The planned wrapper is, in full:

```xml
<xsl:function name="dyn:evaluate" as="item()*">
  <xsl:param name="expression" as="xs:string"/>
  <xsl:evaluate xpath="$expression"/>            <!-- inherits the caller's focus -->
</xsl:function>
<xsl:function name="dyn:evaluate" as="item()*">
  <xsl:param name="expression" as="xs:string"/>
  <xsl:param name="context" as="node()?"/>
  <xsl:for-each select="$context">               <!-- re-establishes the EXSLT context node -->
    <xsl:evaluate xpath="$expression"/>
  </xsl:for-each>
</xsl:function>
```

On any conformant XSLT 3.0 processor this is a genuine tier-2 implementation.
Landing here is gated on core fixing gap 1 (tracked against REQ-121); gap 2 is
avoidable by using QName-map `with-params` only. When it lands: swap the slot,
add golden cases (including a context-node case), and re-tier the matrix row
from tier 3 to tier 2. Known residual divergence to document then: namespace
bindings are the stylesheet's, not the call site's (`xsl:evaluate` without
`namespace-context` — and `namespace-context` needs verifying on the engine
before use).

## Consequences

### Positive

- The "pure XSLT 3.0, runs on any conformant processor" claim is unconditional —
  no hidden engine dependencies anywhere in `src/`.
- Training value concentrates where it belongs: tier-2 modules are genuine
  implementations worth reading.
- The matrix makes every function's status auditable, and the golden corpus pins
  the implemented majority to executable evidence.

### Negative

- `dyn:evaluate` cannot be offered today; legacy stylesheets that depend on it get
  a terminating message and a migration note instead of compatibility.
- Tier-1 wrappers preserve EXSLT result shapes (`token` elements, not string
  sequences) that a modern stylesheet would not choose — a deliberate cost of the
  migration-aid role.
- Divergence bookkeeping (matrix + attribution + `meta.json`) is mandatory
  ceremony for every deliberate departure from libxslt.

## Alternatives Considered

### Implement everything from scratch, ignore native equivalents

Rejected: duplicates the engine, bloats the training surface, and obscures the
migration story (call sites would have no pointer to the native form).

### Vendor extensions behind a portability switch

Rejected: any processor-conditional in `src/` voids the "standard XSLT only" claim;
the switch would be off in every tested configuration, so the vendor path would be
untested dead code.

### Majority-vote semantics for unimplementable functions

Rejected: a wrong answer silently accepted is worse than a loud failure; EXSLT's
value to legacy code is predictable behavior, and tier-3 slots fail loudly and
documentedly.

## References

- [Three-tier model overview](../README.md#the-three-tier-compatibility-model)
- [Authoritative function matrix](./COMPATIBILITY.md)
- [Feature registry](./FEATURE_REQUESTS.md) — REQ-001 (corpus import), REQ-004
  (host-backed tier-3 option)
- Bosak core feature registry — REQ-121 (EXSLT / legacy migration)
- EXSLT 1.0 specification — https://exslt.org
- libxslt EXSLT implementation (reference) — https://gitlab.gnome.org/GNOME/libxslt

---

*Last updated: 2026-10-08*
