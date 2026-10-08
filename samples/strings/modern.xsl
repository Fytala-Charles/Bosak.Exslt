<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : REQ-005 sample (strings module) — the same task in idiomatic
                   XSLT 3.0: fn:tokenize and fn:replace are native.
  SPECIAL NOTES  : Modern-migration counterpart of legacy.xsl. Output captured
                   by running this transform through the Bosak engine
                   (see samples/README.md).
  CHANGE HISTORY : 2026-10-08 | 1.0 | REQ-005 creation.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="product">
  <product sku="{replace(@sku, '-', '_')}">
    <xsl:for-each select="tokenize(@tags, ',')">
      <tag><xsl:value-of select="."/></tag>
    </xsl:for-each>
  </product>
</xsl:template>

</xsl:stylesheet>
