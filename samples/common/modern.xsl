<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : REQ-005 sample (common module) — the same task in idiomatic
                   XSLT 3.0: no result tree fragment, no exsl:node-set; the
                   selection is just a node sequence.
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

<!-- In XSLT 3.0 there is nothing to "re-open": a variable can hold any
     sequence, and a selection is navigated directly. -->
<xsl:template match="/">
  <report>
    <count><xsl:value-of select="count(//item[@status = 'backorder'])"/></count>
    <items>
      <xsl:sequence select="//item[@status = 'backorder']"/>
    </items>
  </report>
</xsl:template>

</xsl:stylesheet>
