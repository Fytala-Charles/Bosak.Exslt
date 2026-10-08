<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 04 — regular expressions">
  <br><br>
  <h1>Session 04 — Regular Expressions</h1>
  <p>Splitting and classifying text: <code>str:tokenize</code>, <code>str:split</code>, <code>str:encode-uri</code></p>
</div>

> **Time:** ~60 minutes · **Prerequisites:** [session 03 — recursion as the basic loop](../03-recursion/README.md) and [session 00](../00-setup/README.md) for tooling; [XPath foundations sessions 1–2](../xpath/README.md) if you have never written XPath
> **Vehicle:** EXSLT strings module (`http://exslt.org/strings`)

---

## 1. Text rarely arrives as nodes

Sessions 01–03 transformed XML — data that already *was* markup. Real data
often arrives as **strings**: one log line, one comma-separated field, one URI.
Before you can transform it, you have to take it apart. XPath 3.1 offers
`fn:tokenize($string, $pattern)`: split a string on a **regular expression**
and get the pieces back as a sequence of strings. EXSLT had the same idea in
2001 — before regexes were standard — in two flavors:

- `str:tokenize` takes a set of **literal delimiter characters**: *any one* of
  them separates tokens. A delimiter of `'.'` means a dot, never "any
  character".
- `str:split` takes a full **regular expression** as the separator, and drops
  the separators entirely.

Both return the pieces wrapped in `<token>` elements — a concession to XSLT
1.0, where only nodes could be processed further. We keep that shape because
the golden output pins it.

`str:encode-uri` rounds the session out: there is **no regex shortcut** for
percent-encoding. Classifying characters — "is this one allowed in a URI?" —
is a per-character decision, which is why the exercise reuses session 03's
recursion.

## 2. Your task

Open `starter/transform.xsl` and run the test:

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

(From the repository root: `dotnet test training/TrainingTests/TrainingTests.csproj`.)

Three exercises, each one a stub or a naive attempt in the starter:

1. **`str:tokenize($string, $delimiters)`** — split on a set of literal
   characters, wrapped in `<token>` elements (exercise 1, section 4).
2. **`str:split($string, $pattern)`** — regex split on one pattern, separators
   discarded, empty pieces dropped (exercise 2, section 5).
3. **`str:encode-uri($uri, $encode-reserved)`** — percent-encode characters
   outside the allowed set (exercise 3, section 6).

## 3. Reading the starter — and an honest note about this engine

The starter's template runs one call of each function against `input.xml`: a
log line with several delimiter characters *and* doubled delimiters, a phrase
for the whitespace default, a comma list with empty entries, a word to split
into characters, and two URIs to encode.

Two definitions are given and should be studied, not changed. The first is the
one-argument `str:tokenize`, which delegates with an empty delimiters argument
— the "default parameter" pattern from session 03. The second is more
interesting:

```xml
<xsl:function name="str:make-tokens" as="element(token)*">
  <xsl:param name="strings" as="xs:string*"/>
  <xsl:for-each select="$strings[. ne '']">
    <token>
      <xsl:value-of select="."/>
    </token>
  </xsl:for-each>
</xsl:function>
```

The predicate `$strings[. ne '']` **drops zero-length tokens**. That filter is
not in the EXSLT spec — it is there because of this session's first engine
quirk (read `docs/AGENT_HANDOVER.md` §4 for the full list):

1. **The Bosak engine keeps zero-length tokens** that `fn:tokenize` should
   drop: `tokenize('a,,b', ',')` yields the empty string as the middle item.
   One filter in `str:make-tokens` absorbs the quirk for both split functions.
2. **`xsl:analyze-string` content instructions misbehave inside
   `xsl:function` bodies** on this engine, so nothing you write today uses
   them — Section 8 explains what `analyze-string` is for and why the library
   avoids it too.
3. **FLWOR expressions support a single `for`/`let` clause.** Flatten nested
   loops into sequences of calls, as the library does.

These quirks are part of the material: professional XSLT is often written
against a real engine, and "conformant XSLT that happens to run correctly
here" is a skill in itself. Every workaround used today is conformant XSLT
3.0 — run it on any other processor and it behaves identically.

## 4. Exercise 1: implement `str:tokenize`

The starter's version passes the delimiters **straight into `fn:tokenize`**:

```xml
<xsl:sequence select="str:make-tokens(tokenize($string, if (not($delimiters)) then '\s+' else $delimiters))"/>
```

