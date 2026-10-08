<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Fytala (training reference solution)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 02 reference solution — the completed starter.
                   Compare with your own attempt BEFORE reading this file
                   (see training/02-first-stylesheet/README.md section 6, which also
                   points at the library implementation in src/math.xsl).
  SPECIAL NOTES  : Self-contained: includes nothing from src/ (golden rule in
                   training/README.md).
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:math="http://exslt.org/math"
                exclude-result-prefixes="xs math"
                version="3.0">

  <xsl:template match="values">
    <result>
      <minimum><xsl:value-of select="math:min(value)"/></minimum>
      <maximum><xsl:value-of select="math:max(value)"/></maximum>
      <highest><xsl:value-of select="math:highest(value)" separator=" "/></highest>
    </result>
  </xsl:template>

  <xsl:function name="math:min" as="xs:double">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="if (empty($nodes)) then xs:double('NaN')
                          else min($nodes ! number(.))"/>
  </xsl:function>

  <xsl:function name="math:max" as="xs:double">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="if (empty($nodes)) then xs:double('NaN')
                          else max($nodes ! number(.))"/>
  </xsl:function>

  <!--
      All nodes whose numeric value equals the maximum. The empty-input guard
      documents intent even though the predicate alone would survive it
      (max(()) is the empty sequence, and nothing compares equal to it).
  -->
  <xsl:function name="math:highest" as="node()*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:variable name="max" as="xs:double"
                  select="if (empty($nodes)) then xs:double('NaN') else max($nodes ! number(.))"/>
    <xsl:sequence select="$nodes[number(.) eq $max]"/>
  </xsl:function>

</xsl:stylesheet>
