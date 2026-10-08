<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 10 — the limits of pure XSLT">
  <br><br>
  <h1>Session 10 — The Limits of Pure XSLT</h1>
  <p>Function items, fold-left/map/filter — and why <code>dyn:evaluate</code> cannot exist here</p>
</div>

> **Time:** ~60 minutes · **Prerequisites:** [session 02 — your first stylesheet](../02-first-stylesheet/README.md) (`xsl:function`), [session 05 — stateful scanning](../05-stateful-scanning/README.md) (accumulators), [session 09 — duration arithmetic](../09-duration-arithmetic/README.md) (maps as data); [session 00](../00-setup/README.md) for tooling
> **Vehicle:** EXSLT dynamic module, tier 3 (`http://exslt.org/dynamic`) — the first function in the curriculum that **cannot be re-created**

---

## 1. Nine sessions in, finally: the wall

Sessions 02–09 re-created every EXSLT function they touched, in pure XSLT
3.0, against the published engine. This session meets the exception —
`dyn:evaluate($expression)`, which takes a *string* and evaluates it as
XPath at run time. It is tier 3 in the project's compatibility model:
**not implementable in pure XSLT 3.0**, and the library says so out loud.
Open `src/dynamic.xsl`; the entire module is this slot:

```xml
<xsl:message terminate="yes"
  select="'Bosak.Exslt: dyn:evaluate() requires dynamic XPath evaluation, which pure XSLT 3.0 cannot provide. ...'"/>
```

Why is it impossible, and not merely hard? Because evaluation is
*reflective*: to run a string of XPath source, something must hold the
expression compiler — the parser, the static context, the evaluation
machinery. A stylesheet is data to that compiler; it has no API back into
it. The only ways to evaluate a string are a host-level construct the
engine exposes (`xsl:evaluate`, which Bosak does not support yet — tracked
as REQ-121 in `docs/FEATURE_REQUESTS.md` / `ROADMAP.md`) or a native
extension function. A pure-XSLT implementation would have to ship an XPath
parser *written in XPath* — which would itself need to evaluate its own
parse trees, round and round. The tier model exists for exactly this
moment: a documented slot that terminates loudly, never a fake
implementation that returns plausible garbage.

The companion namespace `func:*` (`func:function` / `func:result`) is the
other tier-3 row in `docs/COMPATIBILITY.md`: XSLT 1.0's way of defining
extension functions inside a stylesheet. It is not a wall, just a closed
door — `xsl:function` (session 02) supersedes it completely, and migrating
stylesheets should mechanically rewrite `func:function` as `xsl:function`.

**See it fail — in your own sandbox.** The slot's `terminate="yes"` would
crash this session's test harness, so the golden below pins the *positive*
half of the lesson instead. To watch the wall yourself: copy
`src/dynamic.xsl` into a scratch stylesheet of your own (or a temporary
session directory with a `case/meta.json`), call `dyn:evaluate('1 + 1')`,
and run it. The transformation stops dead with the message above. That is
the correct, honest behavior — memorize what it looks like.

## 2. The positive half: what pure XSLT 3.0 offers instead

Most code that *wants* `dyn:evaluate` does not need arbitrary expressions.
It needs **string-dispatch**: a message arrives saying which operation to
perform, and the stylesheet routes it. XPath 3.1 answers that need with
**function items** — functions as first-class values — and the
**higher-order functions** that consume them:

- Anonymous functions: `function($a, $b) { $a + $b }` — a value you can
  store, pass, and call.
- Named function references: `calc:max2#2` — an existing `xsl:function`
  used as a value by name and arity.
- `fn:function-lookup(xs:QName('calc:max2'), 2)` — the same, looked up
  dynamically by name.
- `fn:for-each`, `fn:filter`, `fn:fold-left` — map, select, and accumulate
  over a sequence with a function item.

None of these exist anywhere in `src/` — the library's maps are pure data
(session 09). So this session also verifies new ground: **every construct
used below was probed on Bosak 0.12.3-beta before this session was
authored** (anonymous functions, named references, `function-lookup`,
maps holding function items, `for-each`/`filter`/`fold-left`, function
items as function parameters and in `let` variables — all pass). One
verified quirk shapes the design: looking up a **missing** map key yields
the empty sequence, and *calling* the empty sequence raises `XPTY0004` —
so unknown operations must be guarded with `map:contains` *before* the
call.

## 3. Your task

Open `starter/transform.xsl` and run the test:

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

(From the repository root: `dotnet test training/TrainingTests/TrainingTests.csproj`.)

**Build the safe dispatcher.** `input.xml` carries nine
`<calc op="..." a="..." b="..."/>` requests — six known operations, two
typos, one repeat. Your stylesheet must evaluate each request through a
**registry** — a map from op-name to function item — print each result (or
reject the unknown ops explicitly), and compute a summary
(`<summary evaluated="..." rejected="..." total="..."/>` plus the rejected
op list) with a single `fold-left` pass and a `filter`+`for-each` pair.
This is strictly better than `dyn:evaluate` for known operations: the ops
are typed (`xs:integer` in, `xs:integer` out), compiled into the
stylesheet, and closed — no arbitrary expression can reach the engine.

## 4. The exercise: registry, dispatch, pipeline

