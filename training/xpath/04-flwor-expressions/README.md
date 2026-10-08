<div align="center">
  <img src="../../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala XPath foundations session 04 — FLWOR expressions">
  <br><br>
  <h1>XPath Session 04 — FLWOR Expressions</h1>
  <p>Variables, iteration, filtering, and sorting — XPath's programming syntax</p>
</div>

> **Time:** ~40 minutes · **Prerequisites:** [session 03 — functions &amp; operators](../03-functions-and-operators/README.md)
> **Exercise:** five slots, one skeleton — fill in each `()` and keep the markers

---

## 1. Variable bindings: `let`

```xpath
let $ids := string-join(//book/@id, ',') return concat('ids=', $ids)
```

- `let $x := expr` binds the value of `expr` to `$x` **for the rest of the
  FLWOR** — every clause after it, and the `return`. Note the `:=`, not `=`.
- Bindings are **immutable**: there is no reassignment, and `$x` is not a
  mutable variable but a name for a value. (The XSLT curriculum's functional-
  programming addendum develops exactly this idea — XSLT and XPath are
  expression languages, closer to a spreadsheet cell than to a `while` loop.)
- `$x` is referenced by name; it can hold any value — nodes, sequences, atoms.
- `let` shines when a sub-expression is expensive or long, and you want to
  name it once and use it two or three times — see slot 5's aggregate.

## 2. `for ... return` — iteration

```xpath
for $b in //book return concat($b/@id, ':', $b/title)
```

`for $x in SEQ return EXPR` evaluates `EXPR` once per item in `SEQ`, with
`$x` bound to that item, and concatenates the results in order. Nesting two
`for` clauses produces the **Cartesian product** — every pair — which is how
you generate combinations (conceptually; your engine limits you to one
clause, see §6, and slot 4 shows the workaround).

Relationship to what you know: `for $x in SEQ return EXPR` with no `where` or
`order by` is morally `SEQ ! EXPR-with-dollar-x` — session 3's simple map.
Choose `for` when the body is long enough to deserve a named variable;
choose `!` for one-liners.

## 3. `where` — filtering

```xpath
for $b in //book where xs:integer($b/stock) gt 0 return concat($b/@id, ':', $b/title)
```

`where` keeps a candidate only if its condition is true — the same test a
predicate in `[...]` performs (session 2), but written after the binding.
Both are fine; a predicate reads better when the filter *is* the selection
(`//book[xs:integer(stock) gt 0]/title`), while `where` reads better when the
filter is a side condition on a longer computation, especially one that uses
a `let`-bound intermediate. Note the output order is still **document
order** — `where` filters, it does not sort.

## 4. `order by` — sorting

Full XPath 3.1 sorts inside the FLWOR:

```xpath
for $b in //book
order by xs:integer($b/price) descending
return concat($b/@id, ':', $b/price)
```

Multiple keys are comma-separated (`order by $a descending, $b`), and
ordering is `stable` by default — ties keep their input order, which is why
session 2's document-order theme matters here. **Your engine cannot run this
yet** — see §6 for the workaround the exercise actually uses.

## 5. FLWOR vs `!` vs `/` — the takeaway

| idiom | shape | best for |
|---|---|---|
| `/` | navigation, step by step | selecting nodes; results doc-order, deduped |
| `!` | map one expression per item | short per-item computations; preserves order & duplicates |
| FLWOR | named bindings + optional where/sort | multi-step per-item logic, sorting, named intermediates |

## 6. Sidebar: your engine's limits (probe-verified)

Bosak 0.12.3-beta implements FLWOR **partially**. Two hard walls, both
caught at compile time:

- **No `order by` at all** — even a single-clause FLWOR fails (messages
  verbatim from this session's probes; the position varies with your
  expression):

  `Parse error at position 116: XPST0003: XPath does not allow an order by clause.`

- **One `for`/`let` clause per FLWOR** — a second clause fails:

  `Parse error at position 17: XPST0003: XPath does not allow multiple for/let clauses in a FLWOR expression.`

What works: a single `for` or `let` clause, optionally with `where`, plus
`return`; and **nested FLWORs** (one clause each) — slot 4's shape. That is
how the library itself copes: `src/strings.xsl` (`str:tokenize`) flattens
everything into single-clause `for ... return` expressions, and
`src/dates-and-times.xsl` (`date:difference`) wraps a multi-clause FLWOR in
`try { ... } catch * { '' }` so the function degrades gracefully where the
engine refuses the syntax.

Sorting without `order by`: the `fn:sort` function — XPath 3.1's other route
to sorted output — works, including its three-argument form with a **key
function**:

```xpath
reverse(sort(//book, (), function($b) { xs:integer($b/price) }))
```

Two traps in that one line, both probe-verified: `sort`'s key function gets
the *item*, so inside it you write `$b/price`, but after the sort you are
back to `.` (write `! concat(@id, ...)`); and `reverse(...)` must be followed
by `!`, not `/` — the path operator re-sorts nodes into document order,
silently undoing the reversal.

