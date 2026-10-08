// ===========================================================================================================================================================
// AUTHOR               : Charles Korthout
// CREATE DATE          : 06 October 2026
// PURPOSE              : Golden-file test harness: runs every case under tests/cases through the Bosak XSLT engine and compares with the golden output.
// SPECIAL NOTES        : Test project follows the house harness idioms of the Bosak core (XsltCompiler + XDocumentNode + TransformToString).
//
// COPYRIGHT            : Fytala
// LICENSE              : LICENSE (Apache-2.0)
// SPDX-License-Identifier: Apache-2.0
// ===========================================================================================================================================================
// Change History:      |==================|=======|================|=========================================================================================
//                      |     Author       |Version|  Date          | Notes                                                                                    |
//                      |==================|=======|================|=========================================================================================
//                      | Charles Korthout | 0.1   | 06-10-2026     | Creation                                                                                 |
//                      | Charles Korthout | 0.2   | 08-10-2026     | REQ-003: package-mode cases — meta.json "mode":"package" triggers lazy registration of   |
//                      |                  |       |                | the src/pkg descriptors via XsltFunctionLibrary.RegisterPackage.                          |
//                      |==================|=======|================|=========================================================================================
// ===========================================================================================================================================================

using System.Xml.Linq;
using Bosak.XPath.Providers.Xml;
using Bosak.Xslt.Api;
using Xunit;

namespace Bosak.Exslt.Tests;

/// <summary>
/// Executes the golden-file corpus: each directory under <c>cases/</c> holding a
/// <c>transform.xsl</c> is compiled with the Bosak XSLT compiler, run against the
/// optional <c>input.xml</c>, and compared — after whitespace normalization — with
/// <c>expected.xml</c> or <c>expected.txt</c>.
/// </summary>
public sealed class GoldenFileTests
{
    private static string CasesRoot => Path.Combine(AppContext.BaseDirectory, "cases");

    /// <summary>
    /// Discovers all golden cases: directories below <c>cases/</c> containing a
    /// <c>transform.xsl</c>. Paths are relative to the cases root so test names
    /// read as <c>math/max.1</c>.
    /// </summary>
    public static TheoryData<string> Cases
    {
        get
        {
            var cases = new TheoryData<string>();
            foreach (var directory in Directory.EnumerateDirectories(CasesRoot, "*", SearchOption.AllDirectories))
            {
                if (File.Exists(Path.Combine(directory, "transform.xsl")))
                {
                    cases.Add(Path.GetRelativePath(CasesRoot, directory));
                }
            }

            return cases;
        }
    }

    /// <summary>
    /// Runs a single golden case and asserts the transform output matches the golden file.
    /// </summary>
    /// <param name="case">Case directory relative to the cases root (e.g. <c>math/max.1</c>).</param>
    [Theory]
    [MemberData(nameof(Cases))]
    public void Golden_case_matches(string @case)
    {
        var caseDirectory = Path.Combine(CasesRoot, @case);
        var transformPath = Path.Combine(caseDirectory, "transform.xsl");

        if (CaseRunsInPackageMode(caseDirectory))
        {
            RegisterPackagesOnce();
        }

        var xsl = File.ReadAllText(transformPath);
        var compiler = new XsltCompiler();
        // The base URI lets xsl:import/xsl:include inside the transform resolve the
        // library modules via their relative hrefs.
        var executable = compiler.Compile(xsl, new Uri(transformPath).AbsoluteUri);

        var inputPath = Path.Combine(caseDirectory, "input.xml");
        var source = File.Exists(inputPath)
            ? new XDocumentNode(XDocument.Load(inputPath))
            : new XDocumentNode(new XDocument());

        var actual = executable.TransformToString(source);

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

    private static bool packagesRegistered;

    /// <summary>
    /// True when the case's <c>meta.json</c> carries <c>"mode": "package"</c>:
    /// the transform uses <c>xsl:use-package</c> and the EXSLT package
    /// descriptors must be registered with the engine first.
    /// </summary>
    private static bool CaseRunsInPackageMode(string caseDirectory)
    {
        var metaPath = Path.Combine(caseDirectory, "meta.json");
        if (!File.Exists(metaPath))
        {
            return false;
        }

        try
        {
            using var document = System.Text.Json.JsonDocument.Parse(File.ReadAllText(metaPath));
            return document.RootElement.TryGetProperty("mode", out var mode)
                   && mode.GetString() == "package";
        }
        catch (System.Text.Json.JsonException)
        {
            return false;
        }
    }

    /// <summary>
    /// Registers every <c>src/pkg/*.package.xsl</c> descriptor with the engine's
    /// static package registry. Runs at most once per test process; the engine's
    /// re-registration behavior is undefined, so double registration is avoided.
    /// </summary>
    private static void RegisterPackagesOnce()
    {
        if (packagesRegistered)
        {
            return;
        }

        var packageDirectory = Path.Combine(AppContext.BaseDirectory, "src", "pkg");
        foreach (var packageFile in Directory.EnumerateFiles(packageDirectory, "*.package.xsl"))
        {
            var package = XDocument.Load(packageFile);
            var root = package.Root!;
            var name = root.Attribute("name")!.Value;
            var version = root.Attribute("package-version")!.Value;
            XsltFunctionLibrary.RegisterPackage(name, version, new Uri(packageFile).AbsoluteUri);
        }

        packagesRegistered = true;
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
