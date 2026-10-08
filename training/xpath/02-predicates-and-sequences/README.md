<div align="center">
  <img src="../../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala XPath foundations session 02 — predicates and sequences">
  <br><br>
  <h1>XPath Session 02 — Predicates &amp; Sequences</h1>
  <p>Filtering with <code>[...]</code>, and combining results without losing any</p>
</div>

> **Time:** ~40 minutes · **Prerequisites:** [session 01 — values &amp; paths](../01-values-and-paths/README.md)
> **Exercise:** six expressions, one skeleton — fill in each `()` and keep the markers

---

## 1. What a predicate is

A step selects *all* the nodes its axis and name test reach. A **predicate** —
the `[...]` at the end of a step — filters that set, keeping only the nodes for
which the expression inside is **true**:

```xpath
//book[year lt 1900]
```

Read it as two phases. First `//book` finds every book (five of them). Then,
for **each book in turn**, the predicate is evaluated with that book as the
context item (`.`), and a book stays if the result is true. Inside the
brackets, paths are relative to the candidate node: `year` means "my `year`
child", so the full form is `//book[./year lt 1900]`.

The predicate expression can be anything — comparisons, function calls, paths,
even nested predicates. What matters is how its result is interpreted (section
3).

## 2. Positional predicates: the `[1]` trap

A **numeric** predicate means "keep the item at that position" — but positions
reset for every candidate list. That leads to the most-quoted XPath surprise:

```xpath
//book[1]        (*not* what it looks like)
(//book)[1]      (this is)
```

- `//book[1]` expands to `/descendant-or-self::node()/book[1]`: within **each
  parent**, keep the first book. Two shelves in `input.xml` ⇒ two books.
- `(//book)[1]` first builds the sequence of *all* books, *then* applies `[1]`
  to that whole sequence ⇒ exactly one book, the first in document order.

So "the first of everything" is `(//book)[1]`, and "the first within each
group" is `//shelf/book[1]`. The word *first* is ambiguous in English; in
XPath it is a predicate on a node list, and you must always ask *which list*.

Related: `last()` is a function returning the context list's size, so
`//shelf/book[last()]` keeps the last book *of each shelf*. Notice the pattern:
positional predicates are always answered **per parent**, because a step
produces one candidate list per input node.

## 3. Numeric vs boolean predicates

How the predicate result is read depends on its type:

- **Numeric** — `book[1]`, `book[last()]`, `book[position() gt 2]`: keep the
  item whose position equals the number (or satisfies the numeric test).