The starter shows the classic pre-function-items design, and its failure
mode. `calc:eval` is an `if`/`else-if` chain over the op name; anything
unrecognised falls through to `else $op`, which **echoes the op name** as
the "result". The summary block carries a *second* hand-maintained copy of
the same dispatch logic and totals `number()` of whatever came back — so
one unrecognised op turns the whole total into `NaN`, the rejected count
is hardcoded `0`, and the two op lists have already drifted (`max` is
missing from the chain). Run it and look at the damage; then rebuild it the
function-item way:

1. **The registry** — one `calc:ops()` function returning
   `map { 'add': function($a, $b) { $a + $b }, ..., 'max': calc:max2#2 }`.
   Mix anonymous functions and one named reference so both forms are
   exercised. `'div'` is integer division (`idiv`) so every op returns
   `xs:integer`. Adding an operation is one line, here, and zero lines
   anywhere else.
2. **The dispatch** — per `<calc>`: `map:contains(calc:ops(), string(@op))`
   first (remember the `XPTY0004` quirk), then
   `calc:ops()(string(@op))(xs:integer(@a), xs:integer(@b))` — look up the
   function item, then call it. Unknown ops get an explicit `<rejected/>`;
   never let an op name pass for a result.
3. **The summary** — `fold-left($calcs, map { 'evaluated': 0, 'rejected': 0,
   'total': 0 }, function($acc, $r) { ... })` carrying a map accumulator;
   the same `map:contains` decision as the dispatch, so counts and total
   cannot drift. Then the rejected list:
   `for-each(filter($calcs, function($r) { not(map:contains(...)) }),
   function($r) { string($r/@op) })`.

### Hints (progressive — try each before opening the next)

1. A map value can be a function item — `map { 'add': function($a, $b) {
   $a + $b } }` is ordinary XPath 3.1. Lookup then call:
   `$m('add')(2, 3)`. Two pairs of parentheses: first fetches, second
   invokes.
2. The named reference `calc:max2#2` requires a real `calc:max2` function
   in the stylesheet (`#2` = arity). `function-lookup(xs:QName('calc:max2'),
   2)` fetches the same item dynamically — try both spellings in a probe.
3. The guard exists because `$m('nope')` is the empty sequence and calling
   *that* raises `XPTY0004` (engine-verified). `map:contains` asks before
   you call.
4. In the fold, build a fresh map each step — `map { 'evaluated':
   $acc?evaluated + 1, ... }`. Maps are immutable; "update" means
   "construct the next one".
5. Predict the whole report before running: which two rows are rejected,
   what is `total`, and what the starter printed for each of those rows
   instead?
6. Still stuck? `training/09-duration-arithmetic/solution/transform.xsl`
   shows the map idioms; the rest of this design is section 2 above.

## 5. Checking your work

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

- `Starter_differs_from_golden` **passes** — good: it asserts your starter
  is still unsolved, guarding the exercise for the next learner.
- To check *your* implementation, paste it into the starter and watch the
  test diff. When your output equals `case/expected.xml`, you are done.
  (If you edited `starter/transform.xsl` directly, the
  `Starter_differs_from_golden` test will now fail — that failure means
  *success* for you; restore the stub when you finish the session so the
  exercise stays RED for the next learner.)

You can also run the transform by hand in VS Code with the Bosak extension,
using `input.xml` as the source document.

## 6. Compare with the library

Open `src/dynamic.xsl`: fifty-three lines, two function slots, one message.
This is what tier 3 *is* — documentation and a loud failure instead of a
silent fake. Compare `docs/COMPATIBILITY.md`: the `dyn:evaluate` row says
"documented", names the engine-support migration path (`xsl:evaluate`, or
a Bosak native/commercial extension tracked as REQ-121), and the
`func:function` row explains the mechanical rewrite to `xsl:function`.

Then notice what the library does *not* contain: no registry, no
higher-order functions, no function items. Everything you built this
session — the typed dispatch table, the guarded lookup, the folding
summary — is machinery the EXSLT modules predate or deliberately avoid,
and it is the correct home for the use case that used to end in
`dyn:evaluate`. When you meet a tier-3 slot in the wild, the professional
move is the one this session practiced: pin what you *can* build (and
prove it with a golden), and document honestly what you cannot.

## 7. Go further

- **The literal-only evaluator:** a tiny evaluator for `N op N` expressions
  (two integers, one operator) is buildable today — `analyze-string` the
  string, dispatch through your registry. Build it, then articulate exactly
  which expression forms make the general case impossible, not just hard.
- **Host escape hatch:** read the `xsl:evaluate` entry in the XSLT 3.0
  spec and REQ-121 in `docs/FEATURE_REQUESTS.md`. If Bosak adds it, what
  happens to `src/dynamic.xsl`'s slot — and which golden case would you
  write first?
- **Arity games:** `function-lookup` fails gracefully when nothing matches —
  or does it? Probe `empty(function-lookup(xs:QName('calc:nope'), 2)))` and
  `function-lookup(...)(1, 2)` on this engine and record what actually
  happens.
- **One-pass summary:** your fold visits the requests once; the starter's
  template logic visits them at least twice. What changes when the input is
  a million rows? (Think about what `fold-left` guarantees about order.)
- **Peek ahead:** session 11 is the capstone — you pick the EXSLT function,
  write the golden case first, then the implementation, the full
  contribution workflow.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
