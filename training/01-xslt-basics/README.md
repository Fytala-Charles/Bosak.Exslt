<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 01 — XSLT basics">
  <br><br>
  <h1>Session 01 — XSLT Basics</h1>
  <p>Templates and the processing model: how a stylesheet turns XML into XML</p>
</div>

> **Time:** ~45 minutes · **Prerequisites:** [session 00](../00-setup/README.md) for tooling; [XPath foundations session 1](../xpath/01-values-and-paths/README.md) (paths) — that is all the XPath you need here
> **Exercise:** transform `input.xml` into the golden roster document

---

## 1. What XSLT actually does

XSLT is a **transformation language**. You give it an XML source document and a
stylesheet; it produces a result document (XML, HTML, or plain text). The core
idea is older and simpler than it looks:

> A stylesheet is a **list of template rules**. The processor walks the source
> document from the root down; for every node it visits, it looks for a rule
> whose `match` pattern fits, and follows the rule's instructions to build a
> piece of the result.

That walk — nodes in, template rules matched, result nodes emitted — is the
**processing model**, and it is 80% of what you need to read any XSLT.

## 2. The processing model in five sentences

1. The processor starts at the **document node** of the source with an empty
   result.
2. It finds the best-matching `xsl:template` for the current node and executes
   its body — the template **content**.
3. Literal XML written in the body (elements, text) is **copied to the result**
   — it is called *literal result elements*.
4. XSLT instructions in the body (`xsl:value-of`, `xsl:for-each`, …) are
   **executed**; they select nodes with XPath and emit result content.
5. Unless told otherwise (`xsl:apply-templates`), the walk does **not**
   continue into the children — a template decides explicitly what happens
   next. If *no* rule matches a node, a built-in rule kicks in: it just walks
   through to the children (and copies text nodes it meets — you will see this
   in "Go further").

## 3. Reading the starter

Open `starter/transform.xsl`:

```xml
<xsl:template match="team">
  <roster count="TODO">
    <!-- EXERCISE (see README section 5) -->
  </roster>
</xsl:template>
```

- `match="team"` — the rule fires whenever the walk reaches a `<team>`
  element. Inside the body, the **context item** `.` is that team element, so
  XPath steps like `member` mean "child elements named `member` of the team".
- `<roster count="TODO">` — a literal result element. It lands in the output
  exactly as written… except that an attribute written `{...}` is an
  **attribute value template**: the XPath inside the braces is evaluated and
  its value substitutes the braces. `count="TODO"` is just the literal word
  TODO for now — the exercise is to make it `count="3"`.
- The `<!-- comment -->` and the whitespace around it produce **nothing**:
  comments are stripped by XSLT, and whitespace-only text nodes inside a
  template body are dropped. That is why the starter's output is simply
  `<roster count="TODO"/>` — compact and predictable. (It also means: keep
  instructions that emit text on one line, or the whitespace becomes part of
  your output — the golden comparison *is* whitespace-sensitive.)

The two instructions you need for the exercise:

```xml
<xsl:value-of select="."/>
```

evaluates the XPath in `select` and writes its value into the result — here,
the text of the current member.

```xml
<xsl:for-each select="member">
  ...
</xsl:for-each>
```

executes its body once per item in the selected sequence, each time with `.`
bound to that item. It is the everyday loop of XSLT — session 02 will show
you the recursive alternative for when a loop is not enough.

## 4. Try it live

Open the starter in VS Code and run **Bosak: Run XSLT Transformation** against
`input.xml`. The preview shows `<roster count="TODO"/>`. After each edit,
re-run: this is the fastest feedback loop you have.

## 5. The exercise

The golden output (`case/expected.xml`) is:

```xml
<roster count="3"><name>Ada</name><name>Grace</name><name>Alan</name></roster>
```

Turn the stub into a transform that produces it. Three things to build:

1. the `count` attribute — an XPath that counts the members (look at the
   `count` hint below if stuck);
2. one `<name>` element per `<member>`;
3. each name holding that member's text.

### Hints (progressive)

1. `count="TODO"` becomes `count="{...}"` — attribute value template syntax.
   Inside the braces, you need an XPath that returns the number of members.
   There is a function literally named `count` that takes a sequence and
   returns its length.
2. `<xsl:for-each select="...">` with the right path gives you the loop; the
   body of the loop executes once per member, with `.` = that member.
3. Inside the loop, `<xsl:value-of select="."/>` writes the member's text.
4. Whitespace: write the loop body on one line inside `<roster>`, or stray
   whitespace will sneak into the output (see section 3).
5. Still stuck? `solution/transform.xsl` is the reference — read it, close it,
   write your own.

## 6. Checking your work

```bash
dotnet test ../../TrainingTests/TrainingTests.csproj
```

From the repository root:
`dotnet test training/TrainingTests/TrainingTests.csproj`.

- `Solution_matches_golden` **passes** — the harness guarding the reference
  material for the next learner.
- `Starter_differs_from_golden` **passes** on the untouched stub — it fails
  only when your starter's output *equals* the golden. That failure is your
  success signal; restore the stub afterwards so the exercise stays RED for
  the next learner.

(Remember: `dotnet test -v n` shows the individual test names.)

## 7. Go further

- **Roles:** change the loop so each name keeps its role:
  `<name role="dev">Grace</name>` — attribute value templates work inside
  literal result elements too.
- **The built-in rules:** delete the whole template from your copy and run.
  You get plain text `AdaGraceAlan`! The walk used built-in rules: no match
  for `<team>` → walk children; no match for `<member>` → walk children; text
  nodes are copied by the built-in rule. This default behavior is why tiny
  stylesheets can do surprisingly much — and why an empty stylesheet still
  produces output.
- **Apply-templates:** replace the `for-each` with
  `<xsl:apply-templates select="member"/>`, add a second template
  `match="member"` that emits `<name><xsl:value-of select="."/></name>`, and
  convince yourself the result is identical. This "one rule per element type"
  style is the idiomatic XSLT you will meet everywhere; `for-each` is the
  convenient shortcut. Session 04 (`str:replace`) is where the difference
  starts to matter.
- **Peek ahead:** session 02 builds the same shape of output — but computes
  *values* (minimum, maximum) instead of copying them, using functions you
  define yourself.

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
