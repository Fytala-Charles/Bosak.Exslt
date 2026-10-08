<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 07 — result trees and types">
  <br><br>
  <h1>Session 07 — Result Trees and Types</h1>
  <p>What a variable really holds: <code>exsl:node-set</code>, <code>exsl:object-type</code></p>
</div>

> **Time:** ~60 minutes · **Prerequisites:** [session 03 — recursion as the basic loop](../03-recursion/README.md), [session 06 — nodes, identity, grouping](../06-nodes-and-grouping/README.md); [session 00](../00-setup/README.md) for tooling
> **Vehicle:** EXSLT common module (`http://exslt.org/common`)

---

## 1. The XSLT 1.0 wound these functions bandage

In XSLT 1.0, a variable built with content instructions held a **result tree
fragment (RTF)** — a tree you could serialize but *not navigate*: running a
path step on it was a compile error. `exsl:node-set()` was the escape hatch,
an extension function that converted the fragment into an ordinary node set so
you could finally query what you had built. `exsl:object-type()` reported
`'RTF'` for such values, alongside `'string'`, `'number'`, `'boolean'`, and
`'node-set'`.

XSLT 3.0 healed the wound: **every variable holds an ordinary sequence**, and
a variable built with content instructions holds a full tree headed by a
**document node** — navigable, path-steppable, no conversion needed. Two
consequences shape this session:

- `exsl:node-set` has nothing left to do. Its honest XSLT 3.0 implementation
  is the **identity**. When migrating legacy stylesheets you delete the call
  and use the variable directly.
- There are no more RTFs, so `exsl:object-type` can never report `'RTF'`. A
  stored result tree reports as `'node-set'` — a **documented divergence**
  from the XSLT 1.0 behavior, recorded in `docs/COMPATIBILITY.md`. A type
  that no longer exists still has a slot in the function, because legacy
  callers branch on these five strings.

One mechanical note carries the whole session: a stored tree is a *document
node* whose child is your element. Path steps see the root first —
`$var/totals/product` works because `$var` is the document node and `totals`
is its child element. You met this machinery already in session 05, where
`str:replace` built its text node inside a variable; here it is made explicit.

## 2. Your task

Open `starter/transform.xsl` and run the test:

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

(From the repository root: `dotnet test training/TrainingTests/TrainingTests.csproj`.)

Two exercises:

1. **`exsl:node-set($object)`** — the identity in XSLT 3.0; the starter's
   naive version strips the document node and breaks every path step written
   against the tree (exercise 1, section 4).
2. **`exsl:object-type($object)`** — classify the first item as `'string'`,
   `'number'`, `'boolean'`, `'node-set'`, or `'external'` (exercise 2,
   section 5).

## 3. Reading the starter

The template computes a per-product totals **tree** in a variable, then treats
it like a document:

```xml
<xsl:variable name="totals">
  <totals>
    <xsl:for-each select="row">
      <product name="{@product}" total="{@qty * @price}"/>
    </xsl:for-each>
  </totals>
</xsl:variable>
<xsl:variable name="report" select="exsl:node-set($totals)"/>
```

Read the first variable as: *a document node, whose child is `<totals>`, whose
children are the computed `<product>` elements.* The second variable is the
XSLT 1.0 spelling of "let me path-step that" — today it calls your
`exsl:node-set`. The template then asks the tree two questions (best product,
grand total) and classifies six arguments with `exsl:object-type`: the
stored tree itself, a string, a number, a boolean, a node sequence, the empty
sequence, and a map.

Engine quirks (session 04, section 3) apply as usual — and exercise 2 adds a
live one: this engine throws `FOTY0014` if you try to `fn:string` a map, so a
type guesser that sniffs string values does not merely give wrong answers, it
crashes.

## 4. Exercise 1: implement `exsl:node-set`

The starter's version:

```xml
<xsl:sequence select="$object/child::node()"/>
```

The misconception is natural — "node set" sounds like the *elements inside*
the tree, so this returns the children of the stored document node: the bare
`<totals>` element. But the template's path steps are written against the
tree as built (`$report/totals/product`), and from the bare element the first
step `totals` finds no child. `<best>` and `<grand>` come out empty.

### Hints (progressive — try each before opening the next)

1. Say what XSLT 3.0 actually does: a variable already holds an ordinary
   sequence, so the conversion the function used to perform is… nothing.
   Return the argument exactly as received.
2. The honest implementation is one word long. If you find yourself
   constructing anything, reconsider.
