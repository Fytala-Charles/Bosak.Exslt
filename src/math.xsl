<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 06 October 2026
  PURPOSE        : EXSLT math module (http://exslt.org/math): min, max, highest,
                   lowest, sqrt, power, constant, log and trigonometric functions.
  SPECIAL NOTES  : Entirely tier 1: every function is a thin wrapper over the XPath
                   3.1 math function library (namespace
                   http://www.w3.org/2005/xpath-functions/math, bound here to the
                   "xmath" prefix). Documented divergences from libxslt: power() for
                   negative bases and power(0, 0).
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:math="http://exslt.org/math"
                xmlns:xmath="http://www.w3.org/2005/xpath-functions/math"
                exclude-result-prefixes="xs xmath"
                version="3.0">

  <!-- Tier 1 — wrapper. Returns the minimum value of the nodes, converted to numbers. -->
  <xsl:function name="math:min" as="xs:double">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="if (empty($nodes)) then xs:double('NaN') else min($nodes ! number(.))"/>
  </xsl:function>

  <!-- Tier 1 — wrapper. Returns the maximum value of the nodes, converted to numbers. -->
  <xsl:function name="math:max" as="xs:double">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="if (empty($nodes)) then xs:double('NaN') else max($nodes ! number(.))"/>
  </xsl:function>

  <!--
      Tier 1 — wrapper.
      Returns the nodes whose numeric value equals the maximum — the XPath 3.1 form is
      $nodes[number(.) eq max($nodes ! number(.))].
  -->
  <xsl:function name="math:highest" as="node()*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:variable name="max" as="xs:double"
                  select="if (empty($nodes)) then xs:double('NaN') else max($nodes ! number(.))"/>
    <xsl:sequence select="$nodes[number(.) eq $max]"/>
  </xsl:function>

  <!-- Tier 1 — wrapper. Nodes whose numeric value equals the minimum. -->
  <xsl:function name="math:lowest" as="node()*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:variable name="min" as="xs:double"
                  select="if (empty($nodes)) then xs:double('NaN') else min($nodes ! number(.))"/>
    <xsl:sequence select="$nodes[number(.) eq $min]"/>
  </xsl:function>

  <!-- Tier 1 — wrapper over XPath 3.1 math:sqrt. -->
  <xsl:function name="math:sqrt" as="xs:double">
    <xsl:param name="number" as="xs:double"/>
    <xsl:sequence select="xmath:sqrt($number)"/>
  </xsl:function>

  <!--
      Tier 1 — wrapper.
      No native power function exists in XPath 3.1, so this is exp($e * log($b)).

      Documented divergences from libxslt (which delegates to C pow()):
      - negative base with non-integer exponent returns NaN here (log of a negative
        number is undefined), where libxslt may return a real number via pow();
      - power(0, 0) returns NaN here (0 * log(0) = 0 * -INF), where libxslt
        returns 1.
  -->
  <xsl:function name="math:power" as="xs:double">
    <xsl:param name="base" as="xs:double"/>
    <xsl:param name="power" as="xs:double"/>
    <xsl:sequence select="xmath:exp($power * xmath:log($base))"/>
  </xsl:function>

  <!--
      Tier 1 — wrapper.
      Returns a named mathematical constant rounded to the given number of significant
      digits. Recognized names: PI, E, SQRRT2 (the EXSLT-spec spelling), SQRT1_2,
      LN2, LN10, LOG2E. Unknown names return NaN.
  -->
  <xsl:function name="math:constant" as="xs:double">
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="precision" as="xs:integer"/>
    <xsl:variable name="value" as="xs:double?">
      <xsl:choose>
        <xsl:when test="$name eq 'PI'"><xsl:sequence select="xmath:pi()"/></xsl:when>
        <xsl:when test="$name eq 'E'"><xsl:sequence select="xmath:exp(1)"/></xsl:when>
        <xsl:when test="$name eq 'SQRRT2'"><xsl:sequence select="xmath:sqrt(2)"/></xsl:when>
        <xsl:when test="$name eq 'SQRT1_2'"><xsl:sequence select="xmath:sqrt(0.5)"/></xsl:when>
        <xsl:when test="$name eq 'LN2'"><xsl:sequence select="xmath:log(2)"/></xsl:when>
        <xsl:when test="$name eq 'LN10'"><xsl:sequence select="xmath:log(10)"/></xsl:when>
        <xsl:when test="$name eq 'LOG2E'"><xsl:sequence select="1 div xmath:log(2)"/></xsl:when>
        <xsl:otherwise><xsl:sequence select="()"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="if (empty($value)) then xs:double('NaN')
                          else if ($precision ge 1 and $value ne 0) then
                            round($value, xs:integer($precision - 1 - floor(xmath:log10(abs($value)))))
                          else $value"/>
  </xsl:function>

  <!-- Tier 1 — wrapper over XPath 3.1 math:log (natural logarithm). -->
  <xsl:function name="math:log" as="xs:double">
    <xsl:param name="number" as="xs:double"/>
    <xsl:sequence select="xmath:log($number)"/>
  </xsl:function>

  <!-- Tier 1 — wrappers over the XPath 3.1 trigonometric library. -->
  <xsl:function name="math:sin" as="xs:double">
    <xsl:param name="number" as="xs:double"/>
    <xsl:sequence select="xmath:sin($number)"/>
  </xsl:function>

  <xsl:function name="math:cos" as="xs:double">
    <xsl:param name="number" as="xs:double"/>
    <xsl:sequence select="xmath:cos($number)"/>
  </xsl:function>

  <xsl:function name="math:tan" as="xs:double">
    <xsl:param name="number" as="xs:double"/>
    <xsl:sequence select="xmath:tan($number)"/>
  </xsl:function>

  <xsl:function name="math:asin" as="xs:double">
    <xsl:param name="number" as="xs:double"/>
    <xsl:sequence select="xmath:asin($number)"/>
  </xsl:function>

  <xsl:function name="math:acos" as="xs:double">
    <xsl:param name="number" as="xs:double"/>
    <xsl:sequence select="xmath:acos($number)"/>
  </xsl:function>

  <xsl:function name="math:atan" as="xs:double">
    <xsl:param name="number" as="xs:double"/>
    <xsl:sequence select="xmath:atan($number)"/>
  </xsl:function>

  <xsl:function name="math:atan2" as="xs:double">
    <xsl:param name="y" as="xs:double"/>
    <xsl:param name="x" as="xs:double"/>
    <xsl:sequence select="xmath:atan2($y, $x)"/>
  </xsl:function>

  <xsl:function name="math:exp" as="xs:double">
    <xsl:param name="number" as="xs:double"/>
    <xsl:sequence select="xmath:exp($number)"/>
  </xsl:function>

</xsl:stylesheet>
