<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Fytala (training reference solution)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 01 reference solution — the completed starter.
                   Compare with your own attempt BEFORE reading this file
                   (see training/01-xslt-basics/README.md section 5).
  SPECIAL NOTES  : Self-contained: includes nothing from src/ (golden rule in
                   training/README.md).
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="3.0">

  <!--
      count="{...}" is an attribute value template: the XPath inside the braces
      is evaluated and substituted. The for-each body is kept on one line inside
      <roster> so no whitespace-only text nodes leak into the result.
  -->
  <xsl:template match="team">
    <roster count="{count(member)}"><xsl:for-each select="member"><name><xsl:value-of select="."/></name></xsl:for-each></roster>
  </xsl:template>

</xsl:stylesheet>
