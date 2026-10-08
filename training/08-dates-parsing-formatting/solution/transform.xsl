<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Fytala (training reference solution)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 08 reference solution — the completed starter.
                   Compare with your own attempt BEFORE reading this file
                   (see training/08-dates-parsing-formatting/README.md section 7,
                   which also points at the library implementation in
                   src/dates-and-times.xsl).
  SPECIAL NOTES  : Self-contained: includes nothing from src/ (golden rule in
                   training/README.md).
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:date="http://exslt.org/dates-and-times"
                exclude-result-prefixes="xs date"
                version="3.0">

  <xsl:template match="events">
    <report>
      <xsl:for-each select="event">
        <event name="{@name}">
          <year><xsl:value-of select="date:year(@date)"/></year>
          <leap><xsl:value-of select="date:leap-year(@date)"/></leap>
          <month><xsl:value-of select="date:month-name(@date)"/></month>
        </event>
      </xsl:for-each>
    </report>
  </xsl:template>

  <!--
      EXSLT dates accept the whole ISO 8601 profile — dateTime, date,
      gYearMonth, gYear, gMonthDay, gMonth, gDay, or time — so parsing is a
      ladder of "castable as" probes, padding partial values with defaults.
      Anything else raises date:INVALID, which the callers catch. Exercise 1
      of this session builds this helper; exercises 2 and 3 build on it.
  -->
  <xsl:function name="date:_as-datetime" as="xs:dateTime">
    <xsl:param name="value" as="xs:string"/>
    <xsl:variable name="v" as="xs:string" select="normalize-space($value)"/>
    <xsl:choose>
      <xsl:when test="$v castable as xs:dateTime">
        <xsl:sequence select="xs:dateTime($v)"/>
      </xsl:when>
      <xsl:when test="$v castable as xs:date">
        <xsl:sequence select="xs:dateTime(xs:date($v))"/>
      </xsl:when>
      <xsl:when test="$v castable as xs:gYearMonth">
        <xsl:sequence select="xs:dateTime(xs:date($v || '-01'))"/>
      </xsl:when>
      <xsl:when test="$v castable as xs:gYear">
        <xsl:sequence select="xs:dateTime(xs:date($v || '-01-01'))"/>
      </xsl:when>
      <xsl:when test="$v castable as xs:gMonthDay">
        <xsl:sequence select="xs:dateTime(xs:date('1972-' || $v))"/>
      </xsl:when>
      <xsl:when test="$v castable as xs:gMonth">
        <xsl:sequence select="xs:dateTime(xs:date('1972-' || $v || '-01'))"/>
      </xsl:when>
      <xsl:when test="$v castable as xs:gDay">
        <xsl:sequence select="xs:dateTime(xs:date('1972-12' || $v))"/>
      </xsl:when>
      <xsl:when test="$v castable as xs:time">
        <xsl:sequence select="xs:dateTime(xs:date('1972-01-01'), xs:time($v))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="error(xs:QName('date:INVALID'), 'Invalid ISO 8601 value: ' || $v)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Year as a number; NaN on invalid input, per EXSLT. -->
  <xsl:function name="date:year" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try { xs:double(year-from-dateTime(date:_as-datetime($date-time))) }
                                catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!--
      Gregorian leap-year rule: divisible by 4, except centuries unless
      divisible by 400. 1900 fails the century clause; 2000 passes the
      400-year clause. false() on invalid input.
  -->
  <xsl:function name="date:leap-year" as="xs:boolean">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then false()
                          else (try {
                                  let $y := year-from-dateTime(date:_as-datetime($date-time))
                                  return (($y mod 4) eq 0 and ($y mod 100) ne 0) or ($y mod 400) eq 0
                                } catch * { false() })"/>
  </xsl:function>

  <!--
      English month name; '' on invalid input. The repaired REQ-008 spelling:
      format-date's first parameter is typed xs:date?, while date:_as-datetime
      returns xs:dateTime — the library once shipped that mismatch and the
      try/catch masked the resulting XPTY0004, silently returning '' for
      every input (see README section 6). The one-line repair extracts the
      date portion before formatting.

      Library update (2026-10-06, REQ-001 batch 3): the rewritten library
      rejects a bare gYear here — the EXSLT spec permits month-name only
      dateTime, date, gYearMonth, gMonthDay and gMonth, and modern libxslt
      returns '' for a gYear (documented divergence #3 in
      docs/COMPATIBILITY.md). The guard below mirrors that contract; the
      year extractors above still accept gYear.
  -->
  <xsl:function name="date:month-name" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then ''
                          else if (normalize-space($date-time) castable as xs:gYear) then ''
                          else (try {
                                  format-date(xs:date(substring(string(date:_as-datetime($date-time)), 1, 10)), '[MNn]')
                                } catch * { '' })"/>
  </xsl:function>

</xsl:stylesheet>
