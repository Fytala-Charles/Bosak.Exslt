<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 02 — your first XSLT stylesheet">
  <br><br>
  <h1>Session 02 — Your First Stylesheet</h1>
  <p>Minimum, maximum, and the nodes that reach them: <code>math:min</code>, <code>math:max</code>, <code>math:highest</code></p>
</div>

> **Time:** ~45 minutes · **Prerequisites:** [session 01 — XSLT basics](../01-xslt-basics/README.md) and [session 00](../00-setup/README.md) for tooling; [XPath foundations sessions 1–2](../xpath/README.md) if you have never written XPath — the lesson is walkable without them, but the `select` attributes will make more sense
> **Vehicle:** EXSLT math module, tier 1 (`http://exslt.org/math`)

---

## 1. Why EXSLT is a good teacher

[EXSLT](http://exslt.org) was created in 2001 to give XSLT 1.0 the functions
everyone kept re-implementing: minimums, tokenizers, date arithmetic. Twenty
years later XSLT 3.0 grew native equivalents for many of them. That history
makes EXSLT a perfect textbook:

- Some functions are now **one-liners** over XPath 3.1 — ideal for learning
  the basics without fighting the problem.
- Others need **genuine algorithms** — recursion, scanning, calendar
  arithmetic — the real craft of XSLT.
- One (`dyn:evaluate`) is **impossible** in pure XSLT, which teaches you where
  the language ends.

This session's functions are the first kind. You will implement them in a
standalone stylesheet, and afterwards compare your work with the finished
library at `src/math.xsl`.

## 2. Your task

Open `starter/transform.xsl`. It already defines `math:min` and `math:max`
and calls both from a template — run the test and you will see it fail on the
third line of output:

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

(From the repository root: `dotnet test training/TrainingTests/TrainingTests.csproj`.)

Your job: implement **`math:highest`** — the function that returns the
*nodes* whose numeric value equals the maximum, not just the maximum itself.
Until you do, the `<highest>` element of the output is empty and the test
stays RED.

## 3. Reading the starter

Here is the starter, with the pieces you should understand line by line
before touching anything:

```xml
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:math="http://exslt.org/math"
                exclude-result-prefixes="xs math"
                version="3.0">
```

- `version="3.0"` declares the XSLT version — always on every stylesheet.
- `xmlns:math="http://exslt.org/math"` binds the EXSLT namespace to the
  `math` prefix. Note the URI is `http://exslt.org/...`: it is an identifier,
  not a website; your processor never fetches it.
- `exclude-result-prefixes="xs math"` keeps these namespace declarations out
  of your output document. Without it, the result would carry
  `xmlns:math="..."` on every element.

```xml
<xsl:template match="values">
  <result>
    <minimum><xsl:value-of select="math:min(value)"/></minimum>
    ...
```

- `match="values"` selects which input nodes this template handles. The
  engine walks the input document; whenever it meets a `<values>` element, it
  instantiates this template.
- `value` (no slash) is a *relative* XPath: "the child elements named `value`
  of the current node". It selects several elements at once — in XSLT 3.0 that
  is an ordinary **sequence**, no special type needed.

```xml
<xsl:function name="math:min" as="xs:double">
  <xsl:param name="nodes" as="node()*"/>
  <xsl:sequence select="if (empty($nodes)) then xs:double('NaN')
                        else min($nodes ! number(.))"/>
</xsl:function>
```

Four ideas in five lines:

1. `xsl:function` defines a callable function in the `math` namespace — the
   same name EXSLT callers have used since 2001.
2. `as="node()*"` types the parameter: a sequence (`*`) of nodes, possibly
   empty. `as="xs:double"` types the return value. Types are optional in
   XSLT but they turn confusing runtime behavior into clear error messages.
3. `$nodes ! number(.)` is the **map operator**: apply `number(.)` to every
   item in the sequence. `!` reads as "for each item, compute …". The result
   is a sequence of numbers, which feeds straight into `min()`.
4. `empty($nodes) → NaN` mirrors the EXSLT contract: *the minimum of an empty
   node set is `NaN`*, not an error. Functions you write should honor their
   spec's edge cases from day one.

`math:max` is the same function with `max()` instead of `min()`. When two
functions are identical except for one inner call, resist duplicating the
body for now — later sessions will teach you how XSLT factors such things.

## 4. The exercise: implement `math:highest`

`math:max` returns the **value**. `math:highest` must return the **nodes**
that hold that value — because a caller may need the position, attributes, or
children of the winners, not just their numbers. From the EXSLT spec:

> `math:highest(node-set)` returns the nodes in the node set whose value is
> the maximum value for the node set.

### What you know going in

- The input has ties on purpose: `11` appears twice, and **both** occurrences
  must appear in the output, space-separated.
- The golden output for the session input is:

  ```xml
  <result><minimum>4</minimum><maximum>11</maximum><highest>11 11</highest></result>
  ```

- The template already serializes your sequence:
  `<xsl:value-of select="math:highest(value)" separator=" "/>` — `separator`
  joins the string value of each returned node with a single space.

### Hints (progressive — try each before opening the next)

1. You already know how to compute the maximum value from inside a function:
   copy the `else` branch of `math:max`. Store it in a variable first so you
   can refer to it twice without recomputing.
2. You need a *predicate*: from `$nodes`, keep the items where
   `number(.)` **equals** the maximum. The XPath filter is written in square
   brackets right after the sequence it filters — the same `[...]` you have
   seen in `match` patterns.
3. Comparison operator: `=` compares sequences loosely; `eq` compares exactly
   one value to exactly one value and fails loudly otherwise. For one node
   against one number, prefer `eq`.
4. Empty input: with no nodes, there is nothing to return. Make sure your
   function returns the empty sequence (not an error, not `NaN` — a *node*
   function returns nodes) and convince yourself with an experiment: add
   `<highest><xsl:value-of select="math:highest(nothing)" separator=" "/></highest>`
   to the template and see what happens. Remove the line afterwards.
5. Still stuck? The finished library implementation is at
   `src/math.xsl` — look for `math:highest`. Read it, then close it and write
   your version from memory.

## 5. Checking your work

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

- `Starter_differs_from_golden` **passes** — good: it asserts your starter is still
  unsolved, guarding the exercise for the next learner.
- To check *your* implementation, paste it into the starter and watch the
  `<highest>` line of the test diff change. When your output equals
  `case/expected.xml`, you are done. (If you edited `starter/transform.xsl`
  directly, the `Starter_differs_from_golden` test will now fail — that failure means
  *success* for you; restore the stub when you finish the session so the
  exercise stays RED for the next learner.)

You can also run the transform by hand in VS Code with the Bosak extension,
using `input.xml` as the source document.

## 6. Compare with the library

Open `src/math.xsl` and find `math:highest`. You will see the library version
computes the maximum into a typed variable first, and guards the empty case
explicitly even though the predicate alone would survive it. Both are style
points: explicit guards document intent; a reader should not have to run the
edge case in their head. Worth adopting as a habit.

Also notice: `src/math.xsl` binds the XPath 3.1 math namespace to the prefix
`xmath` — the library is *all* tier-1 wrappers here, so the file is mostly
documentation of the form "EXSLT name → native XPath 3.1 equivalent". Your
session implemented the same functions from first principles, which is
exactly the migration story tier 1 exists for.

## 7. Go further

- **Implement `math:lowest`** (both the value-returning and node-returning
  versions) and add a `<lowest>` line to the template. The golden file does
  not pin it, so the test will not check it — extend `expected.xml` yourself
  and re-run.
- **Whitespace experiment:** indent `<xsl:value-of>` onto its own line inside
  `<highest>` and run the test. It now fails even though the values look
  right. Why? (Whitespace-only text nodes in a template are stripped by XSLT,
  but text nodes that mix content and whitespace are kept — the golden
  comparison is whitespace-sensitive inside elements. Keep value-producing
  instructions on one line, as the starter does.)
- **Peek ahead:** which session in the curriculum table of
  [`../README.md`](../README.md) teaches the techniques behind `str:padding`?
  Why is recursion needed at all in a language that has `for-each`?

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
