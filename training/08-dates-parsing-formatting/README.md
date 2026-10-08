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
You will learn the pictures in this session — and then meet a real bug the
library once shipped: a type-checking mismatch at the `format-date` call
site, quietly masked by the session's own `try`/`catch` until REQ-008
repaired it (section 6).

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
walks through the typing defect the library shipped at its `format-date`
call sites — and the one-line repair that fixed it.

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

## 6. Exercise 3: `date:month-name` — and the bug the catch swallowed

The idiomatic XPath 3.1 spelling of this function is one line, and — after
the REQ-008 repair — it is exactly what the library in `src/` writes:

```xml
format-date(xs:date(substring(string(date:_as-datetime($date-time)), 1, 10)), '[MNn]')
```

Picture strings put a *component* in brackets: `Y` year, `M` month, `D` day,
each with width and style modifiers — `[M01]` zero-pads to two digits,
`[MNn]` asks for the name in lower-then-uppercase (i.e. capitalized) form.
`'[Y0001]-[M01]-[D01]'` is the ISO date; `'[FNn]'` is a weekday name. This
session verified on this very engine that the pictures work exactly as
specified: `format-date(xs:date('2026-10-06'), '[MNn]')` returns `October`.

So your exercise is the library's line, wrapped in the session's standard
contract: `try { format-date(xs:date(substring(string(date:_as-datetime($date-time)), 1, 10)), '[MNn]') }
catch * { '' }`, with the `not($date-time)` early return for the absent
argument.

Now the story, because it is the session's core lesson. `format-date`'s
first parameter is typed **`xs:date?`** — a *date*, not a dateTime. Your
helper `date:_as-datetime` returns **`xs:dateTime`**, always, for every
parseable input. Handing a dateTime where a date is declared is a spec type
error, and this engine enforces it: the call raises `XPTY0004` (verified
with a catch-sentinel probe during this session's development). For a long
time the library's call site did *not* convert — it wrote
`format-date(date:_as-datetime($date-time), '[MNn]')` — and the surrounding
`try { … } catch * { '' }` did exactly what it was told: it converted the
type error into `''`. The result: `date:month-name` and six sibling
functions that share the pattern returned `''` for *every* parseable input,
and nothing crashed, so nothing complained. That is REQ-008: a latent
defect hidden by its own error handler. The repair is the one-line cast at
the call site you see above — take the dateTime's first ten characters and
cast them to `xs:date`. Seven functions, seven casts, and one new golden
case per function in `tests/cases/date/` now pin the correct answers. The
golden you are about to match is the *post-fix* world: real month names.

### Hints (progressive — try each before opening the next)

1. Write the library's repaired line: `format-date(xs:date(substring(string(date:_as-datetime($date-time)), 1, 10)), '[MNn]')`, inside the `try { … } catch * { '' }` skeleton, keeping the `not($date-time)` early return.
2. The conversion is not optional on this engine: with the raw `xs:dateTime`
   argument the call raises `XPTY0004`, and the `catch *` silently turns it
   into `''`. That is precisely the defect the library shipped under REQ-008 —
   seven functions returned `''` for every valid date until the cast was
   added. A catch block that "handles" an error by erasing the result is a
   bug amplifier, not error handling.
3. Predict the whole `<month>` column before running: `October`, `February`,
   `March`, `January` for the four parseable events; empty only for `mystery`
   and `overflow`, where the parser's `date:INVALID` is doing its lawful job.
   Two empty rows are the contract working; six were the bug.
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
same `try`/`catch *`, same early return, including the repaired `xs:date`
cast. The golden prints real month names for the four parseable events; only
`mystery` and `overflow` stay empty.

An honest-probe sidebar, because this session's own history proves the
point: during development, the *uncast* library line was described in these
pages as "`format-date` throws on this engine" — a claim that survived until
a catch-sentinel probe showed the truth. `format-date` itself works
perfectly with a proper `xs:date` argument; the `XPTY0004` came from the
library's own call site, and the `catch *` then laundered it into `''`. The
takeaways travel beyond this session: verify engine claims with a minimal
probe before recording them as fact, and treat a `catch * { '' }` around an
untested call site as a suspect, not a safety net — it turned one loud type
error into seven silently wrong functions (REQ-008). When you meet a
wrapper or one-liner in the library, ask both questions: does it run, and
does a golden prove what it returns? The compatibility matrix now answers
both for this family.

## 9. Go further

- **Pre/post-fix archaeology:** the git history of `src/dates-and-times.xsl`
  records REQ-008 — find the change that added the seven `xs:date` casts,
  run this session's case against the unpatched library (e.g. check out the
  parent version into a scratch copy), and watch every `<month>` empty out.
  Then restore the repaired version. Two worlds, one diff apart: the bug was
  invisible until a golden compared them.
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
