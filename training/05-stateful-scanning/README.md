<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 05 — stateful scanning">
  <br><br>
  <h1>Session 05 — Stateful Scanning</h1>
  <p>One pass, left to right: <code>str:replace</code></p>
</div>

> **Time:** ~60 minutes · **Prerequisites:** [session 03 — recursion as the basic loop](../03-recursion/README.md) and [session 04 — regular expressions](../04-regular-expressions/README.md); [session 00](../00-setup/README.md) for tooling
> **Vehicle:** EXSLT strings module, tier 2 (`http://exslt.org/strings`)

---

## 1. Why one `replace` cannot do it

`fn:replace($string, $pattern, $replacement)` handles exactly one pattern, and
XPath 3.1 offers no multi-pattern replacement at all. EXSLT's `str:replace`
takes a **list** of search strings and a pairwise list of replacements, and
its contract is subtly stateful — a single left-to-right pass in which the
position you have already reached is part of the answer:

- **Earliest position wins.** Where two search strings could match, the one
  starting further left is chosen — regardless of rule order.
- **Ties break by rule order.** Two matches at the *same* position go to the
  rule that comes first in document order.
- **No re-scanning.** Replacement text is emitted, never searched again. A
  match is consumed exactly once.
- **Pairwise by position.** Search string *i* pairs with replacement *i*; a
  missing replacement means the empty string.

Each rule alone looks like a job for `fn:replace`. Together, they are not —
and that gap is this session's lesson.

## 2. Your task

Open `starter/transform.xsl` and run the test:

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

(From the repository root: `dotnet test training/TrainingTests/TrainingTests.csproj`.)

The starter gives you the public `str:replace` wrapper and a **naive**
`str:replace-scan` that chains `fn:replace` calls — one rule at a time.
Your job: rewrite `str:replace-scan` as a genuine left-to-right scanner
(sections 4–5).

## 3. Reading the starter

`input.xml` holds three rules and three strings, each string designed to
expose one clause of the contract:

| Input text | What it proves |
|------------|----------------|
| `zabcz` with rules `ab→x`, `abc→[ABC]` | same-position overlap: `ab` and `abc` both start at position 2 — the earlier *rule* wins, so the result starts `zx…` |
| `abc and ab` | pairwise multi-rule replacement in one pass |
| `tab x` with rules `ab→x`, `x→*` | no re-scanning: the `x` produced by the first replacement must **not** be re-replaced by the third rule |

The given wrapper deserves a close look:

```xml
<xsl:function name="str:replace" as="text()">
  <xsl:param name="input" as="xs:string"/>
  <xsl:param name="search" as="xs:string*"/>
  <xsl:param name="replace" as="xs:string*"/>
  <xsl:variable name="result">
    <xsl:sequence select="str:replace-scan($input, $search, $replace)"/>
  </xsl:variable>
  <xsl:sequence select="$result/text()"/>
</xsl:function>
```

The declared return type is **`text()`**, not `xs:string`. EXSLT was born in
XSLT 1.0, where the result was a result-tree fragment and legacy call sites
run path steps on it (e.g. `$result/self::text()`). Running the scan inside a
variable and returning `$result/text()` keeps that contract in XSLT 3.0. The
session's golden only uses the value, but the library keeps the full contract
— and so does your solution, since the wrapper is given.

Engine quirks (session 04, section 3) apply as usual: no `analyze-string`
content instructions inside the function, no multi-clause FLWOR, and the
starter's `fn:replace` calls are safe here only because none of the search
strings contain regex metacharacters — one more quiet flaw of the naive
approach.

## 4. The naive attempt, and why it fails

The starter applies the rules **in turn**:

```
replace(replace(replace($s, "ab", "x"), "abc", "[ABC]"), "x", "*")
```

Trace `tab x` by hand. First pass: `ab` at position 2 becomes `x` →
`tx x`. Second pass: the *inserted* `x` (and the original one) both become
`*` → `t* *`. But the contract says the replacement text is never re-scanned:
the inserted `x` must survive, and only the original `x` at position 5 is
replaced → `tx *`. Chaining re-scans what a single pass must leave alone.

The mirror-image flaw shows on `zabcz`: chained application lets a *later*
rule rewrite earlier output (`x`→`*`), while the contract's
earliest-position/tie-break rules decide purely from the input string.

