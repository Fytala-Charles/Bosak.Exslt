<div align="center">
  <img src="../../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala XPath foundations session 05 — putting it together">
  <br><br>
  <h1>XPath Session 05 — Putting It Together</h1>
  <p>Composition is the skill: paths, predicates, functions, <code>!</code>, and FLWORs in one expression — then across the bridge into XSLT</p>
</div>

> **Time:** ~40 minutes · **Prerequisites:** [sessions 01–04](../README.md)
> **Exercise:** five slots, each braiding several sessions at once

---

## 1. The real skill was never the syntax

Sessions 01–04 each isolated one idea: paths, predicates and sequences,
functions and operators, FLWORs. Real expressions braid them — a `let` that
feeds a predicate, a `sort` whose key function converts, an `if` inside a
`concat` inside a `!`. Nothing in this session is new syntax; everything is
the judgement call of *which idiom carries which part*.

A composition checklist that works for almost any expression:

1. **What shape is the answer?** One node? A sequence of strings? A boolean
   report? The shape chooses the outermost operator (`/`, `!`, `for`, `let`).
2. **Which steps select?** Write the path first; keep it precise (session 1).
3. **Which filters shrink it?** Predicates in the path, or a `where` clause if
   the condition is a side test on a longer computation (session 2/4).
4. **Where do values need converting?** Untyped element text: `xs:integer(...)`,
   `number(...)` — before any comparison or arithmetic (sessions 2–3).
5. **Where do items need transforming?** One output per input, unchanged
   order: `!`. A named intermediate or a sort: FLWOR (sessions 3–4).
6. **How is it formatted?** `concat` / `string-join` at the outermost layer,
   never in the middle of navigation.

## 2. The engine's quirks are part of the craft now

By this point they should be reflexes, so the exercise assumes them without
comment: explicit `xs:integer(...)` casts for untyped numbers; one `for`/`let`
clause per FLWOR (`let $in := ... return ...` instead of stacked lets); `!`
after `reverse`, never `/`; `fn:sort` with a key function instead of
`order by`; `tokenize` results may carry zero-length tokens.

## 3. The bridge: this is what every `select` attribute is

The XSLT curriculum's
[session 02](../../02-first-stylesheet/README.md) builds `math:highest`. Its
solution contains this line (`solution/transform.xsl`):

```xpath
if (empty($nodes)) then xs:double('NaN') else max($nodes ! number(.))
```

Decompose it — you now own every piece:

- `if … then … else` — session 3's classifier shape, here guarding an edge
  case rather than labelling items.
- `empty($nodes)` — session 2's emptiness test; `()` is a normal value.
- `$nodes ! number(.)` — session 3's map: convert *every* item, preserving
  order and duplicates (and `.` is the mapped item).
- `max(...)` — session 3's aggregation over that map's results.
- And its sibling line, `$nodes[number(.) eq $max]` — session 2's predicate
  with session 3's value comparison — is how the highest *node* is selected
  after the highest *value* is known.

Every `select`, `match`, and `test` attribute in the XSLT curriculum is one
of these expressions. That is the whole bridge. When
[the curriculum index](../../README.md) says its sessions 1–3 build on this
track's sessions 1–2, it is promising that you can already read lines like
the one above — and after this session, you can write them.

## 4. Try it live

Create a scratch file `try.xpath` in the workspace root, put one expression in
it, save, and run **Bosak: Evaluate XPath Expression** from the right-click
menu or the Command Palette (`F1`). Scratch files are free: experiment until
the concepts stick, then delete the file. (`try.xpath` is not part of the
graded exercise.)

Good warm-ups before you start:

- `//book[xs:integer(stock) eq max(//book/xs:integer(stock))]/title` — the
  bestseller, title only. Then wrap it into the full `bestseller:` line.
- `count(//shelf/book) eq count(//book)` — true here. What document change
  would flip it to false, and which slot does that idea appear in?

## 5. The exercise

Open `starter/exercise.xpath`: one concatenation with five slots and
`'1:'`…`'5:'` markers. Fill each `()` and keep everything else byte-identical.
The catalog is the session-4 bookshop with a `<year>` added — the culmination
document, unchanged from here on.

| Slot | Your expression should produce… | Techniques braided |
|---|---|---|
| 1 | one line `bestseller:id:title:stock` for the in-stock book with the most copies | `let` · aggregate · predicate with `eq` · `!` · `concat` |
| 2 | per shelf, `name:bookcount:totalstock` | single-clause FLWOR · `count` · `sum` · nested relative paths |
| 3 | every book as `id:rating`, **best first**, with a `*` after the rating when it equals the top rating | `sort` + key function · `reverse` · `!` · `if` inside `concat` |
| 4 | five validation booleans: every book is on a shelf · no negative stock · some id matches each of the five expected ids · **every** required id in `('b1','b6')` is present · a post-1900 magazine exists | `count` compare · `not` + predicate · general `=` · `every … satisfies` · `exists` |
| 5 | one string: `books=5;in-stock=3;top-rating=5;cheapest-in-stock=Emma` | `let` bound sequence reused three ways · four aggregates · predicate · `string-join` |

### Hints (progressive)

1. Slot 1: bind `max(...)` to a variable first — you need its value inside
   the predicate. `eq`, not `=`, against a single number. The `!` then maps
   the (one) matching book to the formatted line; inside it, `@id`, `title`,
   `stock` are all relative to that book.
2. Slot 2: one `for` clause, everything else in the `return`: `concat` three
   things — the shelf's `@name`, `count($s/book)`, and a `sum` over
   `$s/book/xs:integer(stock)`. No second clause needed.
3. Slot 3: sort **ascending** by rating, then flip with `reverse` — and
   remember what `reverse(...) / ...` would silently do (session 4, §6). The
   tie marker is an `if` **inside** the `concat`, after the rating: books
   whose rating equals `max(//book/xs:integer(rating))` get `'*'`, others
   get the empty string. Watch the tie order among the three 5-rated books.
4. Slot 4: item 3 is existential (`=`), item 4 is *universal* — that is the
   difference between "some id matches" and "every required id exists", and
   only one of them is true for `('b1', 'b6')` on this catalog.
5. Slot 5: bind the in-stock books **once** to `$in`; then the four pieces
   are independent — two `count`s, a `max`, and a last `concat` whose title
   comes from `$in[...]` filtered by `eq min($in/xs:integer(price))`.
6. Still stuck? The reference answer is in `solution/exercise.xpath`. Read it,
   close it, write your own.

## 6. Checking your work

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

## 7. Go further — across the bridge

You have now completed the XPath foundations track. The natural next step is
the [XSLT curriculum](../../README.md), whose session 02 builds `math:highest`
— the line decomposed in §3 — from scratch. Before you go:

- Open `training/02-first-stylesheet/solution/transform.xsl` and read the two
  `select` attributes in `math:highest` aloud in the vocabulary of sessions
  01–04. Every token should have a name now.
- The `$nodes[number(.) eq $max]` pattern — value selected *by* an aggregate —
  reappears in slot 1 of this very exercise. Write the XSLT-curriculum
  version of slot 3 as a `select` attribute on an `xsl:for-each`; what is the
  one thing XSLT adds that the raw expression cannot do?
- Revisit this track's catalog anytime: `05-putting-it-together/input.xml` is
  rich enough to host every technique in all five sessions.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