- **Boolean (anything else)** — `book[year lt 1900]`, `book[@id eq 'b3']`: keep
  items where the value is true. An empty sequence is false; a non-empty
  sequence of nodes is true (this is why `//book[price]` means "books that
  have a price element at all").

One practical wrinkle on untyped XML: in `input.xml` the `year` element has no
schema, so its value is an *untyped atomic*. A fully schema-aware processor
will happily compare that with a number, but the Bosak engine is strict about
mixed comparisons and raises `XPTY0004: Comparison between xs:string and
numeric operands is not defined`. The portable, explicit fix — good style
anywhere — is to convert in the predicate:

```xpath
//book[xs:integer(year) lt 1900]
```

(If you hit `XPTY0004` while experimenting, that is the engine telling you a
comparison needs both sides in the same type family.)

## 4. Testing sequences: `count`, `exists`, `empty`

Filtering tells you *which* nodes; these functions answer *how many / whether
any*:

- `count($seq)` — number of items (nodes or atoms, duplicates included).
- `exists($seq)` — true if the sequence has at least one item.
- `empty($seq)` — true if it has none; exactly `not(exists($seq))`, and the
  `not()` function is how you negate any boolean.

`exists()` and `empty()` short-circuit beautifully with `//`:
`exists(//magazine[year lt 1900])` asks "is there a pre-1950 magazine
*anywhere*?" — one scan, boolean answer.

## 5. Combining: `|` vs `,`

Both combine sequences, and they differ in ways that bite:

| | `A | B` (union) | `A, B` (concatenation) |
|---|---|---|
| Item kinds | nodes only | any items |
| Duplicates | removed | kept, in order |
| Order | **document order**, always | as written |

The union exists because node identity matters: two *different* elements may
have the *same* string value (the catalog has two books titled Frankenstein),
while the same node may be reached by two paths (a book is both "pre-1900" and
"price &gt; 9"). `|` dedupes by **node identity** and sorts by document order;
`,` just appends. So `count((//book, //book))` is 10 (five books, twice), but
`count(//book | //book)` is 5 — try both and see.

> Visual pun, since it confuses everyone once: the training harness *renders* a
> sequence by joining items with ` | ` (e.g. `Emma | Dune`). That ` | ` is
> presentation, not the union operator — but it does echo what a union feels
> like: one flat, document-ordered, duplicate-free list.

## 6. Try it live

Create a scratch file `try.xpath` in the workspace root, put one expression in
it — e.g. `//shelf/book[1]/title` — save, and run **Bosak: Evaluate XPath
Expression** from the right-click menu or the Command Palette (`F1`). The
preview shows the result. Scratch files are free: experiment until the
concepts stick, then delete the file. (`try.xpath` is not part of the graded
exercise.)

Good experiments before you start:

- `//book[1]` versus `(//book)[1]` — predict both, then run both.
- `count(//book | //book)` versus `count((//book, //book))`.
- `exists(//magazine[year lt 1900])` — what changes if you remove the
  `xs:integer` conversion?

## 7. The exercise

Open `starter/exercise.xpath`. It is one big concatenation with six parts.
Each part is preceded by a marker — a string literal like `'1:'` — and a `()`
where your expression goes. The markers are deliberate: the skeleton itself is
a demo of `,`-concatenation (mixed strings and node sequences in one result),
and they let you see *which part* produced which output tokens. Fill each `()`
and keep everything else byte-identical.

The catalog in `input.xml` has two shelves: `classics` (books b1–b3) and
`scifi` (books b4–b5, plus magazine m1). Two different books are titled
Frankenstein — that is intentional, and part 5 will not make sense without it.

| Part | Your expression should select… |
|---|---|
| 1 | the titles of all books published before 1900 |
| 2 | the title of the **first book of each shelf** |
| 3 | the title of the **last book of each shelf** |
| 4 | the sequence: number of books, number of shelves, whether a pre-1950 magazine exists |
| 5 | the union of (pre-1900 book titles) and (book titles priced above 9) |
| 6 | one concatenated sequence: the string `total:`, then the book count, then the part-2 titles |

### Hints (progressive)

1. Part 1: predicate on the `book` step, then step to `title` *after* the
   bracket closes — `//book[...]/title`, not `//book/[...]title`.
2. Part 1 gives you `XPTY0004`? Re-read section 3 — the engine needs an
   explicit type conversion for the numeric comparison.
3. Part 2: "the first book" has two honest readings. If your answer is
   `(//book)[1]` you get one title (Emma); the exercise wants the *per-shelf*
   reading. Which step produces a per-parent candidate list?
4. Part 3: `last()` inside a predicate returns the size of the candidate list
   for the node being tested.
5. Part 4: three items, wrapped in one `( ... )` so the markers stay aligned.
   A bare `year lt 1900` inside `exists` does not type-check — convert it.
6. Part 5: use `|`, not `,`. Predict first: how many titles? (How many
   *books* qualify? Does any book qualify twice?)
7. Part 6: strings and node sequences mix freely in one `( ... , ... )`. The
   marker text is `'total:'` with the colon inside the quotes.
8. Still stuck? The reference answer is in `solution/exercise.xpath`. Read it,
   close it, write your own.

## 8. Checking your work

- `Solution_matches_golden` **passes** — that is the harness guarding the
  reference material for the next learner, not a verdict on your file.
- To check *your* answer, put your six parts into `starter/exercise.xpath` and
  re-run:

  ```bash
  dotnet test ../XPathTrainingTests/XPathTrainingTests.csproj
  ```

  (From the repository root:
  `dotnet test training/xpath/XPathTrainingTests/XPathTrainingTests.csproj`.)
  When the harness prints the golden tokens for your session, you are done.
  (As in the XSLT curriculum: if you edited the starter in place,
  `Starter_differs_from_golden` now failing means *you* succeeded — restore
  the skeleton for the next learner when you finish.)

## 9. Go further

- `//title | 5` is a static error (`XPTY0004` — the union's operands must both
  be node sequences). Why is `,` fine with the same operands? What does that
  say about the two operators' purposes?
- `//book[year lt 1900]` finds b1–b3 — but what does
  `//book[xs:integer(year) lt 1900][xs:integer(price) gt 9]` find? Multiple
  predicates on one step are a logical AND, evaluated left to right; convince
  yourself the left-to-right order cannot change the result here.
- The two Frankenstein books have identical titles but different nodes.
  `//book/title | //shelf[@name eq 'scifi']/book/title` keeps both — write a
  union expression that keeps exactly one of them.
- Duplicated *values* survive both `|` and `,`. The function that collapses
  equal values is `distinct-values` — it is the star of session 3.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
