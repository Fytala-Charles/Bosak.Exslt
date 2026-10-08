<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Training session 02 (starter — replace with your name)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 02 exercise — math:min and math:max are given;
                   implement math:highest yourself. Self-contained: includes nothing
                   from src/ (see the golden rule in training/README.md).
  SPECIAL NOTES  : The starter compiles and runs but its output does not match
                   case/expected.xml — the training test Starter_differs_from_golden must pass.
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

  <!--
      Given for the exercise — study, do not change.
      EXSLT contract: the minimum of an EMPTY node set is NaN, never an error.
      `!` is the map operator: apply number(.) to every node, feed the
      number sequence straight into min().
  -->
  <xsl:function name="math:min" as="xs:double">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="if (empty($nodes)) then xs:double('NaN')
                          else min($nodes ! number(.))"/>
  </xsl:function>

  <!-- Given for the exercise — the same function with max(). -->
  <xsl:function name="math:max" as="xs:double">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="if (empty($nodes)) then xs:double('NaN')
                          else max($nodes ! number(.))"/>
  </xsl:function>

  <!--
      EXERCISE: return the nodes whose numeric value equals the maximum
      (EXSLT math:highest — all winners, in document order). On empty input
      return the empty sequence. Replace the stub below; see README hints.
  -->
  <xsl:function name="math:highest" as="node()*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="()"/>
  </xsl:function>

</xsl:stylesheet>
