<div align="center">
  <img src="../../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala XPath foundations session 03 — functions and operators">
  <br><br>
  <h1>XPath Session 03 — Functions &amp; Operators</h1>
  <p>The <code>fn:*</code> toolbox, arithmetic and comparisons, the <code>!</code> map, and <code>if</code> expressions</p>
</div>

> **Time:** ~40 minutes · **Prerequisites:** [session 02 — predicates &amp; sequences](../02-predicates-and-sequences/README.md)
> **Exercise:** six slots, one skeleton — fill in each `()` and keep the markers

---

## 1. The `fn:*` library

Everything XPath can *do* to values lives in one big function library defined
by the spec — the **XPath Functions & Operators** recommendation. Its
functions live in the namespace `http://www.w3.org/2005/xpath-functions`,
conventionally prefixed `fn:`. In practice you **never write the prefix**:
`fn` is the default function namespace, so `count(...)` already means
`fn:count(...)`. (This is why your own XSLT functions need a declared
namespace — anything unprefixed is assumed to be `fn:*`.)

The library is large; learn the shape, then a workhorse subset:

- **Strings** — `concat` (variadic: `concat(@id, ':', title)`), `substring`
  (1-based: `substring(title, 1, 5)`), `string-length`, `upper-case`,
  `lower-case`, `contains`, `starts-with`, `ends-with`, `normalize-space`
  (trims and collapses whitespace runs), `tokenize`, `string-join`.
- **Numerics** — `abs`, `round` (halves go up: `round(2.5)` is 3),
  `floor`, `ceiling`, `sum`, `min`, `max`, `avg`, `format-number`.
- **Nodes** — `name`, `local-name`, `count`, `position`, `last`
  (session 2: positional predicates), plus the document-wide `doc`,
  `collection` you meet outside this sandbox.

One engine quirk you *will* trip over, so learn it now: on Bosak,
`tokenize('a,,b', ',')` keeps the empty string between the two commas —
three items, not two. (`count(...)` says 3.) Filter zero-length tokens out
yourself when splitting ragged data.

## 2. Arithmetic & comparisons

Arithmetic is ordinary: `+ - * div idiv mod`. (`div` is always `/`-for-numbers
— `/` itself stays reserved for paths; `idiv` truncates to an integer.)
Comparisons come in two families, and the difference matters:

- **Value comparisons** — `eq ne lt le gt ge`. Both operands must be *single*
  items. `//book[1]/@id eq 'b1'` is fine; `//book/@id eq 'b1'` raises
  `XPTY0004` ("operand is a sequence with more than one item") — `eq` refuses
  to guess which item you meant.
- **General comparisons** — `= != < <= > >=`. These are **existential**: `A =
  B` is true if *any* item in `A` pairs with *any* item in `B`. So
  `//book/title = 'Dune'` asks "does some book have this title?" — true —
  and `//book/@id = ('b2', 'b5')` asks "does some id match either value?".

Two established gotchas (session 2 documented the first): schema-less element
text does not auto-convert to numbers on this engine — write
`xs:integer(price) gt 9`, not `price gt 9`; and general comparison is not
case-folding: `= 'Dune'` and `= 'dune'` are different questions.

## 3. `!` — the simple map operator

Session 2's `/` *navigates*: each step reaches nodes from nodes, results are
merged in document order. `!` *maps*: it evaluates its right-hand expression
once per item on the left, with `.` bound to that item, and concatenates the
results in order:

```xpath
//book/title ! upper-case(.)        (one upper-cased title per title node)
(1, 2, 3) ! (. * 10)                (10 | 20 | 30 — atoms in, atoms out)
```

Rules of thumb:

- `/` needs *path steps*; `!` takes *any* expression — the only way to map a
  computation over atomic values like `(1, 2, 3)`.
- `/` dedupes and re-sorts **nodes** by document order; `!` never re-sorts and
  keeps whatever each evaluation produced, duplicates included.
- Honest fine print, verified on this engine: when every input item is a
  *distinct node* and the expression returns one atomic value per item, `/`'s
  final step and `!` produce identical results — `//book/title/substring(.,
  1, 5)` and `//book/title ! substring(., 1, 5)` both give
  `Emma | Persu | Frank | Dune | Frank`. The operator earns its keep the
  moment the input is atomic, or one item maps to several.

## 4. `if` — an expression, not a statement

```xpath
if (xs:integer(stock) gt 0) then concat(@id, ':in') else concat(@id, ':out')
```

