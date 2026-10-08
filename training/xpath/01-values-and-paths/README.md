<div align="center">
  <img src="../../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala XPath foundations session 01 — values and paths">
  <br><br>
  <h1>XPath Session 01 — Values &amp; Paths</h1>
  <p>Everything is a sequence, and paths walk the tree</p>
</div>

> **Time:** ~40 minutes · **Prerequisites:** [session 00 of the XSLT curriculum](../../00-setup/README.md) (tooling)
> **Exercise:** write the path expression that selects the book titles

---

## 1. What XPath is

XPath is a language for **addressing parts of an XML document** — and, since
version 2.0, for computing with the data it finds. It is embedded inside
larger languages: every XSLT `select`, every XQuery `where`, every XML
Schema `assert`. Learning it on its own, in tiny single-expression files, is
the fastest way to fluency — which is why this track exists.

## 2. The one mental model: the tree, and sequences

An XML document is a **tree** of nodes. `input.xml` in this session is a
small catalog:

```xml
<catalog>
  <book id="b1">
    <title>Emma</title>
    <author>Jane Austen</author>
    <year>1815</year>
  </book>
  <book id="b2">
    <title>Persuasion</title>
    <author>Jane Austen</author>
    <year>1817</year>
  </book>
  ...
</catalog>
```

- The document node is the root of the tree (not the same as `<catalog>` —
  the catalog element is its child).
- Elements, attributes, text, comments, processing instructions are nodes.
- An XPath expression **never returns "a node or a string or a number"** —
  it always returns a **sequence**, of any length, whose items are nodes or
  atomic values. A single result is a sequence of one; "nothing found" is the
  **empty sequence** `()`, which is a perfectly normal result, never an
  error.

Hold on to that: *everything is a sequence* explains most of XPath's
surprises, and it is why session 2 spends a whole hour on sequences.

## 3. Paths

A **path expression** is a series of **steps**, read left to right, each
step navigating from the current set of nodes to the next.

```xpath
/catalog/book/title
```

- `/` at the start means: begin at the document node.
- `catalog` is a step: select the child elements named `catalog` (the step
  axis is `child::` by default — you almost never write it).
- `/book` from there: child elements named `book` — both of them; a step
  maps each input node to zero or more nodes, and the results are combined.
- `/title` from each book: its `<title>` child.

Result: the sequence of title elements, in document order. The harness
renders that as `Emma | Persuasion | Frankenstein | The Time Machine`.

Two shorthands you will use constantly:

- `//title` — `//` is short for `/descendant-or-self::node()/`, so
  `//title` means "every `title` element anywhere under the root, at any
  depth". On this document `//title` and `/catalog/book/title` give the same
  result — but `//title` would also find titles nested inside chapters or
  reviews. Prefer the precise form when you know the structure.
- `@id` — the attribute axis: `//book/@id` selects the `id` attribute nodes
  of all books, rendered as their values: `b1 | b2 | b3 | b4`.

And two context items:

- `.` — the **context item**, the node the expression currently stands on.
  In these exercises the context is the document node, so `./catalog/book`
  is the same as `/catalog/book`.
- `..` — the parent axis, rarely needed in one-liners, essential in
  predicates (session 2: "authors of books whose year is …" uses
  `../author`).

## 4. Try it live

Create a scratch file `try.xpath` in the workspace root, put one expression
in it — e.g. `//book/@id` — save, and run **Bosak: Evaluate XPath
Expression** from the right-click menu or the Command Palette (`F1`). The
preview shows the result. Scratch files are free: experiment until the
concepts stick, then delete the file. (`try.xpath` is not part of the
graded exercise.)

## 5. The exercise

Open `starter/exercise.xpath`. Right now it contains only `()` — the empty
sequence, our "TODO" marker — and the test fails:

```bash
dotnet test ../XPathTrainingTests/XPathTrainingTests.csproj
```

(From the repository root:
`dotnet test training/xpath/XPathTrainingTests/XPathTrainingTests.csproj`.)

**Write the path expression that selects all book titles in the catalog.**
The golden result is:

```
Emma | Persuasion | Frankenstein | The Time Machine
```

### Hints (progressive)

1. You need three steps: catalog, then books, then titles. Which axis does
   each step use by default?
2. Start your expression with `/` so it begins at the document node.
3. If your result is `Emma Persuasion Frankenstein The Time Machine` in the
   live evaluator but the test still fails, compare against the exact golden
   file — `case/expected.txt`.
4. Still stuck? The reference answer is in `solution/exercise.xpath` — one
   line. Read it, close it, write your own.

## 6. Checking your work

- `Solution_matches_golden` **passes** — that is the harness guarding the
  reference material for the next learner, not a verdict on your file.
- To check *your* answer, put it in `starter/exercise.xpath` and re-run.
  When the harness prints the golden tokens for your session, you are done.
  (As in the XSLT curriculum: if you edited the starter in place,
  `Starter_differs_from_golden` now failing means *you* succeeded — restore `()` for the
  next learner when you finish.)

## 7. Go further

- `//book/author` returns four items — but two authors occur twice. Leave
  duplicates for now; session 3 shows `distinct-values`.
- Predict the result of `//book/title/..` before running it. Then run it.
  What does that tell you about what a step's result really is?
- Predict the result of `/catalog/book/author/text()` versus
  `/catalog/book/author`. In the harness both render the same — why? (The
  string value of an element is its text content; the harness renders nodes
  by string value. The expressions still differ in *what they return*, which
  matters the moment you apply another step to them.)
- Which single-step change to your solution would also select titles if the
  catalog gained a `<magazine>` section with `<title>`s? Is that desirable
  here?

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
