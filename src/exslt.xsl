<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 06 October 2026
  PURPOSE        : Master module of the Bosak.Exslt library: includes every EXSLT
                   namespace module so a stylesheet can pull in the whole library
                   with one xsl:import or xsl:include.
  SPECIAL NOTES  : Includes exsl, math, strings, dates-and-times, sets and dynamic.
                   The func namespace (http://exslt.org/functions) has no module:
                   func:function is superseded by xsl:function — see
                   docs/COMPATIBILITY.md.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="3.0">

  <xsl:include href="exsl.xsl"/>
  <xsl:include href="math.xsl"/>
  <xsl:include href="strings.xsl"/>
  <xsl:include href="dates-and-times.xsl"/>
  <xsl:include href="sets.xsl"/>
  <xsl:include href="dynamic.xsl"/>

</xsl:stylesheet>
