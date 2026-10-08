<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 06 October 2026
  PURPOSE        : EXSLT dates-and-times module (http://exslt.org/dates-and-times):
                   component extraction, formatting, duration arithmetic and
                   summation over ISO 8601 dates and times.
  SPECIAL NOTES  : Entirely tier 2. Faithful port of the libexslt date.c reference
                   algorithms: parsing follows the libxslt grammar (rejects leap
                   seconds, lowercase designators), calendar math replicates C
                   integer division/modulo, numbers reproduce the libxml2 number
                   formatter. Invalid input yields NaN/'' per EXSLT; divergences
                   in docs/COMPATIBILITY.md.
  CHANGE HISTORY : 2026-10-06 | 1.0 -> 1.1 | REQ-008: xs:date cast in the
                   format-date family repaired a silent XPTY0004 (''/NaN).
                   2026-10-06 | 1.1 -> 1.2 | REQ-001 batch 3: fn:dateTime#2
                   replaces xs:dateTime#2; date:difference FLWOR collapsed to
                   one let (Bosak limit); date:duration guards NaN/overflow.
                   2026-10-06 | 1.2 -> 1.3 | REQ-001 batch 3: full rewrite on the
                   libexslt date.c algorithms. Extraction functions enforce the
                   EXSLT type contracts and return xs:string with XPath 1.0 number
                   formatting; week-in-year, day-in-week, day-in-year replicate the
                   libxslt calendar formulas; add, difference, add-duration, sum,
                   seconds replicate the _exsltDateAdd / _exsltDateDifference /
                   _exsltDateAddDurCalc component arithmetic; numbers print via
                   date:_format-number (xmlXPathFormatNumber port).
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:date="http://exslt.org/dates-and-times"
                exclude-result-prefixes="xs"
                version="3.0">

  <!-- ======================================================================
       Private helpers: calendar formulas (ports of the libexslt date.c
       convenience macros; XPath mod/idiv truncate toward zero like C)
       ====================================================================== -->

  <!--
      Port of the libxslt IS_LEAP macro: ((y & 3) == 0) && ((y % 25 != 0) ||
      ((y & 15) == 0)). $year is the internal (astronomical, no-year-zero)
      year number, exactly as libxslt stores it.
  -->
  <xsl:function name="date:_is-leap" as="xs:boolean">
    <xsl:param name="year" as="xs:integer"/>
    <xsl:sequence select="(($year mod 4) eq 0) and ((($year mod 25) ne 0) or (($year mod 16) eq 0))"/>
  </xsl:function>

  <!-- Number of days in the given month of the given (astronomical) year. -->
  <xsl:function name="date:_days-in-month" as="xs:integer">
    <xsl:param name="year" as="xs:integer"/>
    <xsl:param name="month" as="xs:integer"/>
    <xsl:sequence select="(31, (if (date:_is-leap($year)) then 29 else 28), 31, 30, 31, 30,
                              31, 31, 30, 31, 30, 31)[$month]"/>
  </xsl:function>

  <!-- Port of the libxslt DAY_IN_YEAR macro: days before the month plus day. -->
  <xsl:function name="date:_day-in-year" as="xs:integer">
    <xsl:param name="year" as="xs:integer"/>
    <xsl:param name="month" as="xs:integer"/>
    <xsl:param name="day" as="xs:integer"/>
    <xsl:sequence select="sum(for $m in 1 to ($month - 1) return date:_days-in-month($year, $m)) + $day"/>
  </xsl:function>

  <!--
      Port of _exsltDateDayInWeek: day of week (Sunday = 0) from the day-in-year
      and the (astronomical) year. Negative years use the second variant of the
      C code, with the explicit +7 correction for negative remainders.
  -->
  <xsl:function name="date:_day-in-week0" as="xs:integer">
    <xsl:param name="day-in-year" as="xs:integer"/>
    <xsl:param name="year" as="xs:integer"/>
    <xsl:variable name="raw" as="xs:integer"
                  select="if ($year gt 0) then
                            (($year mod 7) - 1
                             + (($year - 1) idiv 4) - (($year - 1) idiv 100) + (($year - 1) idiv 400)
                             + $day-in-year) mod 7
                          else
                            (($year mod 7) - 2
                             + ($year idiv 4) - ($year idiv 100) + ($year idiv 400)
                             + $day-in-year) mod 7"/>
    <xsl:sequence select="if ($raw lt 0) then $raw + 7 else $raw"/>
  </xsl:function>

  <!-- Port of the leap-day count inside _exsltDateCastYMToDays. -->
  <xsl:function name="date:_leap-count" as="xs:integer">
    <xsl:param name="year" as="xs:integer"/>
    <xsl:sequence select="if ($year gt 0) then
                            (($year - 1) idiv 4) - (($year - 1) idiv 100) + (($year - 1) idiv 400)
                          else
                            ($year idiv 4) - ($year idiv 100) + ($year idiv 400)"/>
  </xsl:function>

  <!--
      Port of _exsltDateCastYMToDays: total days to (year, month), with year 1
      starting at day 0. The year must be the internal astronomical number.
  -->
  <xsl:function name="date:_cast-ym-to-days" as="xs:integer">
    <xsl:param name="year" as="xs:integer"/>
    <xsl:param name="month" as="xs:integer"/>
    <xsl:variable name="before" as="xs:integer"
                  select="sum(for $m in 1 to ($month - 1) return date:_days-in-month($year, $m))"/>
    <xsl:sequence select="($year - 1) * 365 + date:_leap-count($year) + $before
                          + (if ($year le 0) then -1 else 0)"/>
  </xsl:function>

  <!-- ======================================================================
       Private helpers: lexical parsing (port of the libxslt grammar, which
       deliberately differs from the xs:dateTime cast: no leap seconds, no
       lowercase t or z designators, gMonth uses the double-dash MM form)
       ====================================================================== -->

  <!--
      Parses an ISO 8601 date/time lexical form into a map:
        type   : dateTime | date | gYearMonth | gYear | gMonthDay | gDay |
                 gMonth | time
        year   : xs:integer, astronomical (BC years stored +1, like libxslt)
        month  : xs:integer (default 1)
        day    : xs:integer (default 1)
        hour   : xs:integer (default 0)
        minute : xs:integer (default 0)
        second : xs:decimal (default 0)
        tzo    : xs:integer, timezone offset in minutes (default 0)
        tzf    : xs:boolean, true when the timezone was an explicit 'Z'
      Returns the empty sequence when the string is not a valid libxslt
      date/time value.
  -->
  <xsl:function name="date:_parse" as="map(*)?">
    <xsl:param name="value" as="xs:string?"/>
    <xsl:variable name="v" as="xs:string" select="normalize-space($value)"/>
    <xsl:variable name="TZ" as="xs:string" select="'(Z|[+-][0-9]{2}:[0-9]{2})'"/>
    <xsl:variable name="no-year" as="xs:string" select="'0000'"/>
    <xsl:choose>
      <!-- xs:dateTime (CCYY-MM-DDThh:mm:ss[.fff][tz]) -->
      <xsl:when test="matches($v, concat('^(-)?([0-9]{4,})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2}(\.[0-9]+)?)', $TZ, '?$'))">
        <xsl:analyze-string select="$v"
                            regex="^(-)?([0-9]{{4,}})-([0-9]{{2}})-([0-9]{{2}})T([0-9]{{2}}):([0-9]{{2}}):([0-9]{{2}}(?:\.[0-9]+)?)(Z|[+-][0-9]{{2}}:[0-9]{{2}})?$">
          <xsl:matching-substring>
            <xsl:sequence select="date:_build(regex-group(1) eq '-', regex-group(2), regex-group(3),
                                              regex-group(4), regex-group(5), regex-group(6),
                                              regex-group(7), regex-group(8), 'dateTime')"/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <!-- xs:date (CCYY-MM-DD[tz]) -->
      <xsl:when test="matches($v, concat('^(-)?([0-9]{4,})-([0-9]{2})-([0-9]{2})', $TZ, '?$'))">
        <xsl:analyze-string select="$v"
                            regex="^(-)?([0-9]{{4,}})-([0-9]{{2}})-([0-9]{{2}})(Z|[+-][0-9]{{2}}:[0-9]{{2}})?$">
          <xsl:matching-substring>
            <xsl:sequence select="date:_build(regex-group(1) eq '-', regex-group(2), regex-group(3),
                                              regex-group(4), '00', '00', '00',
                                              regex-group(5), 'date')"/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <!-- xs:gYearMonth (CCYY-MM[tz]) -->
      <xsl:when test="matches($v, concat('^(-)?([0-9]{4,})-([0-9]{2})', $TZ, '?$'))">
        <xsl:analyze-string select="$v"
                            regex="^(-)?([0-9]{{4,}})-([0-9]{{2}})(Z|[+-][0-9]{{2}}:[0-9]{{2}})?$">
          <xsl:matching-substring>
            <xsl:sequence select="date:_build(regex-group(1) eq '-', regex-group(2), regex-group(3),
                                              '01', '00', '00', '00',
                                              regex-group(4), 'gYearMonth')"/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <!-- xs:gYear (CCYY[tz]) -->
      <xsl:when test="matches($v, concat('^(-)?([0-9]{4,})', $TZ, '?$'))">
        <xsl:analyze-string select="$v"
                            regex="^(-)?([0-9]{{4,}})(Z|[+-][0-9]{{2}}:[0-9]{{2}})?$">
          <xsl:matching-substring>
            <xsl:sequence select="date:_build(regex-group(1) eq '-', regex-group(2), '01',
                                              '01', '00', '00', '00',
                                              regex-group(3), 'gYear')"/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <!-- xs:gMonthDay, two dashes, MM-DD[tz] -->
      <xsl:when test="matches($v, concat('^--([0-9]{2})-([0-9]{2})', $TZ, '?$'))">
        <xsl:analyze-string select="$v"
                            regex="^--([0-9]{{2}})-([0-9]{{2}})(Z|[+-][0-9]{{2}}:[0-9]{{2}})?$">
          <xsl:matching-substring>
            <xsl:sequence select="date:_build(false(), $no-year, regex-group(1), regex-group(2),
                                              '00', '00', '00', regex-group(3), 'gMonthDay')"/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <!-- xs:gDay, three dashes, DD[tz] -->
      <xsl:when test="matches($v, concat('^---([0-9]{2})', $TZ, '?$'))">
        <xsl:analyze-string select="$v"
                            regex="^---([0-9]{{2}})(Z|[+-][0-9]{{2}}:[0-9]{{2}})?$">
          <xsl:matching-substring>
            <xsl:sequence select="date:_build(false(), $no-year, '01', regex-group(1),
                                              '00', '00', '00', regex-group(2), 'gDay')"/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <!-- xs:gMonth, two dashes, MM, two dashes[tz] -->
      <xsl:when test="matches($v, concat('^--([0-9]{2})--', $TZ, '?$'))">
        <xsl:analyze-string select="$v"
                            regex="^--([0-9]{{2}})--(Z|[+-][0-9]{{2}}:[0-9]{{2}})?$">
          <xsl:matching-substring>
            <xsl:sequence select="date:_build(false(), $no-year, regex-group(1), '01',
                                              '00', '00', '00', regex-group(2), 'gMonth')"/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <!-- xs:time (hh:mm:ss[.fff][tz]) -->
      <xsl:when test="matches($v, concat('^([0-9]{2}):([0-9]{2}):([0-9]{2}(\.[0-9]+)?)', $TZ, '?$'))">
        <xsl:analyze-string select="$v"
                            regex="^([0-9]{{2}}):([0-9]{{2}}):([0-9]{{2}}(?:\.[0-9]+)?)(Z|[+-][0-9]{{2}}:[0-9]{{2}})?$">
          <xsl:matching-substring>
            <xsl:sequence select="date:_build(false(), $no-year, '01', '01',
                                              regex-group(1), regex-group(2), regex-group(3),
                                              regex-group(4), 'time')"/>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--
      Validates the captured components and builds the parse map. Year digits
      must be at least four, must not start with '0' when longer, and must not
      be zero. Ranges follow the libxslt validators: month 1-12, day within
      the month (libxslt leap rule on the astronomical year), hour 0-23,
      minute 0-59, second < 60, |tzo| < 1440 with two-digit fields.
  -->
  <xsl:function name="date:_build" as="map(*)?">
    <xsl:param name="neg" as="xs:boolean"/>
    <xsl:param name="year-digits" as="xs:string"/>
    <xsl:param name="month" as="xs:string"/>
    <xsl:param name="day" as="xs:string"/>
    <xsl:param name="hour" as="xs:string"/>
    <xsl:param name="minute" as="xs:string"/>
    <xsl:param name="second" as="xs:string"/>
    <xsl:param name="tz" as="xs:string"/>
    <xsl:param name="type" as="xs:string"/>
    <xsl:variable name="tzo" as="xs:integer"
                  select="if ($tz eq 'Z' or $tz eq '') then 0
                          else (xs:integer(substring($tz, 2, 2)) * 60 + xs:integer(substring($tz, 5, 2)))
                               * (if (starts-with($tz, '-')) then -1 else 1)"/>
    <xsl:variable name="y" as="xs:integer"
                  select="(if ($neg) then -1 else 1) * xs:integer($year-digits) + (if ($neg) then 1 else 0)"/>
    <xsl:choose>
      <!-- The '0000' sentinel marks types without a year (gMonthDay, gDay,
           gMonth, time); there the day validation runs against year 0
           (leap), matching libxslt's VALID_MDAY on an unset year. -->
      <xsl:when test="(string-length($year-digits) gt 4 and starts-with($year-digits, '0'))
                      or ($type = ('dateTime', 'date', 'gYearMonth', 'gYear')
                          and xs:integer($year-digits) eq 0)
                      or xs:integer($month) lt 1 or xs:integer($month) gt 12
                      or xs:integer($day) lt 1
                      or xs:integer($day) gt date:_days-in-month($y, xs:integer($month))
                      or xs:integer($hour) gt 23
                      or xs:integer($minute) gt 59
                      or xs:decimal($second) ge 60
                      or ($tz ne '' and $tz ne 'Z'
                          and (xs:integer(substring($tz, 2, 2)) gt 23
                               or xs:integer(substring($tz, 5, 2)) gt 59
                               or abs($tzo) ge 1440))">
        <xsl:sequence select="()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="map {
            'type': $type, 'year': $y, 'month': xs:integer($month), 'day': xs:integer($day),
            'hour': xs:integer($hour), 'minute': xs:integer($minute),
            'second': xs:decimal($second), 'tzo': $tzo, 'tzf': $tz eq 'Z'
          }"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ======================================================================
       Private helpers: number and date/time formatting (ports of the
       libxml2/libexslt formatters)
       ====================================================================== -->

  <!--
      Port of xmlXPathFormatNumber (the XPath 1.0 number -> string conversion):
      integers within 32-bit range print as integers, magnitudes above 1E9 or
      below 1E-5 print in scientific notation with trailing-zero stripping,
      everything else prints as a plain decimal. Operates on xs:decimal, which
      is exact for every value produced by this module.
  -->
  <xsl:function name="date:_format-number" as="xs:string">
    <xsl:param name="value" as="xs:decimal"/>
    <xsl:variable name="abs" as="xs:decimal" select="abs($value)"/>
    <xsl:variable name="sign" as="xs:string" select="if ($value lt 0) then '-' else ''"/>
    <xsl:choose>
      <xsl:when test="$value eq 0">
        <xsl:sequence select="'0'"/>
      </xsl:when>
      <xsl:when test="$value eq floor($value) and $abs lt 2147483647">
        <xsl:sequence select="$sign || string(xs:integer($abs))"/>
      </xsl:when>
      <xsl:when test="$abs gt 1000000000 or $abs lt 0.00001">
        <xsl:variable name="s" as="xs:string" select="string($abs)"/>
        <xsl:variable name="int-part" as="xs:string" select="substring-before($s || '.', '.')"/>
        <xsl:variable name="frac-part" as="xs:string" select="substring-after($s, '.')"/>
        <xsl:choose>
          <xsl:when test="$int-part ne '0'">
            <xsl:variable name="digits" as="xs:string"
                          select="replace($int-part || $frac-part, '0+$', '')"/>
            <xsl:variable name="exp" as="xs:integer" select="string-length($int-part) - 1"/>
            <xsl:sequence select="$sign || substring($digits, 1, 1)
                                  || (if (string-length($digits) gt 1) then '.' || substring($digits, 2) else '')
                                  || 'e' || (if ($exp lt 0) then '-' else '+')
                                  || format-number(abs($exp), '00')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="first" as="xs:integer"
                          select="string-length($frac-part) - string-length(replace($frac-part, '^0+', '')) + 1"/>
            <xsl:variable name="digits" as="xs:string"
                          select="replace(substring($frac-part, $first), '0+$', '')"/>
            <xsl:variable name="exp" as="xs:integer" select="-$first"/>
            <xsl:sequence select="$sign || substring($digits, 1, 1)
                                  || (if (string-length($digits) gt 1) then '.' || substring($digits, 2) else '')
                                  || 'e' || (if ($exp lt 0) then '-' else '+')
                                  || format-number(abs($exp), '00')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$sign || string($abs)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Formats a year in the libxslt gYear style: '-' + value for astronomical
      years <= 0 (where 0 prints as -0001), zero-padded to four digits. -->
  <xsl:function name="date:_format-year" as="xs:string">
    <xsl:param name="year" as="xs:integer"/>
    <xsl:sequence select="(if ($year le 0) then '-' else '') || format-number(abs(if ($year le 0) then $year - 1 else $year), '0000')"/>
  </xsl:function>

  <!--
      Port of exsltFormatTime: hh:mm:ss with the fractional part rounded to
      nanoseconds (trailing zeros dropped, no carry into the seconds) plus the
      timezone. The timezone is emitted when $tzf (explicit 'Z') or tzo is
      non-zero, or always when $force (xs:dateTime results print 'Z' for a
      zero offset).
  -->
  <xsl:function name="date:_format-time-of-day" as="xs:string">
    <xsl:param name="hour" as="xs:integer"/>
    <xsl:param name="minute" as="xs:integer"/>
    <xsl:param name="second" as="xs:decimal"/>
    <xsl:param name="tzo" as="xs:integer"/>
    <xsl:param name="tzf" as="xs:boolean"/>
    <xsl:param name="force" as="xs:boolean"/>
    <xsl:variable name="frac" as="xs:decimal" select="$second - floor($second)"/>
    <xsl:variable name="nsecs" as="xs:integer"
                  select="min((999999999, xs:integer(floor($frac * 1000000000 + 0.5))))"/>
    <xsl:variable name="frac-string" as="xs:string"
                  select="if ($nsecs gt 0)
                          then '.' || replace(format-number($nsecs, '000000000'), '0+$', '')
                          else ''"/>
    <xsl:variable name="tz-string" as="xs:string"
                  select="if ($force or $tzf or $tzo ne 0) then
                            (if ($tzo eq 0) then 'Z'
                             else (if ($tzo lt 0) then '-' else '+')
                                   || format-number(abs($tzo) idiv 60, '00') || ':'
                                   || format-number(abs($tzo) mod 60, '00'))
                          else ''"/>
    <xsl:sequence select="format-number($hour, '00') || ':' || format-number($minute, '00') || ':'
                          || format-number(xs:integer(floor($second)), '00') || $frac-string || $tz-string"/>
  </xsl:function>

  <!-- Formats YYYY-MM-DD with the optional timezone (libxslt xs:date style). -->
  <xsl:function name="date:_format-date" as="xs:string">
    <xsl:param name="year" as="xs:integer"/>
    <xsl:param name="month" as="xs:integer"/>
    <xsl:param name="day" as="xs:integer"/>
    <xsl:param name="tzo" as="xs:integer"/>
    <xsl:param name="tzf" as="xs:boolean"/>
    <xsl:sequence select="date:_format-year($year) || '-' || format-number($month, '00') || '-'
                          || format-number($day, '00')
                          || (if ($tzf or $tzo ne 0) then
                                (if ($tzo eq 0) then 'Z'
                                 else (if ($tzo lt 0) then '-' else '+')
                                       || format-number(abs($tzo) idiv 60, '00') || ':'
                                       || format-number(abs($tzo) mod 60, '00'))
                              else '')"/>
  </xsl:function>

  <!--
      Port of exsltDateFormatDuration for the libxslt duration model: signed
      months, signed days, and seconds in [0, 86400). A negative day count is
      complemented against the seconds (86400 - sec, day + 1) before the '-'
      sign is attached; months and days never share opposite signs here
      (_exsltDateAddDurCalc rejects those as indeterminate).
  -->
  <xsl:function name="date:_format-duration" as="xs:string">
    <xsl:param name="months" as="xs:integer"/>
    <xsl:param name="days" as="xs:integer"/>
    <xsl:param name="seconds" as="xs:decimal"/>
    <xsl:variable name="neg" as="xs:boolean" select="$months lt 0 or $days lt 0"/>
    <xsl:variable name="abs-months" as="xs:integer" select="abs($months)"/>
    <xsl:variable name="complemented" as="map(*)"
                  select="if ($days lt 0 and $seconds ne 0) then
                            map { 'days': -($days + 1), 'seconds': 86400 - $seconds }
                          else
                            map { 'days': abs($days), 'seconds': $seconds }"/>
    <xsl:variable name="years" as="xs:integer" select="$abs-months idiv 12"/>
    <xsl:variable name="rest-months" as="xs:integer" select="$abs-months mod 12"/>
    <xsl:variable name="rest" as="xs:decimal" select="$complemented?seconds"/>
    <xsl:variable name="hours" as="xs:integer" select="xs:integer($rest idiv 3600)"/>
    <xsl:variable name="mins" as="xs:integer" select="xs:integer(($rest - 3600 * $hours) idiv 60)"/>
    <xsl:variable name="secs" as="xs:decimal" select="$rest - 3600 * $hours - 60 * $mins"/>
    <xsl:variable name="date-part" as="xs:string"
                  select="(if ($years ne 0) then string($years) || 'Y' else '')
                          || (if ($rest-months ne 0) then string($rest-months) || 'M' else '')
                          || (if ($complemented?days ne 0) then string($complemented?days) || 'D' else '')"/>
    <xsl:variable name="time-part" as="xs:string"
                  select="(if ($hours ne 0) then string($hours) || 'H' else '')
                          || (if ($mins ne 0) then string($mins) || 'M' else '')
                          || (if ($secs ne 0) then date:_format-number($secs) || 'S' else '')"/>
    <xsl:sequence select="if ($date-part eq '' and $time-part eq '') then
                            (if ($neg) then '-P0D' else 'P0D')
                          else
                            (if ($neg) then '-' else '') || 'P' || $date-part
                            || (if ($time-part ne '') then 'T' || $time-part else '')"/>
  </xsl:function>

  <!-- ======================================================================
       Private helpers: duration parsing (port of exsltDateParseDuration —
       hours/minutes fold into days, seconds stay sub-day, and a leading '-'
       complements the seconds rather than negating them)
       ====================================================================== -->

  <!--
      Parses an xs:duration lexical form into the libxslt duration model:
      a map with signed months, signed days and seconds in [0, 86400).
      Returns the empty sequence for invalid input.
  -->
  <xsl:function name="date:_parse-duration" as="map(*)?">
    <xsl:param name="value" as="xs:string?"/>
    <xsl:variable name="v" as="xs:string" select="normalize-space($value)"/>
    <xsl:analyze-string select="$v"
                        regex="^(-)?P(?:([0-9]+)Y)?(?:([0-9]+)M)?(?:([0-9]+)D)?(?:T(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+(?:\.[0-9]*)?|\.[0-9]+)S)?)?$">
      <xsl:matching-substring>
        <xsl:variable name="has-date" as="xs:boolean"
                      select="regex-group(2) ne '' or regex-group(3) ne '' or regex-group(4) ne ''"/>
        <xsl:variable name="has-time" as="xs:boolean"
                      select="regex-group(5) ne '' or regex-group(6) ne '' or regex-group(7) ne ''"/>
        <xsl:choose>
          <!-- 'P', 'PT' and 'P1YT' are not durations -->
          <xsl:when test="not($has-date or $has-time)">
            <xsl:sequence select="()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="sec" as="xs:string" select="regex-group(7)"/>
            <xsl:variable name="neg" as="xs:boolean" select="regex-group(1) eq '-'"/>
            <xsl:variable name="months" as="xs:integer"
                          select="(regex-group(2)[. ne ''] ! xs:integer(.), 0)[1] * 12
                                  + (regex-group(3)[. ne ''] ! xs:integer(.), 0)[1]"/>
            <xsl:variable name="hours" as="xs:integer" select="(regex-group(5)[. ne ''] ! xs:integer(.), 0)[1]"/>
            <xsl:variable name="mins" as="xs:integer" select="(regex-group(6)[. ne ''] ! xs:integer(.), 0)[1]"/>
            <xsl:variable name="sec-digits" as="xs:string"
                          select="if (contains($sec, '.')) then substring-before($sec, '.') else $sec"/>
            <xsl:variable name="sec-int" as="xs:integer"
                          select="if ($sec-digits eq '') then 0 else xs:integer($sec-digits)"/>
            <xsl:variable name="sec-frac-digits" as="xs:string"
                          select="if (contains($sec, '.')) then substring-after($sec, '.') else ''"/>
            <xsl:variable name="sec-frac" as="xs:decimal"
                          select="if ($sec-frac-digits eq '') then 0 else xs:decimal('0.' || $sec-frac-digits)"/>
            <xsl:variable name="days" as="xs:integer"
                          select="(regex-group(4)[. ne ''] ! xs:integer(.), 0)[1]
                                  + ($hours idiv 24) + ($mins idiv 1440) + ($sec-int idiv 86400)"/>
            <xsl:variable name="subday" as="xs:decimal"
                          select="($hours mod 24) * 3600 + ($mins mod 1440) * 60
                                  + ($sec-int mod 86400) + $sec-frac"/>
            <xsl:variable name="carry-days" as="xs:integer" select="xs:integer($subday idiv 86400)"/>
            <xsl:variable name="total-days" as="xs:integer" select="$days + $carry-days"/>
            <xsl:variable name="total-sec" as="xs:decimal" select="$subday - 86400 * $carry-days"/>
            <xsl:sequence select="if ($neg) then
                                    map {
                                      'months': -$months, 'days': (if ($total-sec ne 0) then -$total-days - 1 else -$total-days),
                                      'seconds': (if ($total-sec ne 0) then 86400 - $total-sec else $total-sec)
                                    }
                                  else
                                    map { 'months': $months, 'days': $total-days, 'seconds': $total-sec }"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:sequence select="()"/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:function>

  <!--
      Port of _exsltDateAddDurCalc: adds two libxslt-model durations, carries
      seconds into days once, and rejects results whose months and days have
      opposite signs (indeterminate). Returns () on overflow or indeterminacy.
  -->
  <xsl:function name="date:_add-durations" as="map(*)?">
    <xsl:param name="x" as="map(*)"/>
    <xsl:param name="y" as="map(*)"/>
    <xsl:variable name="months" as="xs:integer" select="$x?months + $y?months"/>
    <xsl:variable name="days" as="xs:integer" select="$x?days + $y?days"/>
    <xsl:variable name="sec-sum" as="xs:decimal" select="$x?seconds + $y?seconds"/>
    <xsl:variable name="seconds" as="xs:decimal" select="if ($sec-sum ge 86400) then $sec-sum - 86400 else $sec-sum"/>
    <xsl:variable name="carried-days" as="xs:integer" select="$days + (if ($sec-sum ge 86400) then 1 else 0)"/>
    <xsl:choose>
      <xsl:when test="abs($months) gt 9223372036854775807 or abs($carried-days) gt 9223372036854775807">
        <xsl:sequence select="()"/>
      </xsl:when>
      <xsl:when test="$carried-days ge 0
                      and (($carried-days gt 0 or $seconds gt 0) and $months lt 0)">
        <xsl:sequence select="()"/>
      </xsl:when>
      <xsl:when test="$carried-days lt 0 and $months gt 0">
        <xsl:sequence select="()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="map { 'months': $months, 'days': $carried-days, 'seconds': $seconds }"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--
      Port of _exsltDateDifference: y - x as a libxslt-model duration. Both
      operands are first truncated to the less specific type. Year/month-level
      operands yield a month count (unless $force-day, as used by
      date:seconds); otherwise the result is days plus sub-day seconds, with
      timezone offsets folded into the seconds. Returns () on invalid input.
  -->
  <xsl:function name="date:_difference" as="map(*)?">
    <xsl:param name="x" as="map(*)"/>
    <xsl:param name="y" as="map(*)"/>
    <xsl:param name="force-day" as="xs:boolean"/>
    <xsl:variable name="sx" as="map(*)"
                  select="if (date:_specificity($x?type) gt date:_specificity($y?type)) then
                            date:_truncate($x, $y?type)
                          else $x"/>
    <xsl:variable name="sy" as="map(*)"
                  select="if (date:_specificity($y?type) gt date:_specificity($x?type)) then
                            date:_truncate($y, $x?type)
                          else $y"/>
    <xsl:choose>
      <xsl:when test="$sx?type = ('gYear', 'gYearMonth') and not($force-day)">
        <xsl:sequence select="map {
            'months': ($sy?year - $sx?year) * 12 + ($sy?month - $sx?month),
            'days': 0, 'seconds': 0
          }"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="raw-sec" as="xs:decimal"
                      select="($sy?hour * 3600 + $sy?minute * 60 + $sy?second)
                              - ($sx?hour * 3600 + $sx?minute * 60 + $sx?second)
                              + ($sx?tzo - $sy?tzo) * 60"/>
        <xsl:variable name="carry" as="xs:integer" select="xs:integer(floor($raw-sec div 86400))"/>
        <xsl:sequence select="map {
            'months': 0,
            'days': date:_cast-ym-to-days($sy?year, $sy?month)
                    - date:_cast-ym-to-days($sx?year, $sx?month)
                    + $sy?day - $sx?day + $carry,
            'seconds': $raw-sec - 86400 * $carry
          }"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Specificity ranking used for truncation: gYear < gYearMonth < date <
      dateTime (other types never reach _difference or _truncate). -->
  <xsl:function name="date:_specificity" as="xs:integer">
    <xsl:param name="type" as="xs:string"/>
    <xsl:sequence select="(0, 1, 2, 3, 4)[(if ($type eq 'gYear') then 2 else if ($type eq 'gYearMonth') then 3
                                             else if ($type eq 'date') then 4
                                             else if ($type eq 'dateTime') then 5 else 1)]"/>
  </xsl:function>

  <!--
      Port of _exsltDateTruncateDate: zeroes the fields more specific than
      $type. The timezone offset is preserved.
  -->
  <xsl:function name="date:_truncate" as="map(*)">
    <xsl:param name="d" as="map(*)"/>
    <xsl:param name="type" as="xs:string"/>
    <xsl:sequence select="map {
        'type': $type,
        'year': $d?year,
        'month': (if ($type = ('gYearMonth', 'date', 'dateTime')) then $d?month else 1),
        'day': (if ($type = ('date', 'dateTime')) then $d?day else 1),
        'hour': (if ($type eq 'dateTime') then $d?hour else 0),
        'minute': (if ($type eq 'dateTime') then $d?minute else 0),
        'second': (if ($type eq 'dateTime') then $d?second else 0),
        'tzo': $d?tzo, 'tzf': $d?tzf
      }"/>
  </xsl:function>

  <!-- ======================================================================
       Current date and time
       ====================================================================== -->

  <!-- Returns the current date and time as YYYY-MM-DDThh:mm:ss. -->
  <xsl:function name="date:date-time" as="xs:string">
    <xsl:sequence select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')"/>
  </xsl:function>

  <!-- Returns the date portion (YYYY-MM-DD) of the argument, or of today.
      Only xs:dateTime and xs:date arguments yield a result. -->
  <xsl:function name="date:date" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (not($date-time)) then
                            format-date(current-date(), '[Y0001]-[M01]-[D01]')
                          else if (exists($d) and $d?type = ('dateTime', 'date')) then
                            date:_format-date($d?year, $d?month, $d?day, $d?tzo, $d?tzf)
                          else ''"/>
  </xsl:function>

  <!-- Returns the time portion (hh:mm:ss) of the argument, or of now. Only
      xs:dateTime and xs:time arguments yield a result. -->
  <xsl:function name="date:time" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (not($date-time)) then
                            format-time(current-time(), '[H01]:[m01]:[s01]')
                          else if (exists($d) and $d?type = ('dateTime', 'time')) then
                            date:_format-time-of-day($d?hour, $d?minute, $d?second, $d?tzo, $d?tzf, false())
                          else ''"/>
  </xsl:function>

  <!-- ======================================================================
       Component extraction. Each function enforces the EXSLT type-validity
       contract of the libxslt reference and returns xs:string so that
       value-of output matches the XPath 1.0 number formatting of the
       reference exactly ('NaN' marks rejected input).
       ====================================================================== -->

  <!-- Returns the year ('NaN' for types other than dateTime, date,
      gYearMonth, gYear; BC years are printed without year zero, per
      libxslt). -->
  <xsl:function name="date:year" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date', 'gYearMonth', 'gYear')) then
                            string((if ($d?year le 0) then $d?year - 1 else $d?year))
                          else 'NaN'"/>
  </xsl:function>

  <!-- Returns 'true'/'false' when the year is a leap year ('NaN' for types
      other than dateTime, date, gYearMonth, gYear). -->
  <xsl:function name="date:leap-year" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date', 'gYearMonth', 'gYear')) then
                            string(date:_is-leap($d?year))
                          else 'NaN'"/>
  </xsl:function>

  <!-- Returns the month of the year (1-12; 'NaN' for types other than
      dateTime, date, gYearMonth, gMonth, gMonthDay). -->
  <xsl:function name="date:month-in-year" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date', 'gYearMonth', 'gMonth', 'gMonthDay')) then
                            string($d?month)
                          else 'NaN'"/>
  </xsl:function>

  <!-- Returns the English name of the month ('' on invalid input). -->
  <xsl:function name="date:month-name" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date', 'gYearMonth', 'gMonth', 'gMonthDay')) then
                            ('', 'January', 'February', 'March', 'April', 'May', 'June', 'July',
                             'August', 'September', 'October', 'November', 'December')[$d?month + 1]
                          else ''"/>
  </xsl:function>

  <!-- Returns the English month abbreviation ('' on invalid input). -->
  <xsl:function name="date:month-abbreviation" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date', 'gYearMonth', 'gMonth', 'gMonthDay')) then
                            ('', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul',
                             'Aug', 'Sep', 'Oct', 'Nov', 'Dec')[$d?month + 1]
                          else ''"/>
  </xsl:function>

  <!-- Returns the libxslt week number of the argument ('NaN' for types other
      than dateTime, date). -->
  <xsl:function name="date:week-in-year" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date')) then
                            string(date:_week-in-year($d?year, $d?month, $d?day))
                          else 'NaN'"/>
  </xsl:function>

  <!-- Port of exsltDateWeekInYear (the libxslt ISO-8601 variant, which
      handles negative years and skips year zero). -->
  <xsl:function name="date:_week-in-year" as="xs:integer">
    <xsl:param name="year" as="xs:integer"/>
    <xsl:param name="month" as="xs:integer"/>
    <xsl:param name="day" as="xs:integer"/>
    <xsl:variable name="diy" as="xs:integer" select="date:_day-in-year($year, $month, $day)"/>
    <xsl:variable name="diw" as="xs:integer" select="(date:_day-in-week0($diy, $year) + 6) mod 7"/>
    <xsl:variable name="shifted" as="xs:integer" select="$diy + (3 - $diw)"/>
    <xsl:variable name="year-length" as="xs:integer" select="date:_day-in-year($year, 12, 31)"/>
    <xsl:variable name="adjusted" as="xs:integer"
                  select="if ($shifted lt 1) then
                            date:_day-in-year((if ($year - 1 eq 0) then -1 else $year - 1), 12, 31) + $shifted
                          else if ($shifted gt $year-length) then
                            $shifted - $year-length
                          else
                            $shifted"/>
    <xsl:sequence select="(($adjusted - 1) idiv 7) + 1"/>
  </xsl:function>

  <!-- Returns the day of the year (1-366; 'NaN' for types other than
      dateTime, date). -->
  <xsl:function name="date:day-in-year" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date')) then
                            string(date:_day-in-year($d?year, $d?month, $d?day))
                          else 'NaN'"/>
  </xsl:function>

  <!-- Returns the day of the month (1-31; 'NaN' for types other than
      dateTime, date, gMonthDay, gDay). -->
  <xsl:function name="date:day-in-month" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date', 'gMonthDay', 'gDay')) then
                            string($d?day)
                          else 'NaN'"/>
  </xsl:function>

  <!-- Returns the ordinal week of the month (1-5; 'NaN' for types other than
      dateTime, date). -->
  <xsl:function name="date:day-of-week-in-month" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date')) then
                            string(($d?day - 1) idiv 7 + 1)
                          else 'NaN'"/>
  </xsl:function>

  <!-- Returns the day of the week as a number: 1 = Sunday, ..., 7 = Saturday
      ('NaN' for types other than dateTime, date). -->
  <xsl:function name="date:day-in-week" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date')) then
                            string(date:_day-in-week0(date:_day-in-year($d?year, $d?month, $d?day), $d?year) + 1)
                          else 'NaN'"/>
  </xsl:function>

  <!-- Returns the English name of the day of the week ('' on invalid input). -->
  <xsl:function name="date:day-name" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date')) then
                            ('', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
                             'Saturday')[date:_day-in-week0(date:_day-in-year($d?year, $d?month, $d?day), $d?year) + 2]
                          else ''"/>
  </xsl:function>

  <!-- Returns the English day abbreviation ('' on invalid input). -->
  <xsl:function name="date:day-abbreviation" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'date')) then
                            ('', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri',
                             'Sat')[date:_day-in-week0(date:_day-in-year($d?year, $d?month, $d?day), $d?year) + 2]
                          else ''"/>
  </xsl:function>

  <!-- Returns the hour of the day (0-23; 'NaN' for types other than
      dateTime, time). -->
  <xsl:function name="date:hour-in-day" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'time')) then
                            string($d?hour)
                          else 'NaN'"/>
  </xsl:function>

  <!-- Returns the minute of the hour (0-59; 'NaN' for types other than
      dateTime, time). -->
  <xsl:function name="date:minute-in-hour" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'time')) then
                            string($d?minute)
                          else 'NaN'"/>
  </xsl:function>

  <!-- Returns the second of the minute (0-59; 'NaN' for types other than
      dateTime, time). -->
  <xsl:function name="date:second-in-minute" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:sequence select="if (exists($d) and $d?type = ('dateTime', 'time')) then
                            date:_format-number($d?second)
                          else 'NaN'"/>
  </xsl:function>

  <!-- ======================================================================
       Durations
       ====================================================================== -->

  <!--
      Converts a number of seconds to a duration string (PnDTnHnMnS) with the
      fraction printed in full, matching the golden-era libxslt formatter.
      NaN and ±Infinity yield '' per the EXSLT spec; a day count overflowing
      libxslt's long arithmetic yields '' as well (matching the reference,
      which returns NULL there).
  -->
  <xsl:function name="date:duration" as="xs:string">
    <xsl:param name="seconds" as="xs:double"/>
    <xsl:choose>
      <xsl:when test="$seconds ne $seconds or abs($seconds) eq xs:double('INF')">
        <xsl:sequence select="''"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="total" as="xs:decimal" select="abs(xs:decimal($seconds))"/>
        <xsl:variable name="days" as="xs:decimal" select="floor($total div 86400)"/>
        <xsl:choose>
          <xsl:when test="$days gt 9223372036854775807">
            <xsl:sequence select="''"/>
          </xsl:when>
          <xsl:when test="$total eq 0">
            <xsl:sequence select="'P0D'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="rest" as="xs:decimal" select="$total - 86400 * $days"/>
            <xsl:variable name="hours" as="xs:integer" select="xs:integer($rest idiv 3600)"/>
            <xsl:variable name="mins" as="xs:integer" select="xs:integer(($rest - 3600 * $hours) idiv 60)"/>
            <xsl:variable name="secs" as="xs:decimal" select="$rest - 3600 * $hours - 60 * $mins"/>
            <xsl:variable name="time-part" as="xs:string"
                          select="(if ($hours ne 0) then string($hours) || 'H' else '')
                                  || (if ($mins ne 0) then string($mins) || 'M' else '')
                                  || (if ($secs ne 0) then date:_format-number($secs) || 'S' else '')"/>
            <xsl:sequence select="(if ($seconds lt 0) then '-' else '') || 'P'
                                  || (if ($days ne 0) then string(xs:integer($days)) || 'D' else '')
                                  || (if ($time-part ne '') then 'T' || $time-part else '')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--
      Adds two durations with the libxslt component normalization and
      opposite-sign indeterminacy rule (_exsltDateAddDurCalc). Returns '' for
      invalid input or indeterminate results.
  -->
  <xsl:function name="date:add-duration" as="xs:string">
    <xsl:param name="duration1" as="xs:string?"/>
    <xsl:param name="duration2" as="xs:string?"/>
    <xsl:variable name="d1" as="map(*)?" select="date:_parse-duration($duration1)"/>
    <xsl:variable name="d2" as="map(*)?" select="date:_parse-duration($duration2)"/>
    <xsl:variable name="sum" as="map(*)?" select="if (exists($d1) and exists($d2)) then date:_add-durations($d1, $d2) else ()"/>
    <xsl:sequence select="if (exists($sum)) then
                            date:_format-duration($sum?months, $sum?days, $sum?seconds)
                          else ''"/>
  </xsl:function>

  <!--
      Adds a duration to a date or dateTime with the libxslt component
      arithmetic of _exsltDateAdd (calendar months, clamped days, seconds
      carried through min/hour/day). The result is formatted in the least
      specific type that can hold it — matching libxslt, a promoted
      xs:dateTime result always prints its timezone ('Z' when zero). Returns
      '' for invalid input.
  -->
  <xsl:function name="date:add" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:param name="duration" as="xs:string?"/>
    <xsl:variable name="dt" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:variable name="dur" as="map(*)?" select="date:_parse-duration($duration)"/>
    <xsl:sequence select="if (exists($dt) and $dt?type = ('gYear', 'gYearMonth', 'date', 'dateTime')
                              and exists($dur)) then
                            date:_add-to-date($dt, $dur)
                          else ''"/>
  </xsl:function>

  <!-- Port of _exsltDateAdd and the libxslt result-type adjustment. -->
  <xsl:function name="date:_add-to-date" as="xs:string">
    <xsl:param name="dt" as="map(*)"/>
    <xsl:param name="dur" as="map(*)"/>
    <xsl:variable name="m" as="xs:integer" select="$dur?months"/>
    <xsl:variable name="mon-temp" as="xs:integer" select="$dt?month + ($m mod 12)"/>
    <xsl:variable name="mon-carry" as="xs:integer"
                  select="($m idiv 12) + (if ($mon-temp lt 1) then -1 else if ($mon-temp gt 12) then 1 else 0)"/>
    <xsl:variable name="mon" as="xs:integer"
                  select="$mon-temp + (if ($mon-temp lt 1) then 12 else if ($mon-temp gt 12) then -12 else 0)"/>
    <xsl:variable name="year" as="xs:integer"
                  select="$dt?year + $mon-carry + ($dur?days idiv 146097) * 400"/>
    <xsl:variable name="sum" as="xs:decimal" select="$dt?second + $dur?seconds"/>
    <xsl:variable name="sec" as="xs:decimal" select="$sum mod 60"/>
    <xsl:variable name="carry0" as="xs:integer" select="xs:integer($sum idiv 60)"/>
    <xsl:variable name="min-temp" as="xs:integer" select="$dt?minute + ($carry0 mod 60)"/>
    <xsl:variable name="carry1" as="xs:integer"
                  select="($carry0 idiv 60) + (if ($min-temp ge 60) then 1 else 0)"/>
    <xsl:variable name="min" as="xs:integer" select="$min-temp + (if ($min-temp ge 60) then -60 else 0)"/>
    <xsl:variable name="hour-temp" as="xs:integer" select="$dt?hour + ($carry1 mod 24)"/>
    <xsl:variable name="carry2" as="xs:integer"
                  select="($carry1 idiv 24) + (if ($hour-temp ge 24) then 1 else 0)"/>
    <xsl:variable name="hour" as="xs:integer" select="$hour-temp + (if ($hour-temp ge 24) then -24 else 0)"/>
    <xsl:variable name="clamped" as="xs:integer"
                  select="min(($dt?day, date:_days-in-month($year, $mon)))"/>
    <xsl:variable name="day-total" as="xs:integer"
                  select="$clamped + ($dur?days mod 146097) + $carry2"/>
    <xsl:variable name="normalized" as="map(*)"
                  select="date:_normalize-day($year, $mon, $day-total)"/>
    <xsl:variable name="rtype" as="xs:string"
                  select="if ($dt?type eq 'dateTime'
                              or $hour ne 0 or $min ne 0 or $sec ne 0) then 'dateTime'
                          else if ($dt?type eq 'date') then 'date'
                          else if ($dt?day ne $normalized?day) then 'date'
                          else if ($dt?type ne 'gYearMonth' and $normalized?month ne 1) then 'gYearMonth'
                          else $dt?type"/>
    <xsl:choose>
      <xsl:when test="$rtype eq 'dateTime'">
        <xsl:sequence select="date:_format-year($normalized?year) || '-' || format-number($normalized?month, '00')
                              || '-' || format-number($normalized?day, '00')
                              || 'T' || date:_format-time-of-day($hour, $min, $sec, $dt?tzo, $dt?tzf, true())"/>
      </xsl:when>
      <xsl:when test="$rtype eq 'date'">
        <xsl:sequence select="date:_format-date($normalized?year, $normalized?month, $normalized?day,
                                                $dt?tzo, $dt?tzf)"/>
      </xsl:when>
      <xsl:when test="$rtype eq 'gYearMonth'">
        <xsl:sequence select="date:_format-year($normalized?year) || '-' || format-number($normalized?month, '00')
                              || (if ($dt?tzf or $dt?tzo ne 0) then
                                    (if ($dt?tzo eq 0) then 'Z'
                                     else (if ($dt?tzo lt 0) then '-' else '+')
                                           || format-number(abs($dt?tzo) idiv 60, '00') || ':'
                                           || format-number(abs($dt?tzo) mod 60, '00'))
                                  else '')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="date:_format-year($normalized?year)
                              || (if ($dt?tzf or $dt?tzo ne 0) then
                                    (if ($dt?tzo eq 0) then 'Z'
                                     else (if ($dt?tzo lt 0) then '-' else '+')
                                           || format-number(abs($dt?tzo) idiv 60, '00') || ':'
                                           || format-number(abs($dt?tzo) mod 60, '00'))
                                  else '')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Walks the (year, month, day-in-month total) triple into range, one
      month per step as in the C while loop. -->
  <xsl:function name="date:_normalize-day" as="map(*)">
    <xsl:param name="year" as="xs:integer"/>
    <xsl:param name="month" as="xs:integer"/>
    <xsl:param name="day" as="xs:integer"/>
    <xsl:variable name="max" as="xs:integer" select="date:_days-in-month($year, $month)"/>
    <xsl:choose>
      <xsl:when test="$day lt 1">
        <xsl:variable name="pm" as="xs:integer" select="if ($month gt 1) then $month - 1 else 12"/>
        <xsl:variable name="py" as="xs:integer" select="if ($month gt 1) then $year else $year - 1"/>
        <xsl:sequence select="date:_normalize-day($py, $pm, $day + date:_days-in-month($py, $pm))"/>
      </xsl:when>
      <xsl:when test="$day gt $max">
        <xsl:variable name="nm" as="xs:integer" select="if ($month lt 12) then $month + 1 else 1"/>
        <xsl:variable name="ny" as="xs:integer" select="if ($month lt 12) then $year else $year + 1"/>
        <xsl:sequence select="date:_normalize-day($ny, $nm, $day - $max)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="map { 'year': $year, 'month': $month, 'day': $day }"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--
      Returns the difference between two dates or dateTimes as a duration
      string (date2 - date1), replicating _exsltDateDifference including the
      truncation to the less specific operand and the year/month
      approximation for gYear/gYearMonth operands. Returns '' for invalid
      input.
  -->
  <xsl:function name="date:difference" as="xs:string">
    <xsl:param name="date1" as="xs:string?"/>
    <xsl:param name="date2" as="xs:string?"/>
    <xsl:variable name="x" as="map(*)?" select="date:_parse($date1)"/>
    <xsl:variable name="y" as="map(*)?" select="date:_parse($date2)"/>
    <xsl:variable name="diff" as="map(*)?"
                  select="if (exists($x) and exists($y)
                              and $x?type = ('gYear', 'gYearMonth', 'date', 'dateTime')
                              and $y?type = ('gYear', 'gYearMonth', 'date', 'dateTime')) then
                            date:_difference($x, $y, false())
                          else ()"/>
    <xsl:sequence select="if (exists($diff)) then
                            date:_format-duration($diff?months, $diff?days, $diff?seconds)
                          else ''"/>
  </xsl:function>

  <!--
      Returns the number of seconds represented by the argument: the total
      seconds of a duration (years and months must be zero), or the seconds
      since the Unix epoch of a gYear/gYearMonth/date/dateTime. Returns 'NaN'
      for anything else.
  -->
  <xsl:function name="date:seconds" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:variable name="d" as="map(*)?" select="date:_parse($date-time)"/>
    <xsl:choose>
      <xsl:when test="exists($d) and $d?type = ('gYear', 'gYearMonth', 'date', 'dateTime')">
        <xsl:variable name="epoch" as="map(*)"
                      select="map {
                          'type': 'dateTime', 'year': 1970, 'month': 1, 'day': 1,
                          'hour': 0, 'minute': 0, 'second': xs:decimal(0), 'tzo': 0, 'tzf': true()
                        }"/>
        <xsl:variable name="diff" as="map(*)" select="date:_difference($epoch, $d, true())"/>
        <xsl:sequence select="date:_format-number($diff?days * 86400 + $diff?seconds)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="dur" as="map(*)?" select="date:_parse-duration($date-time)"/>
        <xsl:sequence select="if (exists($dur) and $dur?months eq 0) then
                                date:_format-number($dur?days * 86400 + $dur?seconds)
                              else 'NaN'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--
      Sums the durations held by a node-set, accumulating with
      _exsltDateAddDurCalc as libxslt does (an intermediate indeterminate
      result fails the whole sum). An empty node-set or any invalid duration
      yields ''.
  -->
  <xsl:function name="date:sum" as="xs:string">
    <xsl:param name="node-set" as="node()*"/>
    <xsl:choose>
      <xsl:when test="empty($node-set)">
        <xsl:sequence select="''"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="total" as="map(*)?"
                      select="date:_sum-fold($node-set, map { 'months': 0, 'days': 0, 'seconds': 0 })"/>
        <xsl:sequence select="if (exists($total)) then
                                date:_format-duration($total?months, $total?days, $total?seconds)
                              else ''"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Left fold of _exsltDateAddDurCalc over the node-set; () aborts. -->
  <xsl:function name="date:_sum-fold" as="map(*)?">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:param name="total" as="map(*)"/>
    <xsl:choose>
      <xsl:when test="empty($nodes)">
        <xsl:sequence select="$total"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="d" as="map(*)?" select="date:_parse-duration(string($nodes[1]))"/>
        <xsl:variable name="next" as="map(*)?"
                      select="if (exists($d)) then date:_add-durations($total, $d) else ()"/>
        <xsl:sequence select="if (exists($next)) then
                                date:_sum-fold($nodes[position() gt 1], $next)
                              else ()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
