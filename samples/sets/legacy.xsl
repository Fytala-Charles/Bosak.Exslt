<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : REQ-005 sample (sets module) — the XSLT 1.0 idiom: distinct
                   values with set:distinct and set difference with
                   set:difference over node-sets.
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
                xmlns:set="http://exslt.org/sets"
                extension-element-prefixes="set"
                exclude-result-prefixes="set">

<xsl:import href="../../src/exslt.xsl"/>

<xsl:template match="/">
  <report>
    <all-cats>
      <xsl:for-each select="set:distinct(//book/@cat)">
        <cat><xsl:value-of select="."/></cat>
      </xsl:for-each>
    </all-cats>
    <desk-only>
      <xsl:for-each select="set:difference(//shelf[@name = 'desk']/book/@cat,
                                           //shelf[@name = 'bag']/book/@cat)">
        <cat><xsl:value-of select="."/></cat>
      </xsl:for-each>
    </desk-only>
  </report>
</xsl:template>

</xsl:stylesheet>
