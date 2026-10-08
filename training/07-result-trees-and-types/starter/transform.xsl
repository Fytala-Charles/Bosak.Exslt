<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Training session 07 (starter — replace with your name)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 07 exercise — exsl:node-set (exercise 1) and
                   exsl:object-type (exercise 2). Self-contained: includes nothing
                   from src/ (see the golden rule in training/README.md).
  SPECIAL NOTES  : The starter compiles and runs but its output does not match
                   case/expected.xml — the training test Starter_differs_from_golden must pass.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:exsl="http://exslt.org/common"
                exclude-result-prefixes="xs exsl"
                version="3.0">

  <xsl:template match="sales">
    <!--
        GIVEN — study, do not change. A variable whose content is constructed
        instructions (not a select attribute) holds a DOCUMENT NODE: the root
        of a little tree whose child is the <totals> element. See README §3.
    -->
    <xsl:variable name="totals">
      <totals>
        <xsl:for-each select="row">
          <product name="{@product}" total="{@qty * @price}"/>
        </xsl:for-each>
      </totals>
    </xsl:variable>
    <!-- The XSLT 1.0 spelling of "let me path-step that": exsl:node-set. -->
    <xsl:variable name="report" select="exsl:node-set($totals)"/>
    <result>
      <best><xsl:value-of select="$report/totals/product[@total = max($report/totals/product/@total)]/@name"/></best>
      <grand><xsl:value-of select="sum($report/totals/product/@total)"/></grand>
      <of-rtf><xsl:value-of select="exsl:object-type($totals)"/></of-rtf>
      <of-string><xsl:value-of select="exsl:object-type('hello')"/></of-string>
      <of-number><xsl:value-of select="exsl:object-type(42)"/></of-number>
      <of-boolean><xsl:value-of select="exsl:object-type(true())"/></of-boolean>
      <of-nodes><xsl:value-of select="exsl:object-type(row)"/></of-nodes>
      <of-empty><xsl:value-of select="exsl:object-type(())"/></of-empty>
      <of-map><xsl:value-of select="exsl:object-type(map { 'a': 1 })"/></of-map>
    </result>
  </xsl:template>

  <!--
      EXERCISE 1 (see README section 4): NAIVE — "node set" sounds like the
      ELEMENTS inside the tree, so this strips the document node and returns
      its children. The path steps in the template ($report/totals/product)
      then start from the wrong node and find nothing. In XSLT 3.0 the honest
      implementation does nothing at all.
  -->
  <xsl:function name="exsl:node-set" as="item()*">
    <xsl:param name="object" as="item()*"/>
    <xsl:sequence select="$object/child::node()"/>
  </xsl:function>

  <!--
      EXERCISE 2 (see README section 5): NAIVE — sniffs the STRING VALUE of
      the first item and guesses. Blind to booleans (true() reads as the
      string "true"), reports maps and nodes as "node-set", and trusts any
      numeric-looking spelling. Replace with real type inspection.
  -->
  <xsl:function name="exsl:object-type" as="xs:string">
    <xsl:param name="object" as="item()*"/>
    <xsl:sequence select="if (empty($object)) then 'node-set'
                          else if (not($object[1] instance of xs:anyAtomicType)) then 'node-set'
                          else if (string($object[1]) castable as xs:double) then 'number'
                          else 'string'"/>
  </xsl:function>

</xsl:stylesheet>
