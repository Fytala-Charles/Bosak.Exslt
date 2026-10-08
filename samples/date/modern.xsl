<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : REQ-005 sample (date module) — the same task in idiomatic
                   XSLT 3.0: the start date formatted natively with
                   fn:format-dateTime, durations totalled through a small
                   sample-local parsing function.
  SPECIAL NOTES  : Modern-migration counterpart of legacy.xsl. Bosak
                   0.12.3-beta rejects xs:duration arithmetic and
                   seconds-from-duration returns 0, so the modern version
                   parses the fixed PTnHnMnS shape itself — which is exactly
                   the kind of code date:sum replaces. Output captured by
                   running this transform through the Bosak engine
                   (see samples/README.md).
  CHANGE HISTORY : 2026-10-08 | 1.0 | REQ-005 creation.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:local="urn:sample:date"
                exclude-result-prefixes="xs local">

<!-- Parses the fixed PTnHnMnS shapes used by input.xml into seconds. -->
<xsl:function name="local:duration-seconds" as="xs:decimal">
  <xsl:param name="duration" as="xs:string"/>
  <xsl:variable name="time" select="substring-after($duration, 'PT')"/>
  <xsl:sequence select="
      (if (contains($time, 'H'))
       then xs:decimal(substring-before($time, 'H')) * 3600 else 0)
    + (if (contains($time, 'M'))
       then xs:decimal(substring-before(substring-after($time, 'H'), 'M')) * 60 else 0)
    + (if (contains($time, 'S'))
       then xs:decimal(substring-before(substring-after($time, 'M'), 'S')) else 0)"/>
</xsl:function>

<xsl:template match="/schedule">
  <xsl:variable name="total-seconds"
                select="sum(task/@duration ! local:duration-seconds(string(.)))"/>
  <plan start="{@start}">
    <date><xsl:value-of select="format-dateTime(xs:dateTime(@start), '[D1] [MNn] [Y]')"/></date>
    <total-seconds><xsl:value-of select="$total-seconds"/></total-seconds>
    <total>
      <xsl:value-of select="$total-seconds idiv 3600"/>
      <xsl:text>h</xsl:text>
      <xsl:value-of select="($total-seconds idiv 60) mod 60"/>
      <xsl:text>m</xsl:text>
    </total>
  </plan>
</xsl:template>

</xsl:stylesheet>
