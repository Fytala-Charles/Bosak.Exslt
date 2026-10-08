<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 06 — nodes, identity, and grouping">
  <br><br>
  <h1>Session 06 — Nodes, Identity, Grouping</h1>
  <p>Comparing nodes as nodes: <code>set:has-same-node</code>, <code>set:distinct</code>, <code>set:difference</code></p>
</div>

> **Time:** ~60 minutes · **Prerequisites:** [session 03 — recursion as the basic loop](../03-recursion/README.md), [session 04 — regular expressions](../04-regular-expressions/README.md), [session 05 — stateful scanning](../05-stateful-scanning/README.md); [session 00](../00-setup/README.md) for tooling
> **Vehicle:** EXSLT sets module (`http://exslt.org/sets`)

---

## 1. Two ways to compare a node

Every session so far has compared what nodes *contain*. This session compares
the nodes *themselves*, and XSLT gives you two different answers depending on
how you ask:

- **`=`, `eq` — value comparison.** Both sides are atomized to their string
  values before comparing. Two different `<item>apple</item>` elements —
  different places in the tree, different attributes — are utterly `=` to
  each other.
- **`is` — identity comparison.** True only when both sides are the *same
  node*: same position in the same document. Two elements with identical
  content are still different nodes.
- **`<<` and `>>` — document order.** True when one node strictly precedes
  the other in the document. With it, "first occurrence" becomes a predicate.

The EXSLT sets module lives entirely in identity space, because its callers
care about *positions*, not just values: `set:has-same-node` asks whether two
node sets physically overlap; `set:difference` removes exactly the nodes you
point at; `set:distinct` deduplicates *while keeping the surviving nodes*.
Get the comparison wrong and every one of them lies — while looking perfectly
reasonable on inputs where values happen to be unique.

## 2. Your task

Open `starter/transform.xsl` and run the test:

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

(From the repository root: `dotnet test training/TrainingTests/TrainingTests.csproj`.)

Three exercises, one per naive starter function:

1. **`set:has-same-node($ns1, $ns2)`** — true iff the sets share a node by
   identity (exercise 1, section 4).
2. **`set:distinct($nodes)`** — deduplicate by string value, keeping the first
   node of each value-group, in document order (exercise 2, section 5).
3. **`set:difference($ns1, $ns2)`** — the nodes of `$ns1` that are not in
   `$ns2`, by identity (exercise 3, section 6).

## 3. Reading the starter

`input.xml` is two shelves of fruit. The values deliberately repeat **across
disjoint subtrees**, and every element carries a `sku` attribute so the golden
output shows *which physical element* survived each operation:

```xml
<shelf id="a">
  <item sku="a1">apple</item> …
</shelf>
<shelf id="b">
  <item sku="b1">pear</item> …
</shelf>
```

No element of shelf `a` *is* any element of shelf `b` — yet their values
overlap completely (`apple`, `pear`). That single design decision makes every
value-based shortcut wrong in a different way, and the golden file pins each
answer: `cross-shelf` is `false`, `distinct` keeps skus `a1 a2 a3 b2`,
`a-minus-b` keeps all of shelf `a`, and `all-minus-a` keeps all of shelf `b`.

Engine quirks (session 04, section 3) apply as usual; one quantified
expression with two variables (`some $a in …, $b in …`) is a *single* clause
and is safe — the library uses it too.

## 4. Exercise 1: implement `set:has-same-node`

The starter asks the value question:

```xml
<xsl:sequence select="some $a in $node-set1, $b in $node-set2 satisfies $a = $b"/>
```

For the two shelves this says `true` — `apple` equals `apple`. But the
contract is whether the sets share a *node*, and no element of shelf `a` is an
element of shelf `b`. The fix is one operator.

### Hints (progressive — try each before opening the next)

1. The quantified expression shape is already right: keep the `some …
   satisfies` skeleton. Only the comparison in the body changes.
2. `is` never atomizes: `$a is $b` is true only for the same node. Swap the
   operator and re-run — `cross-shelf` should flip to `false`.
3. Sanity-check the true case stays true: `overlap` passes shelf `a` plus its
   own first item — one physical node occurs in both arguments, so the answer
   must remain `true`. Identity cuts both ways.
4. Still stuck? `src/sets.xsl` — look for `set:has-same-node`.

## 5. Exercise 2: implement `set:distinct`

The starter's version is `distinct-values($nodes)` — and notice it even
*declares* the difference: `as="xs:string*"`. EXSLT `set:distinct` returns
**nodes**, because callers need what the surviving node carries: its position,
its `sku`, its children. Values are the grouping key; nodes are the payload.

There is a second contract clause the naive version cannot even express:
where several nodes share a value, the one kept is the **first in document
order** — with six items, the golden keeps `a1, a2, a3, b2` and drops `b1`
(its `pear` has `a2` before it) and `b3` (its `apple` has `a1` before it).

