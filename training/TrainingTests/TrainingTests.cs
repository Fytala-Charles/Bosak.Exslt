// ===========================================================================================================================================================
// AUTHOR               : Charles Korthout
// CREATE DATE          : 06 October 2026
// PURPOSE              : Training harness: for every session under training/ with a case/meta.json, asserts the solution transform matches the golden
//                        output (Solution_matches_golden) and the starter transform does NOT match it yet (Starter_differs_from_golden).
// SPECIAL NOTES        : Mirrors the comparison logic of tests/Bosak.Exslt.Tests/GoldenFileTests.cs (same published Bosak packages). Training
//                        stylesheets are self-contained and never include src/, so this harness copies no library files.
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
//                      | Charles Korthout | 0.3   | 06-10-2026     | Session discovery: enumerate every directory (sessions 10+ do not start with "0");    |
//                      |                  |       |                | the case/meta.json marker still does the filtering                                     |
//                      |==================|=======|================|=========================================================================================
// ===========================================================================================================================================================

using System.Xml.Linq;
using Bosak.XPath.Providers.Xml;
using Bosak.Xslt.Api;
using Xunit;

namespace Bosak.Exslt.TrainingTests;

/// <summary>
/// Executes the training sessions: each directory under <c>training/</c> holding a
/// <c>case/meta.json</c> is a session. The harness compiles the session's
/// <c>solution/transform.xsl</c> and <c>starter/transform.xsl</c> with the Bosak XSLT
/// compiler, runs each against the session's optional <c>input.xml</c>, and compares —
/// after whitespace normalization — with <c>case/expected.xml</c> or <c>case/expected.txt</c>.
/// </summary>
public sealed class TrainingTests
{
    private static string TrainingRoot => Path.Combine(AppContext.BaseDirectory, "training");

    /// <summary>
    /// Discovers all training sessions: directories under <c>training/</c> that
    /// contain a <c>case/meta.json</c> (numbered <c>NN-slug/</c> by convention —
    /// sessions 10+ no longer start with "0", so the enumeration matches every
    /// directory and lets the meta.json marker do the filtering). Directory
    /// names become the xUnit display names (e.g. <c>01-xslt-basics</c>).
    /// </summary>
    public static TheoryData<string> Sessions
    {
        get
        {
            var sessions = new TheoryData<string>();
            if (!Directory.Exists(TrainingRoot))
            {
                return sessions;
            }

            foreach (var directory in Directory.EnumerateDirectories(TrainingRoot))
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
    /// <param name="session">Session directory name (e.g. <c>02-first-stylesheet</c>).</param>
    [Theory]
    [MemberData(nameof(Sessions))]
    public void Solution_matches_golden(string session)
    {
        var caseDirectory = Path.Combine(TrainingRoot, session, "case");
        var actual = Run(session, "solution");

        var expectedXml = Path.Combine(caseDirectory, "expected.xml");
        if (File.Exists(expectedXml))
        {
            var expected = File.ReadAllText(expectedXml);
            Assert.True(TryCompareXml(expected, actual, out var difference), difference);
        }
        else
        {
            var expected = File.ReadAllText(Path.Combine(caseDirectory, "expected.txt"));
            Assert.Equal(NormalizeText(expected), NormalizeText(actual));
        }
    }

    /// <summary>
    /// The exercise must still be unsolved: if the starter already produces the golden
    /// output, the session has nothing left to teach and the build fails loudly.
    /// (A learner who solved the exercise in place sees this test fail — that means
    /// success; restore the stub for the next learner.)
    /// </summary>
    /// <param name="session">Session directory name (e.g. <c>02-first-stylesheet</c>).</param>
    [Theory]
    [MemberData(nameof(Sessions))]
    public void Starter_differs_from_golden(string session)
    {
        var caseDirectory = Path.Combine(TrainingRoot, session, "case");
        var actual = Run(session, "starter");

        bool matches;
        var expectedXml = Path.Combine(caseDirectory, "expected.xml");
        if (File.Exists(expectedXml))
        {
            matches = TryCompareXml(File.ReadAllText(expectedXml), actual, out _);
        }
        else
        {
            var expected = File.ReadAllText(Path.Combine(caseDirectory, "expected.txt"));
            matches = NormalizeText(expected) == NormalizeText(actual);
        }

        Assert.False(matches,
            $"The starter for session '{session}' already produces the golden output — the exercise is gone.");
    }

    /// <summary>
    /// Compiles and runs one session variant (starter or solution) against the
    /// session's <c>input.xml</c> when present, else an empty document.
    /// </summary>
    private static string Run(string session, string variant)
    {
        var sessionDirectory = Path.Combine(TrainingRoot, session);
        var transformPath = Path.Combine(sessionDirectory, variant, "transform.xsl");

        var xsl = File.ReadAllText(transformPath);
        var compiler = new XsltCompiler();
        var executable = compiler.Compile(xsl, new Uri(transformPath).AbsoluteUri);

        var inputPath = Path.Combine(sessionDirectory, "input.xml");
        var source = File.Exists(inputPath)
            ? new XDocumentNode(XDocument.Load(inputPath))
            : new XDocumentNode(new XDocument());

        return executable.TransformToString(source);
    }

    /// <summary>
    /// Compares two XML documents semantically for golden purposes: both are parsed
    /// with insignificant whitespace discarded, then re-serialized without formatting.
    /// </summary>
    private static bool TryCompareXml(string expected, string actual, out string difference)
    {
        difference = string.Empty;

        XDocument expectedDocument;
        XDocument actualDocument;
        try
        {
            actualDocument = XDocument.Parse(actual, LoadOptions.None);
        }
        catch (Exception exception) when (exception is System.Xml.XmlException or InvalidOperationException)
        {
            difference = $"Actual output is not well-formed XML: {exception.Message}{Environment.NewLine}{actual}";
            return false;
        }

        try
        {
            expectedDocument = XDocument.Parse(expected, LoadOptions.None);
        }
        catch (Exception exception) when (exception is System.Xml.XmlException or InvalidOperationException)
        {
            difference = $"Expected golden file is not well-formed XML: {exception.Message}";
            return false;
        }

        var expectedCanonical = expectedDocument.ToString(SaveOptions.DisableFormatting);
        var actualCanonical = actualDocument.ToString(SaveOptions.DisableFormatting);
        if (expectedCanonical != actualCanonical)
        {
            difference = $"XML mismatch.{Environment.NewLine}Expected:{Environment.NewLine}{expectedCanonical}" +
                         $"{Environment.NewLine}Actual:{Environment.NewLine}{actualCanonical}";
            return false;
        }

        return true;
    }

    /// <summary>
    /// Reduces text output to its whitespace-separated token stream so that line
    /// endings and layout differences do not affect comparison.
    /// </summary>
    private static string NormalizeText(string text) =>
        string.Join(" ", text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
}
