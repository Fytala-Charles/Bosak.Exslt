<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : REQ-005 sample (strings module) — the XSLT 1.0 idiom:
                   splitting a comma-separated field with str:tokenize and a
                   literal character replacement with str:replace.
  SPECIAL NOTES  : Legacy-migration showcase. xsl:import of the library master,
                   version="1.0". Output captured by running this transform
                   through the Bosak engine (see samples/README.md).
  CHANGE HISTORY : 2026-10-08 | 1.0 | REQ-005 creation.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="str"
                exclude-result-prefixes="str">

<xsl:import href="../../src/exslt.xsl"/>

<xsl:template match="product">
  <product sku="{str:replace(@sku, '-', '_')}">
    <xsl:for-each select="str:tokenize(@tags, ',')">
      <tag><xsl:value-of select="."/></tag>
    </xsl:for-each>
  </product>
</xsl:template>

</xsl:stylesheet>
