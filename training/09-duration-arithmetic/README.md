<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 09 — duration arithmetic">
  <br><br>
  <h1>Session 09 — Dates II: Duration Arithmetic</h1>
  <p>Component arithmetic and decimal precision: <code>date:duration</code>, <code>date:add-duration</code>, <code>date:sum</code></p>
</div>

> **Time:** ~60 minutes · **Prerequisites:** [session 08 — dates, parsing &amp; formatting](../08-dates-parsing-formatting/README.md) (the shared parser idea; `xs:decimal` vs `xs:double`), [session 04 — regular expressions](../04-regular-expressions/README.md) (`analyze-string`; engine quirks, section 3); [session 00](../00-setup/README.md) for tooling
> **Vehicle:** EXSLT dates-and-times module, tier 2 (`http://exslt.org/dates-and-times`)

---

## 1. Durations are three currencies, not one number

Session 08 parsed *dates*. This session computes with *durations* — and the
first shock is that `PnYnMnDTnHnMnS` is not a length of time. It is three
separate ledgers that cannot be merged:

- **Months** are calendar-relative. A month is 28, 29, 30, or 31 days
  depending on which month and which year — so `P1M` has no fixed number of
  seconds.
- **Days** are (mostly) 24 hours. EXSLT deliberately keeps days in their own
  ledger: when components carry, *days never carry into months*, because the
  module has no calendar to ask how long a month is.
- **Seconds** are exact. Hours and minutes fold into them (`PT90M` is a
  time-of-day oddity but a perfectly good duration component).

EXSLT's contract is explicit about the carries: **months carry into years,
seconds carry into days, days never carry into months.** `P1Y14M` is written
`P2Y2M`; `PT25H` is `P1DT1H`; but `P80D` stays `P80D` — nobody converts it
to "two and a half months", because that answer needs a date, and a
duration doesn't have one.

The second shock is **precision**. `xs:double` is binary floating point:
the literal `3599.99999999999` is stored as `3599.999999999989996…`, and a
`div`/`mod` chain on doubles prints the noise (run the starter and look at
its `split-hair` row). libxslt computes `date:duration` in doubles and
rounds that input to `PT1H`; this library computes in `xs:decimal` and
answers `PT59M59.99999999999S`. Both are "a duration near one hour" — but
only one is *the* answer for the input you gave. This is a **documented
divergence** (`docs/COMPATIBILITY.md`, `tests/ATTRIBUTION.md`, and the
`tests/cases/date/duration.1` golden, which pins **our** decimal-exact
line). Divergences are not bugs; they are decisions written down.

The third tool is **`xsl:analyze-string`** (session 04) for parsing
`PnYnMnDTnHnMnS` back into components — with this engine's restriction in
mind: inside `xsl:function`, `analyze-string`'s children must be
select-valued; the shape that works is the one the library uses.

## 2. Your task

Open `starter/transform.xsl` and run the test:

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

(From the repository root: `dotnet test training/TrainingTests/TrainingTests.csproj`.)

Three exercises over one shared design:

1. **`date:duration($seconds)`** — seconds to a canonical duration string,
   decimal-exact (exercise 1, section 4).
2. **`date:add-duration($duration1, $duration2)`** — add two durations with
   component normalization (exercise 2, section 5).
3. **`date:sum($node-set)`** — sum a node set of durations, with the EXSLT
   `NaN` rule (exercise 3, section 6).

## 3. Reading the starter

`input.xml` is one `<workout>` with three groups chosen so every clause of
the contract fires:

| Row | What it proves |
|-----|----------------|
| `zero` → 0 s | the completely-zero duration formats as `P0D` |
| `meeting` → 3661 s | hours, minutes, seconds all non-zero |
| `day-plus` → 90000 s | seconds carry into days (`P1DT1H`) |
| `overdraft` → −90 s | the sign is a formatting decision, taken once, outside the arithmetic |
| `split-hair` → `3599.99999999999` s | the decimal-exact divergence line: `PT59M59.99999999999S`, not `PT1H` |
| `half` → 0.5 s | sub-second precision survives as `PT0.5S` |
| `warmup` `PT1H + PT1H` | no carries — the easy agreement |
| `carry` `PT25H + PT90M` | hours and minutes both carry: `P1DT2H30M` |
| `calendar` `P1Y2M + P10M` | months carry into years: `P2Y` |
| `long-haul` `P40D + P40D` | days **never** carry into months: `P80D` |
| `mixed-sign` `PT90M + -PT30M` | signed component sums: `PT1H` |
| `spill` `PT50S + PT40S` | seconds carry into minutes: `PT1M30S` |
| `broken` `nonsense + PT1H` | invalid operand → `''` |
| `shift` `P1D, PT12H, PT36H` | seconds carry into days across members: `P3D` |
| `milestones` `P1M, P15D, PT1H` | three ledgers in one sum: `P1M15DT1H` |
| `mixed-sign` `-PT30M, PT1H` | negative members participate: `PT30M` |
| `poisoned` `PT1H, not-a-duration, PT30M` | one bad member poisons the whole sum → `NaN` |
| `empty` (no members) | the empty sum is `P0D` |

