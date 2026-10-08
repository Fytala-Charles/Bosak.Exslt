// ===========================================================================================================================================================
// AUTHOR               : Charles Korthout
// CREATE DATE          : 08 October 2026
// PURPOSE              : Samples harness (REQ-005): runs every samples/<module>/ pair (legacy.xsl + modern.xsl)
//                        through the Bosak XSLT engine and compares with the captured outputs.
// SPECIAL NOTES        : Follows the GoldenFileTests idioms: compile with a file base URI (so the
//                        legacy stylesheets' ../../src/exslt.xsl import resolves in the output
//                        directory), optional input.xml, whitespace-normalized XML compare or
//                        token-stream text compare.
//
// COPYRIGHT            : Fytala
// LICENSE              : LICENSE (Apache-2.0)
// SPDX-License-Identifier: Apache-2.0
// ===========================================================================================================================================================
// Change History:      |==================|=======|================|=========================================================================================
//                      |     Author       |Version|  Date          | Notes                                                                                    |
//                      |==================|=======|================|=========================================================================================
//                      | Charles Korthout | 0.1   | 08-10-2026     | Creation (REQ-005)                                                                       |
//                      |==================|=======|================|=========================================================================================
// ===========================================================================================================================================================

using System.Xml.Linq;
using Bosak.XPath.Providers.Xml;
using Bosak.Xslt.Api;
using Xunit;

namespace Bosak.Exslt.Tests;

/// <summary>
/// Executes the sample gallery: each directory under <c>samples/</c> holding a
/// <c>legacy.xsl</c> must run (against its optional <c>input.xml</c>) and match the
/// engine-captured <c>output.legacy.xml</c>/<c>output.legacy.txt</c> and
/// <c>output.modern.xml</c>/<c>output.modern.txt</c> goldens.
/// </summary>
public sealed class SamplesTests
{
    private static string SamplesRoot => Path.Combine(AppContext.BaseDirectory, "samples");

    /// <summary>
    /// Discovers all samples: directories below <c>samples/</c> containing a
    /// <c>legacy.xsl</c>. Paths are relative to the samples root so test names
    /// read as <c>common</c>, <c>math</c>, …
    /// </summary>
    public static TheoryData<string> Samples
    {
        get
        {
            var samples = new TheoryData<string>();
            foreach (var directory in Directory.EnumerateDirectories(SamplesRoot))
            {
                if (File.Exists(Path.Combine(directory, "legacy.xsl")))
                {
                    samples.Add(Path.GetFileName(directory));
                }
            }

            return samples;
        }
    }

    /// <summary>
    /// Runs one sample: both the legacy (XSLT 1.0 idiom + EXSLT library) and the
    /// modern (idiomatic XSLT 3.0, no library) transform must match their captured
    /// outputs.
    /// </summary>
    [Theory]
    [MemberData(nameof(Samples))]
    public void Sample_outputs_match(string sample)
    {
        var sampleDirectory = Path.Combine(SamplesRoot, sample);
        var inputPath = Path.Combine(sampleDirectory, "input.xml");

        var legacyDifference = CompareWithGolden(sampleDirectory, "legacy", inputPath, out var legacyActual);
        Assert.True(legacyDifference is null,
            $"legacy output of sample '{sample}' no longer matches its captured golden:{Environment.NewLine}{legacyDifference ?? legacyActual}");
        var modernDifference = CompareWithGolden(sampleDirectory, "modern", inputPath, out var modernActual);
        Assert.True(modernDifference is null,
            $"modern output of sample '{sample}' no longer matches its captured golden:{Environment.NewLine}{modernDifference ?? modernActual}");
    }

    /// <summary>
    /// Runs <c>{variant}.xsl</c> and compares with <c>output.{variant}.xml</c> (or
    /// <c>.txt</c>). Returns null on match; otherwise the difference description,
    /// or the raw actual output when only the text fallback was compared.
    /// </summary>
    private static string? CompareWithGolden(string sampleDirectory, string variant, string inputPath, out string actual)
    {
        var transformPath = Path.Combine(sampleDirectory, $"{variant}.xsl");
        var xsl = File.ReadAllText(transformPath);
        var compiler = new XsltCompiler();
        // The base URI lets xsl:import href="../../src/exslt.xsl" in the legacy
        // stylesheets resolve from the copied location in the output directory.
        var executable = compiler.Compile(xsl, new Uri(transformPath).AbsoluteUri);

        var source = File.Exists(inputPath)
            ? new XDocumentNode(XDocument.Load(inputPath))
            : new XDocumentNode(new XDocument());
        actual = executable.TransformToString(source);

        var goldenXml = Path.Combine(sampleDirectory, $"output.{variant}.xml");
        if (File.Exists(goldenXml))
        {
            return TryCompareXml(File.ReadAllText(goldenXml), actual, out var difference) ? null : difference;
        }

        var goldenText = Path.Combine(sampleDirectory, $"output.{variant}.txt");
        var expected = File.ReadAllText(goldenText);
        return NormalizeText(expected) == NormalizeText(actual) ? null : $"text mismatch — expected:{Environment.NewLine}{expected}{Environment.NewLine}actual:{Environment.NewLine}{actual}";
    }

    /// <summary>
    /// Compares two XML documents semantically: both are parsed with insignificant
    /// whitespace discarded, then re-serialized without formatting.
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
    /// Reduces text output to its whitespace-separated token stream.
    /// </summary>
    private static string NormalizeText(string text) =>
        string.Join(" ", text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
}