Grouping, the XPath 3.0 way, makes the intent obvious:
`xsl:for-each-group select="$nodes" group-by="."` forms one group per
*atomized value* (`group-by` compares keys by value), and
`current-group()[1]` is the first member of each group in document order.
That is the idiom this session's curriculum row names — and the library takes
an equivalent pure-predicate route you can write without it (section 8
compares them).

### Hints (progressive — try each before opening the next)

1. Keep a node exactly when no *other* node both precedes it and equals its
   string value. That is one `not(some $other in $nodes satisfies (… and …))`
   predicate over `$nodes` — fill the two clauses with `<<` and `string(…)
   eq string(…)`.
2. Write `<<` as `&lt;&lt;` inside the `select` attribute — it is an XML
   document, after all.
3. Why does this keep the *first* of each value-group? Because the first has
   no earlier equal; every later one does. The predicate selects the firsts.
4. The return type returns to `as="node()*"`. The template already serializes
   the returned elements — the `sku` attributes in the diff tell you whether
   you kept the right physical nodes.
5. Predict the count before you run: six items in, how many come out, and
   which skus?
6. Still stuck? `src/sets.xsl` — look for `set:distinct`.

## 6. Exercise 3: implement `set:difference`

The starter filters by value:

```xml
<xsl:sequence select="$node-set1[not(. = $node-set2)]"/>
```

Trace `a-minus-b` by hand: `apple` from shelf `a` equals `apple` from shelf
`b`, so the naive filter **drops `a1`** — an element that was never in the
second set at all. Correct answer: all of shelf `a`, because `except` removes
nodes *by identity*, and shelf `b` contributes no shared nodes.

### Hints (progressive — try each before opening the next)

1. XPath 3.1 has an operator for exactly this: `$node-set1 except $node-set2`
   — identity-based set difference, in document order. One line.
2. The mirror operator is `intersect`; the library's `set:intersection` is a
   one-line wrapper over it. Same identity semantics.
3. Predict both differences before running: `a-minus-b` keeps three elements
   (`a1 a2 a3`); `all-minus-a` keeps three different ones (`b1 b2 b3`). If
   your run loses `a1` or `b3`, you are still comparing values.
4. Still stuck? `src/sets.xsl` — look for `set:difference`.

## 7. Checking your work

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

- `Starter_differs_from_golden` **passes** — good: it asserts your starter is still
  unsolved, guarding the exercise for the next learner.
- To check *your* implementation, paste it into the starter and watch the
  `<cross-shelf>`, `<distinct>`, `<a-minus-b>`, and `<all-minus-a>` lines of the test
  diff. When your output equals `case/expected.xml`, you are done. (If you
  edited `starter/transform.xsl` directly, the `Starter_differs_from_golden`
  test will now fail — that failure means *success* for you; restore the stub
  when you finish the session so the exercise stays RED for the next learner.)

You can also run the transform by hand in VS Code with the Bosak extension,
using `input.xml` as the source document.

## 8. Compare with the library

Open `src/sets.xsl`. Two of your three functions are already there as
**tier-1 wrappers** — one line each over `is`/`except` — which is the
migration story in reverse: XPath 3.1 grew operators for exactly the identity
questions EXSLT had to phrase as functions. Your solutions should match the
library word for word.

`set:distinct` is the **tier-2** genuine implementation, and it takes the
pure-predicate route rather than `xsl:for-each-group`: keep a node when no
other node both `<<`-precedes it and has an equal string value. Both shapes
encode the same contract; the predicate version needs no engine grouping
machinery, which is a portability argument you will appreciate the day you
meet an engine where `for-each-group` misbehaves. (You can test that
machinery yourself — see below.)

One caution from the library's comments: `set:leading` and `set:trailing` in
`src/sets.xsl` deliberately reproduce a libxml2 reference quirk — the
leader/trailer node must itself be a member of the first node set, else the
result is empty. The golden case `tests/cases/sets/leading.1` pins that
behavior. When a reference implementation has a surprising rule, the library
copies the rule and documents it; it does not "fix" it.

## 9. Go further

- **`xsl:for-each-group` experiment:** rewrite `set:distinct` with
  `xsl:for-each-group select="$nodes" group-by="."` and
  `current-group()[1]`, run it, and compare with the predicate version. Same
  golden? Then check `docs/AGENT_HANDOVER.md` §4 — this engine's quirks are
  why the library plays it safe.
- **Implement `set:intersection`** (`$ns1 intersect $ns2`) and add a `<shared>`
  line to the template. Which shelf pair gives a non-empty answer?
- **The containment quirk:** read `src/sets.xsl` `set:leading` and the golden
  case `tests/cases/sets/leading.1`. Predict the output of
  `set:leading(a-items, b-items)` before you look — the naive reading of the
  spec and the libxml2 rule disagree, and the golden pins the libxml2 rule.
- **Peek ahead:** session 07 asks what a variable holding constructed elements
  actually *is* in XSLT 3.0 — and why `exsl:object-type` reports `node-set`
  for things XPath 3.1 calls temporary trees.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