Read it until you see the bug. `fn:tokenize` reads its second argument as a
regular expression. The EXSLT contract says `$delimiters` is a set of literal
characters — but the starter hands the regex engine the character `'.'`, and
in regexland `.` means **any character**. The log line comes out sliced into
single characters. (This is also why a delimiter like `|` or `(` would break
the naive version in its own way.)

### What you know going in

- The contract: *any one* of the delimiter characters separates tokens. With
  `' .:'` as delimiters, `deploy.fytala.nl:` splits on dots, the colon, and
  spaces alike.
- Doubled delimiters (`'  '`, `'.'`) produce **empty tokens that the golden
  output drops** — `str:make-tokens` already handles that part.
- Golden output lines that depend on this exercise: `<log>` and `<words>`.

### Hints (progressive — try each before opening the next)

1. You need one regex that matches any single delimiter character: the
   escaped characters, joined with `|` (regex "or"). `string-join($pieces,
   '|')` does the joining; the `for ... return` expression maps over the
   delimiter characters one by one. Keep it to a **single** `for` clause —
   remember quirk 3.
2. Visit the characters of a string with `string-to-codepoints($delimiters)`
   and turn each codepoint back with `codepoints-to-string($c)`.
3. Escape each character with `fn:replace`: a character that is one of the
   regex metacharacters (`.[\\|^$*+?(){}-`) becomes a backslash plus itself.
   The library writes this as one `replace` call with a parenthesized
   alternation and `'\\$1'` as the replacement — study that pattern; it is the
   standard idiom.
4. The whitespace default: when `$delimiters` is absent or empty, the pattern
   is the two characters `\s+` (regex for "a run of whitespace"). The starter
   shows the shape.
5. Still stuck? `src/strings.xsl` — look for `str:tokenize`. Read it, close
   it, write your version from memory.

## 5. Exercise 2: implement `str:split`

`str:split` is the regex-powered sibling: the **pattern is a real regex** and
the separators are discarded. The starter's version wraps whatever
`fn:tokenize` returns — including the engine's zero-length tokens (quirk 1).
Watch it fail: `<csv>alpha,,gamma,,,delta</csv>` should yield three tokens,
but the naive version emits an empty `<token/>` for every doubled comma.

The empty-pattern branch is **given** in the starter, and deliberately so: an
empty pattern means "split into individual characters", which is pure codepoint
arithmetic from session 03 — `string-to-codepoints` followed by
`codepoints-to-string(.)` per item — not regular expressions at all.

### Hints (progressive — try each before opening the next)

1. The fix for the naive version is one word: the filtering already exists.
   Route the `fn:tokenize` result through `str:make-tokens` instead of wrapping
   it yourself.
2. The default branch: when `$pattern` is absent (the empty sequence, not the
   empty string), split on whitespace runs — the same `'\s+'` pattern as
   exercise 1.
3. Keep the given `$pattern eq ''` branch first in the `xsl:choose`; an empty
   string is a *request for characters*, not "no pattern".
4. Predict before you run: how many `<token>` elements does
   `str:split('a,,b', ',')` produce on this engine, with and without the
   filter? Then add a line to the template and check.
5. Still stuck? `src/strings.xsl` — look for `str:split`.

## 6. Exercise 3: implement `str:encode-uri`

Percent-encoding has no regex form: for each character you must *decide* —
allowed, or `%XX`? RFC 3986 names the always-allowed characters the
**unreserved** set:

```
A–Z  a–z  0–9  -  _  .  ~
```

Everything else is escaped, with one switch. The EXSLT boolean
`$encode-reserved` selects the mode:

- `true()` — **encode-for-uri** semantics: only unreserved characters survive.
  A path separator `/` becomes `%2F`.
- `false()` — **iri-to-uri** semantics: the *reserved* characters
  (`: / ? # % [ ] @ ! $ & ' ( ) * + , ; =`) also survive; only characters
  illegal in a URI (like the space) are escaped.

The starter's stub returns the URI unchanged — the golden `<encoded>` lines
are full of `%20`s that never appear.

### Scope, honestly stated

This exercise encodes **ASCII input only**: each escaped character becomes
`'%'` plus two uppercase hex digits of its Unicode codepoint (which, for
ASCII, equals its byte value). Real URIs are UTF-8: an `é` is *two* bytes and
becomes `%C3%A9`, which per-character codepoint arithmetic cannot produce.
That gap is deliberate — Section 8 shows why the library delegates the full
job to native functions, and "Go further" invites you to close it.

