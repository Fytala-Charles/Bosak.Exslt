<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Fytala (training reference solution)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 07 reference solution — the completed starter.
                   Compare with your own attempt BEFORE reading this file
                   (see training/07-result-trees-and-types/README.md section 7,
                   which also points at the library implementation in src/exsl.xsl).
  SPECIAL NOTES  : Self-contained: includes nothing from src/ (golden rule in
                   training/README.md).
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
    <xsl:variable name="totals">
      <totals>
        <xsl:for-each select="row">
          <product name="{@product}" total="{@qty * @price}"/>
        </xsl:for-each>
      </totals>
    </xsl:variable>
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
      In XSLT 3.0 every variable already holds an ordinary sequence, so the
      XSLT 1.0 result-tree-fragment conversion is the identity: return the
      argument unchanged and let the caller's path steps see exactly the tree
      that was built. When migrating legacy stylesheets, delete the call and
      use the variable directly.
  -->
  <xsl:function name="exsl:node-set" as="item()*">
    <xsl:param name="object" as="item()*"/>
    <xsl:sequence select="$object"/>
  </xsl:function>

  <!--
      Returns the type of the first item as one of "string", "number",
      "boolean", "node-set" or "external", per the EXSLT 1.0 spec. An empty
      sequence is the empty node set, hence "node-set". XSLT 1.0 result tree
      fragments reported as "RTF"; XSLT 3.0 has no fragment type, so a stored
      result tree reports as "node-set" (documented divergence — see
      docs/COMPATIBILITY.md). Maps, arrays and function items — unknown to
      XSLT 1.0 — report as "external".
  -->
  <xsl:function name="exsl:object-type" as="xs:string">
    <xsl:param name="object" as="item()*"/>
    <xsl:choose>
      <xsl:when test="empty($object)">node-set</xsl:when>
      <xsl:when test="$object[1] instance of node()">node-set</xsl:when>
      <xsl:when test="$object[1] instance of map(*)
                      or $object[1] instance of array(*)
                      or $object[1] instance of function(*)">external</xsl:when>
      <xsl:when test="$object[1] instance of xs:boolean">boolean</xsl:when>
      <xsl:when test="$object[1] instance of xs:string
                      or $object[1] instance of xs:anyURI
                      or $object[1] instance of xs:QName
                      or $object[1] instance of xs:untypedAtomic">string</xsl:when>
      <xsl:otherwise>number</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
