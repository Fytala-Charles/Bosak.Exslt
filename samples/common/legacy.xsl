<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : REQ-005 sample (common module) — the XSLT 1.0 idiom: collect
                   nodes into a result tree fragment variable, then re-open it
                   with exsl:node-set.
  SPECIAL NOTES  : Legacy-migration showcase. Written the way a migrating
                   consumer would write it: xsl:import of the library master and
                   version="1.0". Output captured by running this transform
                   through the Bosak engine (see samples/README.md).
  CHANGE HISTORY : 2026-10-08 | 1.0 | REQ-005 creation.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="exsl"
                exclude-result-prefixes="exsl">

<xsl:import href="../../src/exslt.xsl"/>

<!-- In XSLT 1.0 a variable built from instructions is a result tree
     fragment: opaque, only string-value readable, cannot be navigated. -->
<xsl:variable name="backorders-rtf">
  <backorder>
    <xsl:for-each select="//item[@status = 'backorder']">
      <item name="{@name}"/>
    </xsl:for-each>
  </backorder>
</xsl:variable>

<xsl:template match="/">
  <report>
    <type><xsl:value-of select="exsl:object-type($backorders-rtf)"/></type>
    <count><xsl:value-of select="count(exsl:node-set($backorders-rtf)/backorder/item)"/></count>
    <items>
      <xsl:copy-of select="exsl:node-set($backorders-rtf)/backorder/item"/>
    </items>
  </report>
</xsl:template>

</xsl:stylesheet>
