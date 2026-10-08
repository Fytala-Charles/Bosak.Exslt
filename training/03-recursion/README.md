<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 03 — recursion as the basic loop">
  <br><br>
  <h1>Session 03 — Recursion as the Basic Loop</h1>
  <p>Building strings one step at a time: <code>str:padding</code>, <code>str:align</code></p>
</div>

> **Time:** ~60 minutes · **Prerequisites:** [session 02 — your first stylesheet](../02-first-stylesheet/README.md) and [session 00](../00-setup/README.md) for tooling; [XPath foundations sessions 1–2](../xpath/README.md) if you have never written XPath
> **Vehicle:** EXSLT strings module, tier 2 (`http://exslt.org/strings`)

---

## 1. Why a functional language loops by calling itself

Session 02 built strings with `concat` and sequences. This session builds a
string of a **given length** — ten dashes, a 12-character name field — and for
that you need a loop. But XSLT has no loop that accumulates:

- `xsl:for-each` *visits* a sequence and instantiates its content once per
  item. It never hands you a running result. You cannot write
  "for each of 12: append a dash to $s" — variables in XSLT are **immutable**:
  once `<xsl:variable name="s" .../>` has a value, no instruction can change it.
- There is no `+=`, no `StringBuilder`, no mutable cell.

What a functional language offers instead is **recursion**. To build ten
dashes:

1. If you already have ten characters, you are done.
2. Otherwise, append one dash to what you have, and ask yourself again for the
   rest.

The function calls itself with a *smaller problem* each time (one character
closer to the goal) and an **accumulator** — a parameter carrying the string
built so far. When the goal is reached, the accumulated value is the answer.
This shape, where the recursive call is the last thing the function does, is
called **tail recursion**, and it is the basic loop of XSLT. Every scanning,
searching, and building function in the EXSLT library — including
`str:decode-uri`, which you will meet again in this session's module — is this
pattern with different arithmetic inside.

## 2. Your task

Open `starter/transform.xsl`. Run the test and you will see it fail:

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

(From the repository root: `dotnet test training/TrainingTests/TrainingTests.csproj`.)

This session has **two exercises**, and the second builds on the first:

1. **`str:padding($length, $chars)`** — return a string of exactly `$length`
   characters made by repeating `$chars` (exercise 1, section 4).
2. **`str:align($string, $padding, $alignment)`** — place a string inside a
   field of a given width: left, right, or centered (exercise 2, section 5).

Until both are implemented, the `<title>`, `<row>`, and `<rule>` lines of the
report come out wrong and the test stays RED.

## 3. Reading the starter

The template formats a small score table from `input.xml`:

```xml
<xsl:template match="scores">
  <report>
    <title><xsl:value-of select="str:align('High Scores', str:padding(25, '-'), 'center')"/></title>
    <xsl:for-each select="player">
      <row><xsl:value-of select="str:align(@name, str:padding(12), 'left')"/><xsl:value-of select="str:align(@points, str:padding(6), 'right')"/></row>
    </xsl:for-each>
    <rule><xsl:value-of select="str:padding(18, '=-')"/></rule>
  </report>
</xsl:template>
```

- Functions compose: `str:padding(25, '-')` produces the 25-dash field, and
  `str:align` centers the title inside it. `str:padding(12)` with one argument
  pads with spaces — see below.
- The two `xsl:value-of` instructions inside `<row>` sit on one line on
  purpose: whitespace between them would become part of the row text (this was
  the session 02 whitespace experiment).
- The calls are deliberately varied: multi-character pads (`'=-'`), a centered
  title, a right-aligned column. The golden output pins all of it.

Two definitions are given and should be studied, not changed:

```xml
<xsl:function name="str:padding" as="xs:string">
  <xsl:param name="length" as="xs:integer"/>
  <xsl:sequence select="str:padding($length, ())"/>
</xsl:function>
```

This is how XSLT spells a **default parameter**. `xsl:param` has no default
value, so the short form of a function is a second definition with fewer
arguments that supplies the default (`()` = "pad with spaces") and delegates to
the full form. The same pattern appears in `str:align`'s two-argument form,
where the missing alignment means "left".

## 4. Exercise 1: implement `str:padding` — the naive attempt first

The starter currently contains the obvious non-recursive attempt:

```xml
<xsl:sequence select="substring($pad, 1, $length)"/>
```

Read it until you see the flaw. `substring` can **cut** `$pad` down to any
length up to what it already has, but it cannot create characters that are not
there. `substring('-', 1, 25)` is `'-'`, not 25 dashes — the starter's title
comes out as `High Scores-`. No XPath function repeats a string, and (per
section 1) no XSLT instruction can accumulate one in a variable. Repetition
requires calling a function again.

### What you know going in

- The EXSLT contract: `str:padding` returns a string of **exactly** `$length`
  characters, measured in characters, built by repeating `$chars`. `$chars`
  may be several characters long (`'=-'` → `=-=-=-=-=-=-=-=-=-`): repeat the
  whole string, then truncate to the exact length.
- Golden output lines that depend on this exercise: the `<title>` dashes,
  every gap inside `<row>`, and the whole `<rule>`.

### Hints (progressive — try each before opening the next)

