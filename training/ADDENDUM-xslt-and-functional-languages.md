<div align="center">
  <img src="../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training addendum — XSLT and functional programming languages">
  <br><br>
  <h1>Addendum — XSLT and Functional Programming Languages</h1>
  <p>You have been writing functional code all along; here are the names F# and Haskell give it</p>
</div>

> **Format:** lesson only — no exercise, no golden file (like
> [session 00](00-setup/README.md), this is a non-exercise unit).
> Read after session 10; the vocabulary lands best once you have met
> function items and the tier-3 wall.

---

The library is the destination; the training is the path. This addendum
steps off the path for one look at the map: nearly every technique in
sessions 01–10 is a standard idea in the functional-programming (FP)
family — the ML lineage (F#, OCaml, Standard ML) and the Haskell lineage.
Learning the names makes two things easier: reading the FP literature when
an XSLT problem sends you there, and learning F# or Haskell later, when
you discover you already speak most of the language.

## 1. Immutability and single assignment

`<xsl:variable name="s" select="..."/>` binds a name to a value **once**.
There is no assignment instruction anywhere in XSLT — no `=`, no `+=`, no
mutable cell — so "don't mutate" is not a style rule you must remember; it
is a fact about the language, enforced at compile time.

- In **F#**, `let s = ...` is the same single binding. Mutation exists but
  is opt-in and visible: you must declare `let mutable s` and write
  `s <- ...`. The compiler, not your discipline, stops the other spelling.
- In **Haskell**, there is no assignment at all in pure code: `let x = ...`
  (and its cousin `where`) introduce names that can never change.

Sessions 03 and 05 are this idea in work clothes: the recursive workers
carry two parameters, `$built` and `$remaining`, and "adding to `$built`"
means *calling the function again* with a new value — a new binding, never
a changed one. Every XSLT variable you have ever written was a `let`.

## 2. Recursion as the only loop

Because nothing can be mutated, a loop that "updates a result variable"
cannot exist. Session 03 made the point precisely: `xsl:for-each` *visits*
a sequence and instantiates its content once per item — it is a **map**
(applying something to every element), not a loop; it never hands you a
running result. XSLT's only way to repeat with accumulation is a function
that calls itself: the tail-recursive worker with an accumulator
parameter.

That worker is two famous idioms in other languages:

- **F#:** an inner recursive function with an accumulator — the `loop`
  idiom every F# programmer writes:
  ```fsharp
  let rec loop built remaining =
      if remaining = "" then built
      else loop (built + "-") (remaining.Substring(1))
  loop "" "0123456789"
  ```
- **Haskell:** the same shape, conventionally called a **go function** in
  a `where` clause — this is exactly how the Prelude itself defines
  `foldl`:
  ```haskell
  go acc []     = acc
  go acc (x:xs) = go (f acc x) xs
  ```

`str:padding` (session 03) and the `str:replace` scanner (session 05) are
`loop`/`go` with different arithmetic inside; session 09's durations are
the same pattern carried through maps. XPath 3.1 even packages the shape
as `fn:fold-left` — the accumulator loop as a library call (session 10,
and section 4 below). If you can write session 03, you can already read F#
and Haskell recursion.

## 3. Pattern-directed dispatch

Sessions 01–02 taught template rules — `match="team"`, `match="member"`,
`match="member[@lead]"` — without naming the concept. The name is
**pattern matching**, and it is everywhere in FP:

- **Haskell** matches top to bottom and defines functions by equations:
  ```haskell
  describe (Member name _)   = "member " ++ name
  describe (Lead name dept)  = "lead " ++ name ++ " of " ++ dept
  ```
  plus **guards** (`| condition = ...`) for the predicate part.
- **F#** spells it `match ... with`, also top to bottom:
  ```fsharp
  match member with
  | Lead(name, dept) -> $"lead {name} of {dept}"
  | Member(name, _)  -> $"member {name}"
  ```

XSLT resolves the "several rules could match" question by **template
priority**: more specific patterns win (`member[@lead]` beats `member`),
numeric `@priority` overrides, and declaration order breaks exact ties.
Haskell and F# resolve it by *order*: the first pattern that matches wins.
The deep idea is identical — dispatch by shape, with a defined precedence
— and the honest difference is listed in section 6: XSLT's conflict
resolution is more Prolog-flavored (rules about rules) than the FP
tradition.

## 4. Higher-order functions

Session 10 built a registry of function items and pipelined sequences
through `fn:filter` + `fn:for-each` + `fn:fold-left`. Those are the
classic higher-order trio, and the standard libraries of both languages
are built from them:

| XSLT 3.1 / XPath 3.1 | F# (.NET `List`) | Haskell (Prelude) |
|----------------------|------------------|-------------------|
| `fn:for-each($seq, $f)` | `List.map f list` | `map f list` |
| `fn:filter($seq, $f)` | `List.filter f list` | `filter f list` |
| `fn:fold-left($seq, $init, $f)` | `List.fold f init list` | `foldl f init list` |
| function item `f` | first-class function `f` | first-class function `f` |

One canonical problem, three spellings — sum of the squares of the even
numbers from 1 to 10 (answer 220 everywhere):

```xml
<!-- XSLT 3.0 / XPath 3.1: the pipeline session 10 verified on this engine -->
<xsl:variable name="result" as="xs:integer"
  select="fold-left(
            filter(1 to 10, function($x) { $x mod 2 eq 0 }),
            0,
            function($acc, $x) { $acc + $x * $x })"/>
```

```fsharp
// F#
[1..10]
|> List.filter (fun x -> x % 2 = 0)
|> List.map (fun x -> x * x)
|> List.fold (+) 0
```

```haskell
-- Haskell
foldr (+) 0 (map (^2) (filter even [1..10]))
```

Read the three aloud and they say the same sentence: *keep the even ones,
square them, add them up.* Session 10's dispatcher is the FP
"replace string-dispatch with a table of functions" move; the `|>`
pipeline is just "the sequence flows through these steps" written
left-to-right instead of inside-out.

## 5. Purity and the transformation as a function

A stylesheet is very nearly a **pure function**: same source document, same
parameters → same result document. Nothing you computed in session 09
depended on when you computed it, and nothing in `str:replace` changes the
input string — functions take values and return values, like a Haskell
function of type `Document -> Document`.

Where effects exist, they are pushed to the edges, exactly like Haskell's
`IO` type marks effectful computation at the boundary of pure code:

- `xsl:result-document` writes a file — visible to the world outside the
  result tree;
- `xsl:message` (and the tier-3 slot's `terminate="yes"`, session 10) is
  an effect on the host process;
- extension functions may do anything the engine allows.

The disciplined API design you practiced in session 05 — the scanner
returns text nodes, its contract stated in types (`as="xs:string"` in,
`text()*` out) — is how FP libraries communicate: type-driven contracts
instead of hidden mutation.

## 6. Where XSLT diverges from the ML/Haskell lineage

Honesty cuts both ways; the differences matter as much as the kinship.

- **The syntax is XML.** XSLT is verbose by design — markup intended for
  machines and tooling as much as for humans. F# and Haskell are textual
  languages a human reads first; a ten-line XSLT template is often three
  lines there.
- **The type system is optional.** XPath values carry types, but nodes
  from an unvalidated document are `untypedAtomic` and conversions happen
  *at use* (the `castable as` probes of session 08). Haskell infers strong
  static types for everything and will not run an ill-typed program; F#
  also infers, occasionally asking for an annotation. XSLT trusts you at
  runtime and reports with error codes like `XPTY0004`; Haskell reports
  before the program runs.
- **No laziness guarantee.** Haskell evaluates lazily by default — nothing
  computes until its result is demanded, which is why infinite lists like
  `[1..]` are ordinary values. XPath/XSLT sequences have no such
  guarantee; engines may evaluate eagerly, and XSLT streaming
  (`xsl:iterate`, streamable templates) is a memory discipline, not
  call-by-need semantics.
- **Nodes have identity; values do not.** Two nodes can be *equal by
  value* yet *different nodes* — session 06's whole lesson (`is` vs `=`,
  document order, `except`/`intersect` on node identity). In value-based
  FP a value is its structure: two identical lists are the same list.
  Node identity and document order are concepts with no FP counterpart.
- **Dispatch precedence is rule-based.** Template priority and conflict
  resolution (specificity rules, numeric priorities, declaration-order
  tie-breaks) descend from the logic/Prolog tradition — "rules about
  rules" — rather than FP's simple top-to-bottom pattern order.

And the practical payoff: these differences are vocabulary, not barriers.
If you can trace a template match and a tail-recursive worker, F# and
Haskell code reads like a session you have already done; and when an XSLT
problem sends you to an FP paper about folds or monads, you will recognize
the machinery on sight.

## 7. Go further

- **F# first steps:** the F# guide at Microsoft Learn, and Scott
  Wlaschin's *F# for fun and profit* — its "railway oriented programming"
  essays will feel like session 05's stateful scanning with types.
- **Haskell first steps:** *Learn You a Haskell for Great Good* (free
  online) or the Haskell.org "Documentation" page; work through its
  pattern-matching chapter and notice how much of it is session 01.
- **Then re-read [session 10](10-limits-of-pure-xslt/README.md)** with
  this vocabulary: function items are first-class functions, the registry
  is dispatch-by-table, `fold-left` is `List.fold`, and `dyn:evaluate` is
  the one place where a *string* — not a function — arrives, which is why
  the type system, and the whole pure-language story, cannot help.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
