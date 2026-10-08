<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : REQ-005 sample (date module) — the XSLT 1.0 idiom: summing
                   ISO 8601 task durations with date:sum and extracting the
                   calendar date with date:date.
  SPECIAL NOTES  : Legacy-migration showcase. xsl:import of the library master.
                   Written in XSLT 1.0 idiom, but version="3.0": on Bosak
                   0.12.3-beta a version="1.0" caller evaluates the library's
                   typed internals under 1.0 double arithmetic and every
                   date:* function fails with XTTE0570 (xs:integer
                   conversion) — so the legacy idiom is shown with a 3.0
                   version declaration. Output captured by running this
                   transform through the Bosak engine (see samples/README.md).
  CHANGE HISTORY : 2026-10-08 | 1.0 | REQ-005 creation.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:date="http://exslt.org/dates-and-times"
                extension-element-prefixes="date"
                exclude-result-prefixes="date">

<xsl:import href="../../src/exslt.xsl"/>

<xsl:template match="/schedule">
  <plan start="{@start}">
    <date><xsl:value-of select="date:date(@start)"/></date>
    <total><xsl:value-of select="date:sum(task/@duration)"/></total>
  </plan>
</xsl:template>

</xsl:stylesheet>
