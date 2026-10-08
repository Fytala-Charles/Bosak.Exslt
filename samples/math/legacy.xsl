<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : REQ-005 sample (math module) — the XSLT 1.0 idiom: maximum
                   and arg-max over a node-set with math:max / math:highest.
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
                xmlns:math="http://exslt.org/math"
                extension-element-prefixes="math"
                exclude-result-prefixes="math">

<xsl:import href="../../src/exslt.xsl"/>

<xsl:template match="/orders">
  <summary>
    <max><xsl:value-of select="math:max(order/@price)"/></max>
    <top>
      <xsl:for-each select="math:highest(order/@price)">
        <xsl:value-of select="../@id"/>
      </xsl:for-each>
    </top>
  </summary>
</xsl:template>

</xsl:stylesheet>