The template loops each group and prints `<duration>`, `<result>`, and
`<total>` respectively. Engine quirks (session 04, section 3) apply as
usual — and this session adds a fresh one of its own, discovered while the
starter was being built (section 5).

## 4. Exercise 1: `date:duration` — seconds to string, exactly

The starter's `date:duration` is a binary-float `div`/`mod` chain that
emits every component whether or not it is zero. It *runs* — and its
`split-hair` row prints `…59.999999999989996S`, the binary noise you are
here to eliminate.

Two ideas repair it. First, **do the arithmetic in `xs:decimal`**: convert
once (`abs(xs:decimal($seconds))`), split whole days off with
`floor($total div 86400)`, and the remainder is exact. Second, **formatting
is a separate concern**: a small `_format-duration` helper takes
`(neg, months, days, seconds)` and emits only the non-zero components in
canonical `PnYnMnDTnHnMnS` shape, with `P0D` as the everything-zero special
case. The sign never enters the arithmetic — it is applied at the end.

### Hints (progressive — try each before opening the next)

1. `xs:decimal($seconds)` before `abs` — not after. One conversion at the
   boundary, exact arithmetic from then on.
2. The day split is `floor($total div 86400)`; the in-day remainder is
   `$total - 86400 * $days`. Whole days are `xs:integer`; the remainder
   stays `xs:decimal` even when it happens to be whole.
3. Build the formatter first and call it from `date:duration` — exercises 2
   and 3 will reuse it verbatim. Only non-zero components appear; `P0D`
   when all three are zero; `-` prefixed once, outside.
4. Predict all six rows before running — especially `split-hair`: our
   golden says `PT59M59.99999999999S` where libxslt's floats say `PT1H`.
   Which one is "correct" for the input as written, and who decided?
5. Still stuck? `src/dates-and-times.xsl` — look for `date:_split-seconds`
   and `date:_format-duration`.

## 5. Exercise 2: `date:add-duration` — two durations, three ledgers

Get the signature right first: EXSLT `date:add-duration` takes **two
durations** and returns their sum as a duration. It is easy to reach for
native XPath arithmetic instead — the starter does exactly that, and every
pair row comes back `''`. Delete its `try`/`catch` and run again: the
engine says `XPTY0004: A plain xs:duration value is not allowed in
date/time arithmetic (xs:dayTimeDuration or xs:yearMonthDuration
required)`. XPath 3.1's operator table admits only the two *restricted*
duration types in arithmetic — the general `xs:duration` is excluded — so
the naive route is not just un-normalized, it is closed. (The same
restriction is why `date:seconds` in the library special-cases its casts.)

**Do not confuse this function with `date:add`.** Same module, one word
different, opposite philosophy:

- `date:add($date-time, $duration)` anchors to a **real date** and uses
  calendar arithmetic (`xs:dateTime + xs:duration`): month lengths, leap
  years, month-end clamping. January 31 plus `P1M` lands on February 28 or
  29 — the answer depends on *which* January.
- `date:add-duration($duration1, $duration2)` never touches a calendar.
  Components add, carry within the rules (months→years, seconds→days), and
  days stop at the month boundary forever. `P1M + P1M` is `P2M` — always,
  on any date, in any year.

`docs/COMPATIBILITY.md` records the flip side of this distinction: this
library's `date:add` uses native calendar addition, while libxslt's uses
component arithmetic, so month-end results may differ between the two
(documented, no golden test). When you meet a duration function, ask
first: *which of the three ledgers does it trust, and does it know what day
it is?*

The implementation parses each operand with `analyze-string` into a map
(`neg`, `months`, `days`, `seconds` — fold years into months and
hours/minutes into seconds at parse time), adds the ledgers as *signed*
sums, then hands `(neg, months, days, seconds)` to your exercise 1
formatter. A parse failure on either operand returns `''`. Mind the
engine quirk from session 04: inside a function, `analyze-string`'s
children must be select-valued — `xsl:variable` and `xsl:sequence` with
`select`, exactly the library's shape.

### Hints (progressive — try each before opening the next)

1. The regex is one line: `^(-)?P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(\d+(?:\.\d+)?S)?)?$`.
   Six capture groups; every one optional. Draw the shape before coding it.
2. At parse time, normalize into three ledgers: years × 12 fold into
   months; hours × 3600 and minutes × 60 fold into a *decimal* seconds
   total (drop the trailing `S` with `substring`). `regex-group(n) ne ''`
   tells you whether an optional group participated.
3. Add signed: `-P...` flips the sign of *all three* ledgers of that
   operand. Whole months and days are `xs:integer`; seconds stay decimal.
