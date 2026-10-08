<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : REQ-005 sample (math module) — the same task in idiomatic
                   XSLT 3.0: fn:max over a sequence, arg-max by direct
                   comparison, no EXSLT.
  SPECIAL NOTES  : Modern-migration counterpart of legacy.xsl. Untyped
                   attribute values are converted explicitly with number().
                   Output captured by running this transform through the Bosak
                   engine (see samples/README.md).
  CHANGE HISTORY : 2026-10-08 | 1.0 | REQ-005 creation.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/orders">
  <xsl:variable name="top-price" select="max(order/@price/number())"/>
  <summary>
    <max><xsl:value-of select="$top-price"/></max>
    <top><xsl:value-of select="order[number(@price) eq $top-price]/@id"/></top>
  </summary>
</xsl:template>

</xsl:stylesheet>
