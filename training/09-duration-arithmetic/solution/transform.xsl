<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Fytala (training reference solution)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 09 reference solution — the completed starter.
                   Compare with your own attempt BEFORE reading this file
                   (see training/09-duration-arithmetic/README.md section 7,
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

  <xsl:template match="workout">
    <report>
      <xsl:for-each select="convert">
        <convert name="{@name}">
          <duration><xsl:value-of select="date:duration(@seconds)"/></duration>
        </convert>
      </xsl:for-each>
      <xsl:for-each select="pair">
        <pair name="{@name}">
          <result><xsl:value-of select="date:add-duration(@d1, @d2)"/></result>
        </pair>
      </xsl:for-each>
      <xsl:for-each select="sum">
        <sum name="{@name}">
          <total><xsl:value-of select="date:sum(d)"/></total>
        </sum>
      </xsl:for-each>
    </report>
  </xsl:template>

  <!--
      Exercise 1 machinery: a seconds total (xs:decimal, never binary float)
      splits into whole days plus the in-day remainder, and the canonical
      EXSLT spelling keeps only the non-zero components. months arrive
      pre-normalized from the callers (exercise 1 has none).
  -->
  <xsl:function name="date:_split-seconds" as="map(*)">
    <xsl:param name="total" as="xs:decimal"/>
    <xsl:variable name="days" as="xs:integer" select="xs:integer(floor($total div 86400))"/>
    <xsl:sequence select="map { 'days': $days, 'seconds': $total - 86400 * $days }"/>
  </xsl:function>

  <xsl:function name="date:_format-duration" as="xs:string">
    <xsl:param name="neg" as="xs:boolean"/>
    <xsl:param name="months" as="xs:integer"/>
    <xsl:param name="days" as="xs:integer"/>
    <xsl:param name="seconds" as="xs:decimal"/>
    <xsl:variable name="years" as="xs:integer" select="$months idiv 12"/>
    <xsl:variable name="mo" as="xs:integer" select="$months mod 12"/>
    <xsl:variable name="h" as="xs:integer" select="xs:integer(floor($seconds div 3600))"/>
    <xsl:variable name="m" as="xs:integer" select="xs:integer(floor(($seconds - 3600 * $h) div 60))"/>
    <xsl:variable name="s" as="xs:decimal" select="$seconds - 3600 * $h - 60 * $m"/>
    <xsl:variable name="s-string" as="xs:string"
                  select="if ($s eq floor($s)) then string(xs:integer($s)) else string($s)"/>
    <xsl:variable name="date-part" as="xs:string"
      select="concat(if ($years ne 0) then string($years) || 'Y' else '',
                     if ($mo ne 0) then string($mo) || 'M' else '',
                     if ($days ne 0) then string($days) || 'D' else '')"/>
    <xsl:variable name="time-part" as="xs:string"
      select="concat(if ($h ne 0) then string($h) || 'H' else '',
                     if ($m ne 0) then string($m) || 'M' else '',
                     if ($s ne 0) then $s-string || 'S' else '')"/>
    <xsl:variable name="body" as="xs:string"
      select="if ($date-part eq '' and $time-part eq '') then 'P0D'
              else 'P' || $date-part || (if ($time-part ne '') then 'T' || $time-part else '')"/>
    <xsl:sequence select="(if ($neg) then '-' else '') || $body"/>
  </xsl:function>

  <!--
      Seconds to duration string, per EXSLT. Decimal-exact: xs:decimal
      arithmetic keeps fractional seconds intact, where a binary-float
      div/mod chain rounds (the split-hair row is the documented divergence —
      README section 4).
  -->
  <xsl:function name="date:duration" as="xs:string">
    <xsl:param name="seconds" as="xs:double"/>
    <xsl:variable name="total" as="xs:decimal" select="abs(xs:decimal($seconds))"/>
    <xsl:variable name="split" as="map(*)" select="date:_split-seconds($total)"/>
    <xsl:sequence select="date:_format-duration($seconds lt 0, 0, $split?days, $split?seconds)"/>
  </xsl:function>

  <!--
      Exercise 2 machinery: parse the ISO 8601 duration lexical form into a
      map { neg, months, days, seconds }. Hours and minutes fold into the
      decimal seconds total at parse time; years fold into months (x12).
      analyze-string's children must be select-valued on this engine
      (session 04, section 3); () means "not a duration".
  -->
  <xsl:function name="date:_parse-duration" as="map(*)?">
    <xsl:param name="value" as="xs:string"/>
    <xsl:variable name="v" as="xs:string" select="normalize-space($value)"/>
    <xsl:analyze-string select="$v"
                        regex="^(-)?P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(\d+(?:\.\d+)?S)?)?$">
      <xsl:matching-substring>
        <xsl:variable name="sec" as="xs:string" select="regex-group(7)"/>
        <xsl:sequence select="map {
            'neg': regex-group(1) eq '-',
            'months': sum(regex-group(2)[. ne ''] ! (xs:integer(.) * 12))
                      + sum(regex-group(3)[. ne ''] ! xs:integer(.)),
            'days': sum(regex-group(4)[. ne ''] ! xs:integer(.)),
            'seconds': sum(regex-group(5)[. ne ''] ! (xs:decimal(.) * 3600))
                       + sum(regex-group(6)[. ne ''] ! (xs:decimal(.) * 60))
                       + (if ($sec ne '') then xs:decimal(substring($sec, 1, string-length($sec) - 1)) else 0)
          }"/>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:sequence select="()"/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>

  <!--
      Add two durations with component normalization (the libxslt/EXSLT rule):
      signed component sums, months carry into years, seconds carry into days,
      and days deliberately never carry into months. '' when either operand
      is not a duration. Note: TWO durations — adding a duration to a date is
      date:add (calendar arithmetic), a different function entirely.
  -->
  <xsl:function name="date:add-duration" as="xs:string">
    <xsl:param name="duration1" as="xs:string?"/>
    <xsl:param name="duration2" as="xs:string?"/>
    <xsl:variable name="d1" as="map(*)?" select="date:_parse-duration($duration1)"/>
    <xsl:variable name="d2" as="map(*)?" select="date:_parse-duration($duration2)"/>
    <xsl:choose>
      <xsl:when test="empty($d1) or empty($d2)">
        <xsl:sequence select="''"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="months" as="xs:integer"
                      select="(if ($d1?neg) then -$d1?months else $d1?months)
                              + (if ($d2?neg) then -$d2?months else $d2?months)"/>
        <xsl:variable name="days" as="xs:integer"
                      select="(if ($d1?neg) then -$d1?days else $d1?days)
                              + (if ($d2?neg) then -$d2?days else $d2?days)"/>
        <xsl:variable name="seconds" as="xs:decimal"
                      select="(if ($d1?neg) then -$d1?seconds else $d1?seconds)
                              + (if ($d2?neg) then -$d2?seconds else $d2?seconds)"/>
        <xsl:variable name="neg" as="xs:boolean"
                      select="($months lt 0)
                              or ($months eq 0 and $days lt 0)
                              or ($months eq 0 and $days eq 0 and $seconds lt 0)"/>
        <xsl:variable name="split" as="map(*)" select="date:_split-seconds($seconds)"/>
        <xsl:sequence select="date:_format-duration($neg, abs($months), $days + $split?days, abs($split?seconds))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--
      Sum a node set of durations: parse every member, refuse ("NaN") when
      any member is unparseable, otherwise the same component arithmetic as
      add-duration. The empty node set sums to P0D.
  -->
  <xsl:function name="date:sum" as="xs:string">
    <xsl:param name="node-set" as="node()*"/>
    <xsl:variable name="durations" as="map(*)*"
                  select="$node-set ! date:_parse-duration(string(.))"/>
    <xsl:choose>
      <xsl:when test="count($durations) ne count($node-set)">
        <xsl:sequence select="'NaN'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="months" as="xs:integer" select="sum($durations ! (if (?neg) then -(?months) else ?months))"/>
        <xsl:variable name="days" as="xs:integer" select="sum($durations ! (if (?neg) then -(?days) else ?days))"/>
        <xsl:variable name="seconds" as="xs:decimal" select="sum($durations ! (if (?neg) then -(?seconds) else ?seconds))"/>
        <xsl:variable name="neg" as="xs:boolean"
                      select="($months lt 0)
                              or ($months eq 0 and $days lt 0)
                              or ($months eq 0 and $days eq 0 and $seconds lt 0)"/>
        <xsl:variable name="split" as="map(*)" select="date:_split-seconds($seconds)"/>
        <xsl:sequence select="date:_format-duration($neg, abs($months), $days + $split?days, abs($split?seconds))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