4. Carries are your exercise 1 machinery: split the seconds ledger into
   days (`floor` division on decimals — exact), add that to the days
   ledger, and let the formatter fold months into years. Days never touch
   months.
5. Predict the seven rows before running: which two rows differ from a
   "no-carry" implementation, and which row differs from a *calendar*
   implementation? (`long-haul` is the tell.)
6. Still stuck? `src/dates-and-times.xsl` — look for `date:_parse-duration`
   and `date:add-duration`.

## 6. Exercise 3: `date:sum` — the accumulator, with poison rules

`date:sum($node-set)` receives **nodes** whose string values are durations,
and returns one duration string. The machinery is all built: parse every
member with exercise 2's parser, add the ledgers the exercise 2 way, format
with exercise 1's formatter.

What makes `date:sum` its own exercise is the **failure contract**, and it
differs from `date:add-duration` on purpose. EXSLT says: if *any* member of
the node set does not hold a valid duration, the result is the **string
`"NaN"`** — not `''`, not an error, and not the sum of the good members.
The starter's naive version returns `NaN` for every set containing a
month-bearing *or negative* member; the contract says those sets sum
perfectly well, and only genuinely unparseable members poison the result.
The trick that enforces the rule in one comparison: parse all members into
a sequence, then check `count($parsed) ne count($node-set)` — a failed
parse produced no map. (The empty node set passes that check with flying
colors: zero maps, zero nodes, and the arithmetic answers `P0D`.)

### Hints (progressive — try each before opening the next)

1. `$node-set ! date:_parse-duration(string(.))` parses every member in one
   line. `string(.)` is the EXSLT "string value" conversion of a node.
2. The poison check is the count comparison — no flags, no `some`/
   `every`, one `ne`. Then the sum is the exercise 2 ledger arithmetic,
   unchanged.
3. Mind the difference: `poisoned` → `NaN` (string), `broken` (exercise 2)
   → `''`. Same parser underneath; the functions disagree on purpose. Say
   why.
4. Predict all five rows, including what `empty` should print and why the
   count comparison doesn't reject it.
5. Still stuck? `src/dates-and-times.xsl` — look for `date:sum`.

## 7. Checking your work

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

- `Starter_differs_from_golden` **passes** — good: it asserts your starter
  is still unsolved, guarding the exercise for the next learner.
- To check *your* implementation, paste it into the starter and watch the
  `<duration>`, `<result>`, and `<total>` lines of the test diff. When your
  output equals `case/expected.xml`, you are done. (If you edited
  `starter/transform.xsl` directly, the `Starter_differs_from_golden` test
  will now fail — that failure means *success* for you; restore the stub
  when you finish the session so the exercise stays RED for the next
  learner.)

You can also run the transform by hand in VS Code with the Bosak extension,
using `input.xml` as the source document.

## 8. Compare with the library

Open `src/dates-and-times.xsl`. Your three helpers — the day split, the
canonical formatter, the duration parser — should be its
`date:_split-seconds`, `date:_format-duration`, and `date:_parse-duration`
with the comments rewritten in your own words; your three functions are
those helpers composed. That is the tier-2 shape at full strength: no
native shortcut exists for the *general* duration type, so the genuine
implementation is the honest one.

Two library notes worth carrying away. First, the decimal-exact choice is
deliberate and documented: `tests/cases/date/duration.1` keeps libxslt's
verbatim output on every row *except* the split-hair one, which was
re-goldened to our `PT59M59.99999999999S` and logged in
`tests/ATTRIBUTION.md`. When your implementation differs from the
reference, that is the full correct procedure: decide, document, pin.
Second, session 08's lesson echoes here — the starter's `try`/`catch`
swallowed an `XPTY0004` and returned `''` for every row, and only deleting
the catch revealed the engine's real complaint. A catch block that erases
results is a bug amplifier, not error handling.

## 9. Go further

- **The month-end probe:** hand `date:add('2026-01-31', 'P1M')` and
  `date:add('2024-01-31', 'P1M')` to the library and compare: calendar
  arithmetic clamps to February 28/29 depending on the year, while the
  component view of the same `P1M` never changes. Then read the `date:add`
  row in `docs/COMPATIBILITY.md` — the divergence from libxslt's component
  arithmetic is documented there, deliberately without a golden.
- **Round trip:** implement `date:seconds` (duration → total seconds) and
  check `date:duration(date:seconds($d))` against a few inputs. Where does
  the round trip lose information?
- **A different poison:** what should `date:sum` return when one member is
  the empty string? Write the one-line probe before checking the library.
- **Own the quirk:** `fn:tokenize` on this engine keeps zero-length tokens
  (session 04, section 3). Rebuild `date:_parse-duration` without
  `analyze-string` — regex-`tokenize` plus positional mapping — and count
  the extra guards you need.
- **Peek ahead:** session 10 meets the functions pure XSLT 3.0 *cannot*
  have — `dyn:evaluate` and the tier-3 slots that raise instead of faking
  it.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