### Hints (progressive — try each before opening the next)

1. Write the unreserved set as one string of literals and the reserved set as
   another. The keep-set for the `true()` mode is the first string; for
   `false()` it is `concat($unreserved, $reserved)`. Two modes, one variable.
2. Walk the string with session 03's tail recursion: one character per call,
   `substring($remaining, 1, 1)` to look at it, `substring($remaining, 2)` for
   the rest, `concat` to assemble.
3. Classification is `contains($keep, $c)` — a character is a one-character
   string.
4. Hex digits: `substring('0123456789ABCDEF', $code idiv 16 + 1, 1)` gives the
   high digit, `$code mod 16 + 1` the low one. `idiv` is integer division from
   session 03.
5. Predict the odd-looking golden line before you run: in iri mode, `%` is a
   reserved character, so `100% sure` encodes to `100%%20sure` — a bare `%`
   passes through untouched.
6. Still stuck? `src/strings.xsl` — look for `str:encode-uri` (but expect it
   to be a one-line wrapper; your hand-rolled version is the lesson).

## 7. Checking your work

```bash
dotnet test ../TrainingTests/TrainingTests.csproj
```

- `Starter_differs_from_golden` **passes** — good: it asserts your starter is still
  unsolved, guarding the exercise for the next learner.
- To check *your* implementation, paste it into the starter and watch the
  `<log>`, `<csv>`, `<chars>`, and `<encoded>` lines of the test diff. When your
  output equals `case/expected.xml`, you are done. (If you edited `starter/transform.xsl`
  directly, the `Starter_differs_from_golden` test will now fail — that failure means
  *success* for you; restore the stub when you finish the session so the
  exercise stays RED for the next learner.)

You can also run the transform by hand in VS Code with the Bosak extension,
using `input.xml` as the source document.

## 8. Compare with the library

Open `src/strings.xsl`.

**`str:tokenize`** builds its pattern exactly the way exercise 1 asks you to:
one `replace` per delimiter character, escaped metacharacters, joined with
`|`. When your solution goes green, you have independently re-derived the
library's approach — that is the migration story tier 1 exists for.

**`str:split`** — notice what it is *not*: it never calls
`xsl:analyze-string`. That instruction is the natural third tool here: where
`tokenize` gives you the pieces *between* separators, `analyze-string` walks
the string once and lets you build a different result for the matching parts
and the non-matching parts (its `matching-substring`/`non-matching-substring`
children). On this engine (quirk 2), content instructions inside those
elements serialize literally **inside `xsl:function` bodies**, so the library
builds `str:split` on `fn:tokenize` instead — and `date:_parse-duration` uses
only `select`-valued `matching-substring`, which works. Same quirk, two
conformant workarounds. When you meet `analyze-string` in later XSLT work,
remember: its power is the dual view of the string; its cost on this engine is
where you are allowed to use it.

**`str:encode-uri`** is one `xsl:sequence` long: `encode-for-uri($uri)` or
`iri-to-uri($uri)`. XPath 3.1 grew native functions that do the whole job —
including UTF-8 byte encoding, the part this session deliberately scoped away.
Your exercise exists to teach the *contract* those functions fulfill:
unreserved versus reserved, `%XX` uppercase hex, iri mode preserving `%`.
Read native functions this way from now on: wrapper on the outside, contract
understood on the inside.

## 9. Go further

- **UTF-8, for real:** extend `str:encode-uri-scan` so a codepoint above 127
  emits one `%XX` per UTF-8 byte (`é` = U+00E9 = bytes C3 A9 → `%C3%A9`).
  Hint: a codepoint encodes to 2 bytes when below 2048; the first byte is
  `192 + $code idiv 64`. Compare with what `encode-for-uri('é')` returns.
- **Decode:** `str:decode-uri` reverses today's exercise — scan for `%`, read
  two hex digits, emit the character. Pure session 03 recursion; the library
  version is in `src/strings.xsl`.
- **`analyze-string` safari:** write a tiny stylesheet (not inside an
  `xsl:function`) that wraps `hello 42 world` in `<num>` tags around the
  digits using `xsl:analyze-string`. Then move the identical code into an
  `xsl:function` and observe quirk 2 firsthand.
- **Peek ahead:** session 05 replaces several search strings in one
  left-to-right pass. Why can't `fn:tokenize` express "split on whichever of
  these comes first"?

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