1. Follow the two-step shape from section 1. You need a **worker** function
   with one more parameter than the public one — the accumulator, the string
   built so far. The public two-argument `str:padding` normalizes `$chars`
   (empty means a space) and starts the worker with the accumulator at `''`.
2. In the worker, the recursive step appends and shrinks the problem in one
   expression: `concat($built, $chars)` is the new accumulator, and the same
   function is called again with it.
3. The stop condition compares `string-length($built)` against `$length`. When
   you stop, return `substring($built, 1, $length)` — not `$built` itself. Why?
   Because the last append may have overshot: padding of length 5 from `'abc'`
   builds `'abcabc'` and must return `'abcab'`.
4. Lengths 0 and negative: make sure the function returns `''` without
   recursing. Convince yourself with an experiment — add
   `<x><xsl:value-of select="str:padding(0)"/></x>` to the template. Remove it
   afterwards.
5. Still stuck? The finished library implementation is at
   `src/strings.xsl` — look for `str:padding`. Read it, then close it and write
   your version from memory. (Spoiler: it does not use recursion — section 7
   explains why that is fine.)

## 5. Exercise 2: implement `str:align`

The starter's `str:align` stub always left-aligns. From the EXSLT spec:

> `str:align(string, padding, alignment)` returns the string aligned within
> the padding string; `alignment` may be `'left'`, `'right'`, or `'center'`.

The **padding string defines the width**: `str:align('Ada', str:padding(12))`
must return `'Ada'` followed by 9 spaces — a 12-character field. Per the spec:

- the string **longer** than the padding is **truncated** to the padding length;
- a shorter string gets the missing characters from the padding side(s);
- center alignment puts the odd extra character on the **right**.

### Hints (progressive — try each before opening the next)

1. Compute two numbers first: the target width (`string-length($padding)`) and
  the gap to fill (width minus `string-length($string)`). If the gap is zero
  or negative, one `substring` handles the truncation rule.
2. Right alignment is `str:padding($gap, $padding)` placed **before** the
   string — reuse exercise 1; do not rebuild repetition logic here. Note what
   passing the whole `$padding` (not just its first character) buys you: with
   `'=-'` as the field, the fill continues the `=-` rhythm.
3. Center: split the gap with `idiv 2` (integer division). The left share
   floors the division, so an odd gap leaves the extra character on the right —
   exactly what the spec asks. Fill left and right separately with
   `str:padding`.
4. The default branch (empty or unrecognized `$alignment`) is left alignment —
   the starter already shows that shape.
5. Still stuck? `src/strings.xsl` — look for `str:align`.

## 6. Checking your work

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

- `Starter_differs_from_golden` **passes** — good: it asserts your starter is still
  unsolved, guarding the exercise for the next learner.
- To check *your* implementation, paste it into the starter and watch the
  `<title>`, `<row>`, and `<rule>` lines of the test diff. When your output equals
  `case/expected.xml`, you are done. (If you edited `starter/transform.xsl`
  directly, the `Starter_differs_from_golden` test will now fail — that failure means
  *success* for you; restore the stub when you finish the session so the
  exercise stays RED for the next learner.)

You can also run the transform by hand in VS Code with the Bosak extension,
using `input.xml` as the source document.

## 7. Compare with the library

Open `src/strings.xsl` and find `str:padding`. Surprisingly, the library
version contains **no recursion**: it builds the string with
`(1 to ($length idiv string-length($pad) + 1)) ! $pad` inside a `string-join`,
then truncates with `substring`. That works because XPath 3.1 has a range
operator (`1 to N`) that XSLT 1.0 lacked — one of the reasons EXSLT functions
shrink to one-liners in modern XSLT.

So why learn the recursive form? Two reasons. First, the range trick only
exists when you can *count* the repetitions up front; the moment a loop's
continuation depends on what it has already seen — scanning `str:decode-uri`
for a `%`, the left-to-right replacement pass in `str:replace` — counting
upfront is impossible and recursion is the only loop left. Session 05 builds
exactly that scanner. Second, engines differ: a portable stylesheet cannot
assume every processor optimizes deep recursion, but the tail-recursive shape
you wrote today is what every XSLT engine since 1999 handles well.

Notice also how `str:align` in the library fills its gaps with `substring` of
the padding directly instead of calling `str:padding`. Both readings are the
same semantics — the fill of a 7-character gap from `'=-'` is `'=-=-=-='`
either way. Composition is a style choice; the spec's contract is what both
versions honor.

## 8. Go further

- **Boundary experiments:** predict the result, then add a line to the
  template to test: `str:padding(6, 'ab')` (overrun truncation),
  `str:padding(4, 'abcdef')` (cut-down), `str:align('unbelievably long string',
  str:padding(8, '.'))` (truncation branch), and `str:align('ab',
  str:padding(5), 'centre')` (British spelling, odd gap).
- **Trace the loop:** add `<xsl:message select="$built"/>` inside your worker
  (temporarily!) and run the transform to see the accumulator grow call by
  call.
- **Implement `str:align` without `str:padding`** — fill the gaps with
  `substring` of the padding string the way the library does. Which version do
  you find easier to read, and why?
- **Peek ahead:** session 05 replaces several search strings in a single
  left-to-right pass. Why can't that be written as a `1 to N` range the way
  the library's `str:padding` is?

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
