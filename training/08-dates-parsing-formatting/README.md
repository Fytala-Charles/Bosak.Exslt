<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 08 — dates, parsing and formatting">
  <br><br>
  <h1>Session 08 — Dates I: Parsing &amp; Formatting</h1>
  <p>ISO 8601 in, components out: <code>date:year</code>, <code>date:leap-year</code>, <code>date:month-name</code></p>
</div>

> **Time:** ~60 minutes · **Prerequisites:** [session 07 — result trees and types](../07-result-trees-and-types/README.md) (the `instance of` / `castable as` family); [session 00](../00-setup/README.md) for tooling
> **Vehicle:** EXSLT dates-and-times module, tier 2 (`http://exslt.org/dates-and-times`)

---

## 1. Dates are strings until you make them values

XML has no date type; dates arrive as strings. XPath 3.1 answers with real
types: `xs:dateTime` (`2026-10-06T14:30:00Z`), `xs:date` (`2026-10-06`), and
the ISO 8601 partial types `xs:gYearMonth` (`2026-10`), `xs:gYear` (`2026`),
`xs:gMonthDay`, `xs:gMonth`, `xs:gDay`, and `xs:time`. Once a string is
accepted by a type, component extraction is native: `year-from-dateTime`,
`month-from-date`, `hours-from-time`, and friends.

Two hard requirements shape everything in this session:

- **EXSLT accepts the whole profile.** A date function argument may be a full
  dateTime, a bare year, a month-day — anything ISO 8601. Strict casting
  (`xs:date($in)`) handles two shapes and gives up on the rest.
- **Invalid input is data, not an exception.** Per the EXSLT spec, an
  unparseable argument yields `NaN` from numeric extractors and `''` from
  string extractors. `xs:date('not-a-date')` *throws* — so the implementation
  must catch, and "crash on bad input" is a defect, not robustness.

The third tool is **format-date picture strings**: a micro-language in which
`'[Y0001]-[M01]-[D01]'` means a date and `'[MNn]'` means the month's name.
You will learn the pictures in this session — and then watch one type-checking
subtlety silently eat the result, which is its own lesson (section 6).

## 2. Your task

Open `starter/transform.xsl` and run the test:

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

(From the repository root: `dotnet test training/TrainingTests/TrainingTests.csproj`.)

Three exercises over one shared design:

1. **`date:year($date-time)`** — plus the shared lenient parser
   `date:_as-datetime` that exercises 2 and 3 build on (exercise 1, section 4).
2. **`date:leap-year($date-time)`** — the Gregorian century rules (section 5).
3. **`date:month-name($date-time)`** — the month's English name via a
   `format-date` picture string, and the type-checking subtlety that comes
   with it (section 6).

## 3. Reading the starter

`input.xml` is six events chosen so every clause of the contract fires:

| Event date | What it proves |
|------------|----------------|
| `2026-10-06T14:30:00Z` | full dateTime with timezone |
| `2000-02-29` | a 400-year leap year (Feb 29 exists) |
| `1900-03-01` | a century that is **not** leap |
| `2026` | a bare year (ISO `gYear`) — valid EXSLT input |
| `not-a-date` | invalid → `NaN` / `''` |
| `2023-13-45` | structurally date-like but month 13 — invalid → `NaN` / `''` |

The template loops the events and prints `<year>`, `<leap>`, and `<month>`
for each. Engine quirks (session 04, section 3) apply as usual; section 6
examines one genuine XPath typing subtlety that is easy to trip over.

## 4. Exercise 1: `date:year` and the shared parser