Elsewhere (Saxon, BaseX, every other engine) full FLWOR works as written in
§§2–4 — the concepts transfer even where this engine's parser stops.

## 7. Try it live

Create a scratch file `try.xpath` in the workspace root, put one expression in
it — e.g. `for $b in //book return concat($b/@id, ':', $b/title)` — save, and
run **Bosak: Evaluate XPath Expression** from the right-click menu or the
Command Palette (`F1`). The preview shows the result. Scratch files are free:
experiment until the concepts stick, then delete the file. (`try.xpath` is
not part of the graded exercise.)

Good experiments before you start:

- `for $b in //book where xs:integer($b/stock) gt 0 return $b/@id` — then the
  same as a bare path with a predicate. Same tokens?
- `reverse(//book) ! @id` versus `reverse(//book)/@id` — predict both.
- `let $n := count(//book) return $n + 1` — what breaks if you write `=` in
  place of `:=`?

## 8. The exercise

Open `starter/exercise.xpath`: one concatenation with five slots and
`'1:'`…`'5:'` markers, like sessions 2–3. Fill each `()` and keep everything
else byte-identical. The catalog is the session-3 bookshop, now with a
`<rating>` per book as well (1–5).

| Slot | Your expression should produce… |
|---|---|
| 1 | via `let`: the string `ids=` followed by all book ids comma-joined (`b1,b2,b3,b4,b5`) |
| 2 | via `for` + `where`: `id:title` for every book **that is in stock** (stock &gt; 0) |
| 3 | a price ranking, **most expensive first**: `id:price` for all five books — use `sort` + `reverse` + `!` (§6) |
| 4 | via a nested pair of single-clause FLWORs: each shelf name, then the ids of its books — `classics b1 b2 b3 scifi b4 b5` |
| 5 | via `let`: the string `total=` + the stock total, then `,avg-idiv=` + the integer average (total `idiv` count) |

### Hints (progressive)

1. Slot 1: `string-join` the `@id` attributes with `','`, bind that to a
   variable, then `concat('ids=', $yourvariable)` in the return. One clause.
2. Slot 2: the starter's slot already contains a working *selection* —
   `//book[xs:integer(stock) gt 0]/@id` — but it drops the titles. Rewrite as
   `for $b in ... where ... return concat(...)`: inside the return, `$b/...`
   reaches each book's own children.
3. Slot 2, engine reminder: `stock` needs the session-2 `xs:integer(...)`
   cast before `gt`.
4. Slot 3: `sort(//book, (), function($b) { ... })` sorts **ascending** by
   the key — the cheapest book first. Two ways to flip it: reverse the
   sorted sequence, or sort by a negated key. `reverse(...)` must be followed
   by `!`, never `/` — why? (§6.) And inside the `!`, the book is `.`: write
   `@id` and `price`, not `$b/...`.
5. Slot 4: the outer `for` walks shelves; its `return` may be a *sequence* —
   `(name-thing, (inner-FLWOR))`. The inner FLWOR iterates `$s/book` — the
   outer variable is visible inside.
6. Slot 5: bind the stock total once; compute the average **in the return**
   using the bound variable and `count(//book)`. You may not write a second
   `let` — one clause only (§6).
7. Still stuck? The reference answer is in `solution/exercise.xpath`. Read it,
   close it, write your own.

## 9. Checking your work

- `Solution_matches_golden` **passes** — that is the harness guarding the
  reference material for the next learner, not a verdict on your file.
- To check *your* answer, put your expressions into `starter/exercise.xpath`
  and re-run:

  ```bash
  dotnet test ../XPathTrainingTests/XPathTrainingTests.csproj
  ```

  (From the repository root:
  `dotnet test training/xpath/XPathTrainingTests/XPathTrainingTests.csproj`.)
  When the harness prints the golden tokens for your session, you are done.
  (As in the XSLT curriculum: if you edited the starter in place,
  `Starter_differs_from_golden` now failing means *you* succeeded — restore
  the skeleton for the next learner when you finish.)

## 10. Go further

- Slot 4's nested pair produces the Cartesian walk implicitly: outer shelf,
  inner book. What would `for $a in //shelf return for $b in //shelf return
  concat($a/@name, '>', $b/@name)` produce — and why is it *not* the
  four-pair product you might expect? (One clause per FLWOR; nest them.)
- `sort(//book, (), function($b) { xs:integer($b/rating) })` — three books
  tie at rating 5. Which order do they come out in, and what does that tell
  you about `fn:sort`'s stability?
- `every` and `some` (session 3's go-further) combine beautifully with
  `let`: `let $cheap := //book[xs:integer(price) lt 9] return every $b in
  $cheap satisfies xs:integer($b/stock) gt 0` — "all cheap books are in
  stock". Evaluate it on this catalog (it is false — which book is the
  counterexample?).
- Session 5 assembles everything: multi-step expressions over a richer
  document, then the bridge back into XSLT.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
