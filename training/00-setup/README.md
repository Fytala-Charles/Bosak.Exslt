<div align="center">
  <img src="../../assets/logos/fytala-logo-color-dark.svg" width="100" alt="Fytala training session 00 — setup and tooling">
  <br><br>
  <h1>Session 00 — Setup &amp; Tooling</h1>
  <p>Installing and verifying VS Code, the Bosak extension, and .NET — plus a mini-guide to working in VS Code</p>
</div>

> **Time:** ~30 minutes · **Prerequisites:** a machine you can install software on
> **Exercise:** none — this session's "test" is the configuration check in §4

---

## 1. What you are installing

Three pieces of tooling power the whole curriculum:

| Tool | Why the training needs it | Required version |
|------|---------------------------|------------------|
| [.NET SDK](https://dotnet.microsoft.com/download) | Runs the test harness (`dotnet test`) that grades every session | **10.0+** |
| [VS Code](https://code.visualstudio.com/) | Editor for stylesheets, input documents, and test output | 1.80+ |
| **Bosak XPath / XSLT** extension (`fytala.vscode-bosak`) | Syntax highlighting, live diagnostics, completions, and one-click "run this transform" inside VS Code | 0.1.4+ |

One optional piece: [Node.js](https://nodejs.org/) 18+ — **only** if you build the
extension from source (§3, option C). If you install from the Marketplace or a
prebuilt VSIX, skip it.

> XPath is the language inside XSLT — every `select`, `match`, and `test`
> attribute is an XPath expression. This curriculum teaches XPath as you go,
> and the sessions that lean on it say so up front. If you want a structured
> foundation first, see the curriculum index (`training/README.md`) for the
> XPath prerequisites note.

## 2. Install the .NET SDK

1. Download the **.NET 10 SDK** (not just the runtime) from
   [dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).
2. Verify from a **new** terminal:

   ```bash
   dotnet --version
   ```

   You want `10.x.x`. If the command is not found, reopen the terminal (PATH
   updates only apply to new sessions).

## 3. Install VS Code and the Bosak extension

1. Install [VS Code](https://code.visualstudio.com/) (1.80 or newer). On
   Windows, accept the **"Add to PATH"** installer option — the configuration
   check in §4 calls the `code` command.

2. Install the **Bosak XPath / XSLT** extension (`fytala.vscode-bosak`).
   Three routes, easiest first:

   **Option A — from the Extensions Marketplace (recommended).**
   Open the Extensions view (`Ctrl+Shift+X`), search for
   **Bosak XPath / XSLT** (publisher: *fytala*), and click **Install**.

   **Option B — from a prebuilt VSIX.**
   Open VS Code → Extensions view (`Ctrl+Shift+X`) → **⋯** (More Actions) →
   **Install from VSIX…** → select the `vscode-bosak-*.vsix` file.

   **Option C — build from the Bosak repository (contributors).**
   ```bash
   cd /path/to/Bosak
   dotnet build src/Bosak.LanguageServer/Bosak.LanguageServer.csproj
   cd vscode-bosak
   npm install        # needs Node.js 18+
   npm run compile
   ```
   Then either press `F5` in VS Code (opens an Extension Development Host
   window with Bosak loaded), or package and sideload it:
   ```bash
   npx vsce package   # produces vscode-bosak-0.1.4.vsix
   ```
   …followed by Option B's *Install from VSIX* step.

3. If the extension reports **"Bosak language server not found"**, point it at
   the server binary explicitly — in VS Code settings (`Ctrl+,`, search
   "bosak"):
   ```json
   {
     "bosak.server.path": "D:/Development/Bosak/src/Bosak.LanguageServer/bin/Debug/net10.0/Bosak.LanguageServer.exe"
   }
   ```
   (Adjust the path to your Bosak checkout.)

## 4. Run the configuration check

From the repository root:

```bash
pwsh training/00-setup/check-setup.ps1 -RunTests
```

The script checks, in order:

1. `dotnet` on PATH at version 10+,
2. the `code` CLI on PATH,
3. the `fytala.vscode-bosak` extension installed,
4. Node.js 18+ (warning only — needed solely for building the extension),
5. with `-RunTests`: the training harness end-to-end — the strongest possible
   proof the toolchain is complete.

Every line should read `[PASS]`. If anything fails, fix it before continuing —
every later session assumes this green baseline. Re-run the check any time
your setup changes.

## 5. The anatomy of a test: from session folder to `dotnet test`

Everything you will build in this training — every exercise, every "test" — is
a **session folder**. The test harness turns each session folder into two
xUnit tests automatically; you never write C# and you never edit project
files. Here is the full contract, using the real session 01 as the example
(you can open every file on disk as you read):

```
training/01-xslt-basics/
│
├── README.md               THE LESSON — for humans only; no tool reads it.
│                           Explains the concept, walks the starter line by
│                           line, gives progressive hints, points at the
│                           solution and the library. Self-paced students live
│                           here.
│
├── input.xml               THE WORLD — the source document the transform runs
│                           against. Some sessions omit it (the transform
│                           creates its own data or needs no source).
│
├── starter/
│   └── transform.xsl       YOUR STARTING POINT — must compile and must run,
│                           but its output must DIFFER from the golden.
│                           → test: Starter_differs_from_golden
│
├── solution/
│   └── transform.xsl       THE REFERENCE ANSWER — its output must EQUAL the
│                           golden (after whitespace normalization).
│                           → test: Solution_matches_golden
│
└── case/                   THE CONTRACT — what "correct" means, plus where
    ├── expected.xml        the exercise came from.
    │                       Exactly one of:
    ├── expected.txt          • expected.xml — XML output, compared
    │                           structurally (layout-insensitive)
    └── meta.json             • expected.txt — text output, compared as a
                                token stream
                              meta.json — provenance: function, namespace,
                              tier, license source. Required: a "source" field.
```

### How `dotnet test` finds and runs these

1. **Build-time copy.** `training/TrainingTests/TrainingTests.csproj` copies
   every `training/0*` folder into its output directory (open
   `training/TrainingTests/TrainingTests.csproj` and look for the
   `<None Include="..\0*\**\*.*" …>` line). The transforms must live next to
   their `input.xml` and `case/` files for relative paths to work — that is
   the only reason the copy exists.
2. **Discovery.** At test time, the harness scans the copied tree for
   directories containing `case/meta.json`. That single marker file is what
   makes a folder a session. The folder name becomes the test display name.
3. **Two tests per session.** For each session the harness compiles and runs
   both transforms against `input.xml` and compares with the golden —
   asserting the solution matches it and the starter does not:

   ```text
   $ dotnet test training/TrainingTests/TrainingTests.csproj -v n
   ...
   ✔ 01-xslt-basics   Solution_matches_golden       (solution == golden)
   ✔ 01-xslt-basics   Starter_differs_from_golden   (starter != golden)
   ✔ 02-first-stylesheet   Solution_matches_golden
   ✔ 02-first-stylesheet   Starter_differs_from_golden
   ```

### The smallest possible session

Strip the idea to its bones — a hypothetical `99-hello` session. Five small
files, nothing else:

```text
training/99-hello/
├── input.xml
├── starter/transform.xsl
├── solution/transform.xsl
└── case/
    ├── expected.xml
    └── meta.json
```

`input.xml` — the world:
```xml
<?xml version="1.0"?>
<greeting>Hello</greeting>
```

`starter/transform.xsl` — compiles and runs, but says the wrong thing:
```xml
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
  <xsl:template match="greeting">
    <result>TODO</result>
  </xsl:template>
</xsl:stylesheet>
```

`solution/transform.xsl` — says the right thing:
```xml
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
  <xsl:template match="greeting">
    <result><xsl:value-of select="."/></result>
  </xsl:template>
</xsl:stylesheet>
```

`case/expected.xml` — the contract:
```xml
<?xml version="1.0"?>
<result>Hello</result>
```

`case/meta.json` — provenance:
```json
{
  "function": "(none — hello-world example)",
  "namespace": "http://www.w3.org/1999/XSL/Transform",
  "tier": 0,
  "source": { "project": "hand-written", "license": "Apache-2.0" }
}
```

That is the entire mechanism. `Starter_differs_from_golden` runs the starter,
gets `<result>TODO</result>`, sees it differs from `<result>Hello</result>`,
and passes. `Solution_matches_golden` runs the solution, sees equality, and
passes. When you author a real session later (the capstone, session 11,
teaches the full workflow), you create exactly these five files in a new
`NN-slug/` folder — the harness and `dotnet test` pick it up on the next
build. The XPath track (`training/xpath/`) uses the same anatomy with one
difference: the artifact under test is `exercise.xpath` (one expression)
instead of `transform.xsl`, and goldens are usually `expected.txt`.

## 6. A 10-minute tour of VS Code for this training

You need surprisingly little VS Code knowledge for the curriculum. Five
habits cover everything:

**Open the workspace as a folder.** `File → Open Folder…` → select the
`Bosak.Exslt` repository root. Everything in this training — lessons,
starters, goldens — is reachable from the Explorer (`Ctrl+Shift+E`).

**Let the extension check your typing.** Open
`training/01-xslt-basics/starter/transform.xsl`. You should see XSLT
syntax highlighting immediately, and the document outline (top of the
Explorer side bar) listing the templates and functions. Now break something:
delete the `</xsl:function>` closing tag from one function. Within a second a
red squiggle appears and the **Problems** panel (`Ctrl+Shift+M`) shows the
compile error. Undo (`Ctrl+Z`). That loop — type, see diagnostics, fix — is
half of how you will work.

**Use completions and hover.** Inside any `select="…"` attribute, press
`Ctrl+Space` for XPath function and axis completions; hover over a function
name for its signature. You will write XPath for eleven sessions — let the editor
teach you the library.

**Run transforms with one click.** Open the starter stylesheet from the
previous step, then either use the editor title-bar / context-menu command
**Bosak: Run XSLT Transformation**, or the CodeLens link above the template.
The extension prompts for a source document — pick
`training/01-xslt-basics/input.xml` — and opens the result in a preview
editor. That is the fastest feedback loop for experimenting; the *graded*
loop is the test harness below.

**Run the tests in the integrated terminal.** Open the terminal with
`` Ctrl+` `` and run:

```bash
dotnet test training/TrainingTests/TrainingTests.csproj
```

Keep this terminal open during a session: edit the starter, re-run the
command, read the diff. That is TDD.

## 7. Optional: your first XPath expression

The extension also speaks XPath directly. Create a file `hello.xpath` in the
workspace root with this single line:

```xpath
(1 to 5) ! (. * .)
```

Save, then right-click → **Bosak: Evaluate XPath Expression** (or the
Command Palette, `F1`, same name). The preview shows the squared numbers.
`.xpath` files are a sandbox for expressions — use them freely alongside the
sessions.

## 8. Done?

The configuration check is green, you have run a transform by hand, you know
what a session folder is made of (section 5), and you know where the Problems
panel and the terminal live. That is everything the curriculum assumes.
Continue with
[Session 01 — XSLT Basics](../01-xslt-basics/README.md).

---

<div align="center" style="background:#2F4F4F; color:#F0FFF0; padding:1rem; border-radius:12px; margin-top:2rem;">
  <p style="margin:0; font-family:Poppins,Segoe UI,sans-serif;">
    <strong>© Fytala</strong> — Bosak.Exslt Training
  </p>
</div>