- It is an **expression**: it yields a value, so it can sit anywhere a value
  can — inside a sequence, a function argument, a predicate, or the right
  side of `!`.
- The **else is mandatory**, even if empty: `else ()`. There is no statement
  form of `if` in XPath; nothing "does" anything, everything *evaluates*.
- The classic shape is the **classifier**: one input item → one label. That is
  a map (one result per item), not a filter (a subset of the input) — part 5
  tests whether you feel the difference.

## 5. Try it live

Create a scratch file `try.xpath` in the workspace root, put one expression in
it — e.g. `(1, 2, 3) ! (. * 10)` — save, and run **Bosak: Evaluate XPath
Expression** from the right-click menu or the Command Palette (`F1`). The
preview shows the result. Scratch files are free: experiment until the
concepts stick, then delete the file. (`try.xpath` is not part of the graded
exercise.)

Good experiments before you start:

- `//book/title = 'Dune'` versus `//book/title eq 'Dune'` — one renders
  `true`, the other raises `XPTY0004`. Why?
- `tokenize('a,,b', ',')` — how many items does the evaluator show?
- `//book/title/substring(., 1, 5)` versus `//book/title ! substring(., 1, 5)`
  — predict, then confirm they match, then read §3's fine print again.

## 6. The exercise

Open `starter/exercise.xpath`: one concatenation with six slots and `'1:'`
…`'5:'` markers, exactly like session 2. Fill each `()` and keep everything
else byte-identical. The catalog is the session-2 bookshop grown a `<stock>`
element per book — total copies on hand, where `0` means out of stock. Two
books are out of stock: b2 and b5.

| Slot | Your expression should produce… |
|---|---|
| 1 | one label per book: `id`, then its title's first letter upper-cased, then its title's length — joined with `:` (the last step of a path may be a function call) |
| 2 | the sequence: total copies in stock, the largest single stock count, the total modulo the number of books |
| 3 | the sequence: is any title `Dune`? is any title `dune`? does any id equal `b2` or `b5`? how many books are out of stock? |
| 4 | via `!`, one label per book: `id:UPPERCASE-TITLE` |
| 4b | via `!`, the first five characters of every title — watch what happens to the two Frankensteins |
| 5 | via `!`, one `id:in` or `id:out` label **for every book**, depending on its stock |

### Hints (progressive)

1. Slot 1: `concat` takes any number of arguments. `substring(title, 1, 1)`
   is the first character (positions are 1-based). A path's last step can be
   the function call itself — no `!` needed.
2. Slot 2: `sum` and `max` need numbers; session 2's gotcha applies to
   `<stock>` exactly as it did to `<price>`. `mod` sits between the two
   operands like `+`.
3. Slot 3: all four items are answers to yes/no-or-how-many questions. Three
   of the expressions are *comparisons* (they render `true` or `false` on
   their own); the last one needs `count(...)` around a filtered path. Which
   comparison family accepts a multi-item left side?
4. Slot 4: `!` rebinds `.` per book, so `concat(@id, ...)` inside the map
   sees that book's attributes and children.
5. Slot 4b: two *different* books share a title. `!` keeps one result per
   input item — count your tokens before you celebrate.
6. Slot 5: a predicate filter (`//book[...]/@id`) selects a *subset of nodes*
   and would silently drop the out-of-stock books. The exercise wants a label
   for **every** book — that is a map. And the engine will not let you write
   `if` without its `else` — what should an out-of-stock book evaluate to?
7. Still stuck? The reference answer is in `solution/exercise.xpath`. Read it,
   close it, write your own.

## 7. Checking your work

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

## 8. Go further

- "Are *all* titles `Dune`?" is not the negation of `=`'s existential answer
  — it needs its own quantifier: `every $t in //book/title satisfies $t eq
  'Dune'`. Its partner is `some ... satisfies ...`. Write the "no two books
  share a title" test with `every` and `=` — it fails on this catalog; which
  pair breaks it?
- `(10, 25, 40) ! (. idiv 10)` — there is no way to write this with `/`.
  Convince yourself why.
- `normalize-space('  Emma   Woodhouse ')` — when does this save you? (The
  training catalog keeps titles single-word so rendered tokens stay
  unambiguous; real documents are not so tidy.)
- `distinct-values(//book/title)` finally collapses the duplicate
  Frankensteins — the star session 2 promised. Try it now: it renders
  `Emma | Persuasion | Frankenstein | Dune`. It returns in session 4, where
  FLWOR expressions give it a real workout.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
