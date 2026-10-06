<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 06 October 2026
  PURPOSE        : EXSLT common module (http://exslt.org/common): exsl:node-set and
                   exsl:object-type for legacy XSLT 1.0 stylesheets running on XSLT 3.0.
  SPECIAL NOTES  : Tier 1 (wrapper): exsl:node-set is the identity in XSLT 3.0.
                   Tier 2 (genuine): exsl:object-type; XSLT 1.0 "RTF" reports as
                   "node-set" because XSLT 3.0 has no result-tree-fragment type.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:exsl="http://exslt.org/common"
                exclude-result-prefixes="xs"
                version="3.0">

  <!--
      Tier 1 — wrapper.

      Converts a result tree fragment to a node set. In XSLT 1.0 this was required
      before a variable holding constructed nodes could be processed with path
      expressions. In XSLT 3.0 every variable already holds an ordinary sequence, so
      this function is the identity. When migrating, delete the call and use the
      variable directly.
  -->
  <xsl:function name="exsl:node-set" as="item()*">
    <xsl:param name="object" as="item()*"/>
    <xsl:sequence select="$object"/>
  </xsl:function>

  <!--
      Tier 2 — genuine implementation.

      Returns the type of the supplied object as one of the strings "string",
      "number", "boolean", "node-set" or "external", per the EXSLT 1.0 spec.

      Documented divergence from libxslt: XSLT 1.0 result tree fragments were
      reported as "RTF"; XSLT 3.0 has no fragment type, so any node (including a
      stored result tree) reports as "node-set". Maps, arrays and function items —
      types unknown to XSLT 1.0 — report as "external".
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

  <!--
      Tier 3 — documented only.

      exsl:document is an extension *element* (multiple output documents), not a
      function. XSLT 2.0 and later provide xsl:result-document for this purpose;
      there is intentionally no function slot here.
  -->

</xsl:stylesheet>