3. Sanity-check the semantics, not just the test: with the identity in place,
   `$report` *is* the document node, `$report/totals` is the element, and
   `$report/totals/product` are the computed rows. Draw the three-level tree.
4. Predict before running: compute the three totals from `input.xml` by hand
   (quantity × price per row), pick the maximal one for `best`, sum them for
   `grand`, and compare with the diff.
5. Still stuck? `src/exsl.xsl` — look for `exsl:node-set`.

## 5. Exercise 2: implement `exsl:object-type`

The starter guesses from the *string value* of the first item: looks-numeric
means `'number'`, otherwise `'string'`, non-atomics lump into `'node-set'`.
Trace it: `true()` reads as the string `"true"` — reported `'string'`, not
`'boolean'`. A map is not an atomic value at all — and feeding one to
`fn:string` crashes on this engine. The real design inspects the **type**,
not the spelling.

### Hints (progressive — try each before opening the next)

1. XPath 3.1 introspects types with `instance of`: `$object[1] instance of
   node()`, `instance of xs:boolean`, `instance of xs:string`, `instance of
   map(*)`. (Why `$object[1]`: the EXSLT contract classifies the object by
   its first item.)
2. The order of the branches is part of the answer: test nodes first (a
   document node, an element, a text node — all `'node-set'`), then maps,
   arrays, and function items (`'external'` — types XSLT 1.0 never had), then
   booleans, then strings and their cousins (`xs:anyURI`, `xs:QName`,
   `xs:untypedAtomic`), and let everything numeric fall through to
   `'number'`.
3. The empty sequence is the empty node set per the EXSLT spec — branch on
   `empty($object)` *before* touching `$object[1]`.
4. Never call `fn:string` to classify: that is the crash from section 3, and
   even where it works, `"true"` and `"42"` are spellings, not types.
5. The `<of-rtf>` line is the session's point on purpose: the stored tree
   reports `'node-set'`. XSLT 1.0 would have said `'RTF'`; that type is gone,
   and the golden pins the documented answer (`docs/COMPATIBILITY.md`).
6. Still stuck? `src/exsl.xsl` — look for `exsl:object-type`.

## 6. Checking your work

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

- `Starter_differs_from_golden` **passes** — good: it asserts your starter is still
  unsolved, guarding the exercise for the next learner.
- To check *your* implementation, paste it into the starter and watch the
  `<best>`, `<grand>`, and `<of-…>` lines of the test diff. When your output
  equals `case/expected.xml`, you are done. (If you edited `starter/transform.xsl`
  directly, the `Starter_differs_from_golden` test will now fail — that failure means
  *success* for you; restore the stub when you finish the session so the
  exercise stays RED for the next learner.)

You can also run the transform by hand in VS Code with the Bosak extension,
using `input.xml` as the source document.

## 7. Compare with the library

Open `src/exsl.xsl`. `exsl:node-set` is three lines — parameter, comment,
identity — with a note to delete the call when migrating. `exsl:object-type`
is the branch ladder you wrote, with the same order and the same empty-first
guard; its header comment records the `'RTF'` divergence next to the function
rather than in a distant document, which is where a future maintainer will
look.

Two more readings while you are there. `exsl:document` has **no function
slot** — it was an extension *element* (multiple output documents), and XSLT
2.0's `xsl:result-document` replaced it; the module documents the absence
instead of stubbing a fake. And notice how much of this module is *history
management*: two of its three entries exist so that XSLT 1.0 stylesheets keep
running. That is a real role — most EXSLT traffic in the wild is legacy
migration — and it ends at session 10, where `dyn:evaluate` cannot be
papered over at all.

## 8. Go further

- **`instance of` safari:** add lines classifying `xs:date('2026-10-06')`
  (which branch catches it?), the decimal `10.5`, and the result of
  `current-dateTime()`. Which of your branches fires, and is the EXSLT label
  still meaningful for it?
- **Typed variables:** declare the totals variable `as="document-node()"` and
  re-run; then try `as="element(totals)"` and watch the template's path steps
  change meaning. What does each declaration promise the compiler?
- **The delete-the-call experiment:** remove the `exsl:node-set` call (use
  `$totals` directly in `$report`) — the golden should stay green. That is the
  whole tier-1 migration story in one edit.
- **Peek ahead:** session 08 parses and formats dates — where
  `xs:date('2026-02-30')` fails loudly, and where the `format-date` picture
  string decides whether October prints as `10` or as `October`.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