A second naive idea fails differently: split on all search strings with
`fn:tokenize` and reassemble with replacements. But `tokenize` returns *flat
pieces* — it cannot tell you which separator produced which piece, adjacent
separators collapse (with this engine's zero-length-token quirk, session 04),
and overlapping candidates such as `ab`/`abc` have no single separator to
split on. The pieces alone do not carry enough state; the scan must look at
the string itself.

## 5. The exercise: implement `str:replace-scan`

The real design is session 03's tail recursion with a twist: instead of an
accumulator parameter, the shrinking `$remaining` string **is** the state —
everything before it has been emitted and is final. Each round:

1. **Find candidates:** for every rule, where would it match in `$remaining`?
2. **Pick the winner:** the smallest position; ties to the earliest rule.
3. **Emit and advance:** literal text before the match + the paired
   replacement, then recurse on the string *past* the match.

### Hints (progressive — try each before opening the next)

1. Position arithmetic from session 03: if `contains($remaining, $s)` then the
   match starts at
   `string-length(substring-before($remaining, $s)) + 1`. You need this for
   **every** rule — map over the rule positions with
   `for $j in 1 to count($search) return …` (single `for` clause, per the
   engine quirk). This *positional mapping* is how `$search[$j]` stays paired
   with `$replace[$j]`.
2. A candidate needs two facts: the rule index and its position. A one-line
   **map** holds both: `map { 'i': $j, 'pos': … }`, read back with `$m?i` and
   `$m?pos`. Rules that do not match contribute nothing — the `if … then map
   … else ()` shape.
3. The winner: `min($candidates ! (?pos))` is the earliest position;
   `($candidates[?pos eq $first-pos])[1]` is the first candidate at that
   position — the tie-break. `[1]` works because the `for` loop generated the
   maps in rule order.
4. Emit `concat(substring($remaining, 1, $first-pos - 1), $replacement, …)`
   and recurse on `substring($remaining, $first-pos + string-length($search[$i]))`.
   The replacement for rule *i* is `$replace[$i]` — guarded, because a shorter
   replace list means the empty string.
5. Base case: no candidates → return `$remaining` (the untouched tail).
   An empty input string gets there immediately.
6. Predict before you run: `zabcz` must become `zxcz` — the tie at position 2
   goes to `ab`, and the emitted `x` is never re-scanned by rule 3.
7. Still stuck? `src/strings.xsl` — look for `str:replace` and its
   `str:replace-scan` helper. Read it, close it, write your version from
   memory.

## 6. Checking your work

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

- `Starter_differs_from_golden` **passes** — good: it asserts your starter is still
  unsolved, guarding the exercise for the next learner.
- To check *your* implementation, paste it into the starter and watch the
  `<overlap>` and `<rescan>` lines of the test diff. When your output equals
  `case/expected.xml`, you are done. (If you edited `starter/transform.xsl`
  directly, the `Starter_differs_from_golden` test will now fail — that failure means
  *success* for you; restore the stub when you finish the session so the
  exercise stays RED for the next learner.)

Note that the naive starter already produces the correct `<pairwise>` line —
that input does not exercise either flaw. Two of the three inputs are where
the lesson lives; a correct scanner gets all three for free.

You can also run the transform by hand in VS Code with the Bosak extension,
using `input.xml` as the source document.

## 7. Compare with the library

Open `src/strings.xsl` and find `str:replace` / `str:replace-scan`. If your
solution went green, you have re-derived the library's exact architecture:
candidate maps carrying the rule index, `min` over positions, `[1]` for the
tie-break, `concat` + recurse past the match. Two details worth adopting as
habits:

- The **index rides inside the map**, so rules that do not match cannot shift
  the `$search`/`$replace` positional pairing. Filtering *first* and pairing
  afterwards is the classic way this function breaks; carrying the index
  through is the fix.
- The comment on the empty search string is not dead code: per the libxslt
  reference, an empty search string inserts its replacement *between*
  characters (position 2), which is why the `if ($from[$j] eq '')` branch
  exists. Edge cases you do not hit today are still part of the contract.

## 8. Go further

- **Adjacent and empty:** predict, then test with template lines:
  rules `aa→b`, `a→c` on `aaa` (earliest position wins — which rule fires
  first, and what is left?); a rule with an empty search string on `abc`
  (the between-characters quirk); more search strings than replacements.
- **The empty-tail trace:** run `str:replace('ab', 'ab', 'x')` in your head —
  the recursion must advance exactly *past* the match, or it loops. Add
  `<xsl:message>` of `$remaining` (temporarily) and watch each round.
- **Efficiency thought:** each round rescans the tail with `contains` per
  rule, so the scan is roughly quadratic — fine at training scale, worth
  knowing about at log-file scale. XSLT's answer to that is `xsl:analyze-string`
  (session 04, section 8) or streaming; there is no pure-XSLT linear fix here.
- **Peek ahead:** session 06 leaves strings behind — `set:has-same-node` asks
  whether two node *sets* share a node, which needs a comparison operator
  stricter than `=`. Which one?

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