The starter's `date:year` is a strict two-rung ladder: `castable as
xs:dateTime`, else `castable as xs:date`, else `NaN`. It survives the full
dateTime and both invalid strings — but the `century` event (`2026`, a legal
`gYear`) gets `NaN` where the contract says `2026`. And when exercises 2 and 3
need the same leniency, there is nothing shared to build on.

Build `date:_as-datetime($value)` first — the helper every later exercise
calls. Its contract: normalize whitespace, then probe the ISO 8601 types from
most to least specific, padding partial shapes with neutral defaults, and
raise `error(xs:QName('date:INVALID'), …)` when nothing fits. Then
`date:year` becomes: parse, extract, and wrap in `try { … } catch * { NaN }`.

### Hints (progressive — try each before opening the next)

1. The ladder is a `xsl:choose` of `castable as` probes. Order matters:
   `xs:dateTime` before `xs:date` before `xs:gYearMonth` before `xs:gYear` —
   most specific first, or `2026-10-06T14:30:00Z` would match something
   shorter and lose its time.
2. Padding: a `gYearMonth` becomes a date by appending `'-01'`; a `gYear` by
   appending `'-01-01'`; then one `xs:dateTime(xs:date(…))` conversion
   normalizes everything. For the exotic shapes the library fills in `1972`
   (a leap year, so Feb 29 stays legal) and day `01` — copy that choice.
3. `date:year` body: `try { xs:double(year-from-dateTime(date:_as-datetime($date-time))) }
   catch * { xs:double('NaN') }`. The `catch *` is the EXSLT contract: the
   parser's `error()` call never reaches the caller.
4. Absent argument (`not($date-time)`) returns `NaN` without parsing — the
   empty string and the missing string are different inputs.
5. Still stuck? `src/dates-and-times.xsl` — look for `date:_as-datetime`.

## 5. Exercise 2: `date:leap-year`

The starter applies the rule everyone half-remembers: *divisible by 4*. Trace
`1900`: divisible by 4 → the starter says `true`. But 1900 was not a leap
year — the Gregorian calendar skips century years *unless* they are divisible
by 400 (which is why 2000 had a Feb 29). The full test, on the year extracted
via your shared parser:

```
(($y mod 4) eq 0 and ($y mod 100) ne 0) or ($y mod 400) eq 0
```

### Hints (progressive — try each before opening the next)

1. Get the year with `year-from-dateTime(date:_as-datetime($date-time))` — a
   `let $y := … return …` keeps the expression readable (single `let`, per
   the engine quirk).
2. Translate the sentence, not the folklore: "by 4, except centuries, except
   400-years" is exactly the two-clause `or` above.
3. Invalid input → `false()`: same `try`/`catch *` shape as exercise 1, with
   the boolean fallback.
4. Predict all six events before running: only `birthday` (2000) is `true` —
   `archive` (1900) is the trap the starter falls into.
5. Still stuck? `src/dates-and-times.xsl` — look for `date:leap-year`.

## 6. Exercise 3: `date:month-name` — and the subtlety that eats it

The idiomatic XPath 3.1 spelling of this function is one line, and it is
exactly what the library in `src/` writes:

```xml
format-date($as-datetime, '[MNn]')
```

Picture strings put a *component* in brackets: `Y` year, `M` month, `D` day,
each with width and style modifiers — `[M01]` zero-pads to two digits,
`[MNn]` asks for the name in lower-then-uppercase (i.e. capitalized) form.
`'[Y0001]-[M01]-[D01]'` is the ISO date; `'[FNn]'` is a weekday name. This
session verified on this very engine that the pictures work exactly as
specified: `format-date(xs:date('2026-10-06'), '[MNn]')` returns `October`.

So your exercise is the library's line, wrapped in the session's standard
contract: `try { format-date(date:_as-datetime($date-time), '[MNn]') }
catch * { '' }`, with the `not($date-time)` early return for the absent
argument.

Now the subtlety, because it changes the golden. `format-date`'s first
parameter is typed **`xs:date?`** — a *date*, not a dateTime. Your
`date:_as-datetime` returns **`xs:dateTime`**, always, for every parseable
input. Handing a dateTime where a date is declared is a spec type error, and
this engine enforces it: it raises `XPTY0004` (verified with a catch-sentinel
during this session's development). The `catch *` does its job and converts
the error to `''` — which means **on this engine the library's
`date:month-name` returns `''` for every parseable input**. That is not an
engine defect: the parent's-style probe with a proper `xs:date` argument
(`format-date(xs:date('2026-10-06'), '[MNn]')` → `October`) works perfectly.
The mismatch lives in the library's own call site, and any engine that
enforces function signatures behaves the same way. The golden file pins this
behavior deliberately — `<month>` is empty for all six events — because a
training corpus documents what the code *does*, not what it was meant to do.
Section 9 shows the one-line repair.

### Hints (progressive — try each before opening the next)

1. Write the library's line: `format-date(date:_as-datetime($date-time),
   '[MNn]')`, inside the `try { … } catch * { '' }` skeleton, keeping the
   `not($date-time)` early return.
2. Do **not** fix the dateTime-versus-date mismatch while solving the
   exercise — the golden pins the library's actual behavior, including the
   empty `<month>` results. Fixing it is the "go further" item.
3. Predict the whole `<month>` column before running: empty everywhere on
   this engine — four rows from the type error, two from the parser's
   `date:INVALID`, indistinguishable in the output and *equally correct per
   the contract*.
4. The starter's off-by-one lookup list is the wrong mechanism entirely;
   pictures are the real tool. Compare how many characters each version
   spends on the problem.
5. Still stuck? `src/dates-and-times.xsl` — look for `date:month-name` and
   mirror it, comment for comment.

## 7. Checking your work

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

- `Starter_differs_from_golden` **passes** — good: it asserts your starter is still
  unsolved, guarding the exercise for the next learner.
- To check *your* implementation, paste it into the starter and watch the
  `<year>`, `<leap>`, and `<month>` lines of the test diff. When your output
  equals `case/expected.xml`, you are done. (If you edited `starter/transform.xsl`
  directly, the `Starter_differs_from_golden` test will now fail — that failure means
  *success* for you; restore the stub when you finish the session so the
  exercise stays RED for the next learner.)

You can also run the transform by hand in VS Code with the Bosak extension,
using `input.xml` as the source document.

## 8. Compare with the library

Open `src/dates-and-times.xsl`. Your `date:_as-datetime` should match its
ladder rung for rung — same probe order, same 1972 padding, same
`date:INVALID` error. Your `date:year` and `date:leap-year` should be its
code with the comments rewritten in your own words. That is what tier 2 looks
like when the native types do most of the work: the *genuine implementation*
is the lenient contract around the strict primitives.

`date:month-name` should be the library's code word for word — same line,
same `try`/`catch *`, same early return. Read its behavior on this engine
alongside the golden: empty `<month>` elements everywhere, because the
function hands `format-date` an `xs:dateTime` where the signature declares
`xs:date?`, and this engine enforces that. The interesting question for a
future maintainer is in `docs/COMPATIBILITY.md`: the matrix lists
`date:month-name` as "implemented" with no test case pinning its output —
the divergence this golden documents is exactly why untested "implemented"
rows deserve suspicion. When you meet a wrapper or one-liner in the library,
ask both questions: does it run, and does a golden prove what it returns?

## 9. Go further

- **Repair the subtlety:** make the names appear. `format-date` wants an
  `xs:date`; your helper yields an `xs:dateTime`. Convert at the call site —
  `format-date(xs:date(substring(string(date:_as-datetime($date-time)), 1, 10)), '[MNn]')` —
  and verify with a template line that October, February, March, and January
  finally print. Why is `substring` safe here but wrong in general?
- **`date:month-abbreviation`:** the library's `[MNn,*-3]` picture means
  "name, contracted to at most 3 characters" (`*-3` width modifier). Predict
  the output for May before you try it — then check.
- **More shapes:** add events with `2026-10` (gYearMonth), `--10-06`
  (gMonthDay), and `14:30:00` (time → year 1972). Predict each row first; the
  padding defaults decide.
- **Picture safari:** write the picture strings for ISO `YYYY-MM-DD`, for
  `Monday, 6 October 2026`, and for a US-style `10/6/2026` — then run them
  against `xs:date('2026-10-06')` on this engine. Which of your safaris
  succeed first try?
- **The `xs:date` shortcut:** for *full dates only*, `xs:date('2000-02-29')`
  then `year-from-date` works without the ladder. Where exactly does that
  shortcut stop being enough?
- **Peek ahead:** session 09 turns numbers into durations — `PT1H30M` —
  where decimal-exact arithmetic beats floating point, and libxslt's rounding
  is a *documented divergence*, not a bug.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
