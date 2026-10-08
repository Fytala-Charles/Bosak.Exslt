// ===========================================================================================================================================================
// AUTHOR               : Charles Korthout
// CREATE DATE          : 06 October 2026
// PURPOSE              : XPath training harness: for every session under training/xpath/ with a case/meta.json, evaluates the solution expression and
//                        asserts it renders the golden result (Solution_matches_golden), and evaluates the starter expression and asserts it does NOT
//                        (Starter_differs_from_golden).
// SPECIAL NOTES        : Expressions are pure XPath 3.1, evaluated against the session's input.xml via the published Bosak.XPath.Api. Rendering matches
//                        training/xpath/README.md: atomic values as themselves, sequences item-by-item joined with " | ", empty sequence as "()".
//
// COPYRIGHT            : Fytala
// LICENSE              : LICENSE (Apache-2.0)
// SPDX-License-Identifier: Apache-2.0
// ===========================================================================================================================================================
// Change History:      |==================|=======|================|=========================================================================================
//                      |     Author       |Version|  Date          | Notes                                                                                    |
//                      |==================|=======|================|=========================================================================================
//                      | Charles Korthout | 0.1   | 06-10-2026     | Creation                                                                                 |
//                      | Charles Korthout | 0.2   | 06-10-2026     | Renamed tests: Solution_matches_golden / Starter_differs_from_golden                    |
//                      |==================|=======|================|=========================================================================================
// ===========================================================================================================================================================

using System.Text;
using Bosak.XPath.Api;
using Bosak.XPath.Core.Xdm;
using Bosak.XPath.Providers.Xml;
using Xunit;

namespace Bosak.Exslt.XPathTrainingTests;

/// <summary>
/// Executes the XPath foundations sessions: each directory under <c>xpath/</c> holding
/// a <c>case/meta.json</c> is a session. The harness evaluates the session's
/// <c>solution/exercise.xpath</c> and <c>starter/exercise.xpath</c> against the session's
/// <c>input.xml</c> with the Bosak XPath 3.1 engine, renders each result the way
/// <c>training/xpath/README.md</c> documents, and compares — as a whitespace-normalized
/// token stream — with <c>case/expected.txt</c>.
/// </summary>
public sealed class XPathTrainingTests
{
    private static string XPathRoot => Path.Combine(AppContext.BaseDirectory, "xpath");

    /// <summary>
    /// Discovers all XPath sessions: directories under <c>xpath/</c> whose names start
    /// with a two-digit number and that contain a <c>case/meta.json</c>. Directory names
    /// become the xUnit display names (e.g. <c>01-values-and-paths</c>).
    /// </summary>
    public static TheoryData<string> Sessions
    {
        get
        {
            var sessions = new TheoryData<string>();
            if (!Directory.Exists(XPathRoot))
            {
                return sessions;
            }

            foreach (var directory in Directory.EnumerateDirectories(XPathRoot, "0*"))
            {
                if (File.Exists(Path.Combine(directory, "case", "meta.json")))
                {
                    sessions.Add(Path.GetFileName(directory));
                }
            }

            return sessions;
        }
    }

    /// <summary>
    /// The reference answer must satisfy the golden contract; this guards the
    /// session's teaching material itself.
    /// </summary>
    /// <param name="session">Session directory name (e.g. <c>01-values-and-paths</c>).</param>
    [Theory]
    [MemberData(nameof(Sessions))]
    public void Solution_matches_golden(string session)
    {
        var actual = Render(Evaluate(session, "solution"));
        var expected = File.ReadAllText(Path.Combine(XPathRoot, session, "case", "expected.txt"));
        Assert.Equal(NormalizeText(expected), NormalizeText(actual));
    }

    /// <summary>
    /// The exercise must still be unsolved: if the starter already renders the golden
    /// result, the session has nothing left to teach and the build fails loudly.
    /// (A learner who solved the exercise in place sees this test fail — that means
    /// success; restore the stub for the next learner.)
    /// </summary>
    /// <param name="session">Session directory name (e.g. <c>01-values-and-paths</c>).</param>
    [Theory]
    [MemberData(nameof(Sessions))]
    public void Starter_differs_from_golden(string session)
    {
        var actual = Render(Evaluate(session, "starter"));
        var expected = File.ReadAllText(Path.Combine(XPathRoot, session, "case", "expected.txt"));
        Assert.False(NormalizeText(expected) == NormalizeText(actual),
            $"The starter for session '{session}' already renders the golden result — the exercise is gone.");
    }

    /// <summary>
    /// Compiles and evaluates one session variant (starter or solution) against the
    /// session's <c>input.xml</c>.
    /// </summary>
    private static XdmValue Evaluate(string session, string variant)
    {
        var sessionDirectory = Path.Combine(XPathRoot, session);
        var expressionPath = Path.Combine(sessionDirectory, variant, "exercise.xpath");

        var source = File.ReadAllText(expressionPath);
        var expression = XPath31Expression.Compile(source);
        var inputPath = Path.Combine(sessionDirectory, "input.xml");
        var context = new XDocumentNode(System.Xml.Linq.XDocument.Load(inputPath));
        return expression.Evaluate(context);
    }

    /// <summary>
    /// Renders a value the way training/xpath/README.md documents: atomic values as
    /// themselves, sequences item-by-item joined with " | ", the empty sequence as "()".
    /// </summary>
    private static string Render(XdmValue value)
    {
        if (value.IsUndefined)
        {
            return "()";
        }

        if (!value.IsSequence)
        {
            return value.ToString();
        }

        var builder = new StringBuilder();
        var enumerator = value.SequenceValue!.GetEnumerator();
        var first = true;
        while (enumerator.MoveNext())
        {
            if (!first)
            {
                builder.Append(" | ");
            }

            builder.Append(Render(enumerator.Current));
            first = false;
        }

        return builder.Length == 0 ? "()" : builder.ToString();
    }

    /// <summary>
    /// Reduces text output to its whitespace-separated token stream so that line
    /// endings and layout differences do not affect comparison.
    /// </summary>
    private static string NormalizeText(string text) =>
        string.Join(" ", text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
}
