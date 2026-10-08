<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Training session 09 (starter — replace with your name)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 09 exercise — date:duration (exercise 1),
                   date:add-duration (exercise 2) and date:sum (exercise 3).
                   Self-contained: includes nothing from src/ (see the golden
                   rule in training/README.md).
  SPECIAL NOTES  : The starter compiles and runs but its output does not match
                   case/expected.xml — the training test Starter_differs_from_golden
                   must pass.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:date="http://exslt.org/dates-and-times"
                exclude-result-prefixes="xs date"
                version="3.0">

  <xsl:template match="workout">
    <report>
      <xsl:for-each select="convert">
        <convert name="{@name}">
          <duration><xsl:value-of select="date:duration(@seconds)"/></duration>
        </convert>
      </xsl:for-each>
      <xsl:for-each select="pair">
        <pair name="{@name}">
          <result><xsl:value-of select="date:add-duration(@d1, @d2)"/></result>
        </pair>
      </xsl:for-each>
      <xsl:for-each select="sum">
        <sum name="{@name}">
          <total><xsl:value-of select="date:sum(d)"/></total>
        </sum>
      </xsl:for-each>
    </report>
  </xsl:template>

  <!--
      EXERCISE 1 (see README section 4): NAIVE — a binary-float div/mod chain,
      and every component is emitted whether or not it is zero. Small
      xs:double rounding errors leak into the output (watch the split-hair
      row), and "P0D" has no special case.
  -->
  <xsl:function name="date:duration" as="xs:string">
    <xsl:param name="seconds" as="xs:double"/>
    <xsl:variable name="total" select="abs($seconds)"/>
    <xsl:variable name="d" select="floor($total div 86400)"/>
    <xsl:variable name="h" select="floor(($total mod 86400) div 3600)"/>
    <xsl:variable name="m" select="floor(($total mod 3600) div 60)"/>
    <xsl:variable name="s" select="$total mod 60"/>
    <xsl:sequence select="(if ($seconds lt 0) then '-' else '') || 'P'
                          || $d || 'DT' || $h || 'H' || $m || 'M' || $s || 'S'"/>
  </xsl:function>

  <!--
      EXERCISE 2 (see README section 5): NAIVE — the native route: cast both
      operands to xs:duration, add, stringify. XPath 3.1's operator table only
      admits the restricted xs:dayTimeDuration/xs:yearMonthDuration types in
      date/time arithmetic, so on this engine the + raises XPTY0004 — and the
      try/catch politely converts the error to '' for every row. Delete the
      try/catch to read the engine's exact complaint.
  -->
  <xsl:function name="date:add-duration" as="xs:string">
    <xsl:param name="duration1" as="xs:string?"/>
    <xsl:param name="duration2" as="xs:string?"/>
    <xsl:sequence select="try { string(xs:duration($duration1) + xs:duration($duration2)) }
                          catch * { '' }"/>
  </xsl:function>

  <!--
      EXERCISE 3 (see README section 6): NAIVE — flatten every member to
      day-time seconds via the native constructor and total those. It works
      for pure day-time sets (watch the zero-component noise on shift), but
      the moment a member carries a month — or a minus sign — the constructor
      raises and the try/catch flattens the whole row to "NaN".
  -->
  <xsl:function name="date:sum" as="xs:string">
    <xsl:param name="node-set" as="node()*"/>
    <xsl:sequence select="try {
                            date:duration(sum($node-set !
                              (xs:dayTimeDuration(string(.)) div xs:dayTimeDuration('PT1S'))))
                          }
                          catch * { 'NaN' }"/>
  </xsl:function>

</xsl:stylesheet>
