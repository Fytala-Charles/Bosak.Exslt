<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : REQ-005 sample (dynamic module) — the migration target for
                   dyn:evaluate: the expression was static all along, so the
                   modern version computes it directly.
  SPECIAL NOTES  : Static-dispatch migration pattern (cf. training session 10):
                   most real dyn:evaluate call sites evaluate an expression the
                   stylesheet could have written literally. xsl:evaluate is not
                   used: Bosak 0.12.3-beta has a context-item gap there (see
                   REQ-004 / docs/FEATURE_REQUESTS.md). Untyped attribute
                   values are converted explicitly with number(). Output
                   captured by running this transform through the Bosak engine
                   (see samples/README.md).
  CHANGE HISTORY : 2026-10-08 | 1.0 | REQ-005 creation.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/order">
  <totalled>
    <xsl:for-each select="line">
      <line qty="{@qty}" price="{@price}">
        <xsl:value-of select="number(@qty) * number(@price)"/>
      </line>
    </xsl:for-each>
  </totalled>
</xsl:template>

</xsl:stylesheet>
