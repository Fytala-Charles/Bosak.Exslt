<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : REQ-005 sample (dynamic module) — the XSLT 1.0 idiom:
                   evaluating a computed expression per line with
                   dyn:evaluate.
  SPECIAL NOTES  : Legacy-migration showcase AND tier-3 wall. dyn:evaluate is
                   not implementable in pure XSLT 3.0 (see
                   docs/COMPATIBILITY.md); on Bosak 0.12.3-beta the slot's
                   xsl:message terminate="yes" does NOT abort the transform —
                   the message is reported, the call returns the empty
                   sequence, and processing continues. The captured output
                   therefore has empty <line> elements; the message text is
                   documented in samples/README.md. The migration path
                   (xsl:evaluate once the engine's context-item gap is fixed,
                   per REQ-004 / ADR-001) is deliberately not used.
  CHANGE HISTORY : 2026-10-08 | 1.0 | REQ-005 creation.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="dyn"
                exclude-result-prefixes="dyn">

<xsl:import href="../../src/exslt.xsl"/>

<xsl:template match="/order">
  <totalled>
    <xsl:for-each select="line">
      <line qty="{@qty}" price="{@price}">
        <xsl:value-of select="dyn:evaluate('@qty * @price')"/>
      </line>
    </xsl:for-each>
  </totalled>
</xsl:template>

</xsl:stylesheet>
