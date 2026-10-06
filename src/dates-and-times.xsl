<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 06 October 2026
  PURPOSE        : EXSLT dates-and-times module (http://exslt.org/dates-and-times):
                   component extraction, formatting, duration arithmetic and
                   summation over ISO 8601 dates and times.
  SPECIAL NOTES  : Entirely tier 2 (genuine implementations). Built on xs:dateTime
                   parsing, XPath 3.1 date arithmetic and format-dateTime.
                   Invalid input yields NaN or '' per the EXSLT contract. Known
                   divergences from the libxslt reference are recorded in
                   docs/COMPATIBILITY.md.
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
       Private helpers
       ====================================================================== -->

  <!--
      Parses an ISO 8601 lexical form (dateTime, date, gYearMonth, gYear,
      gMonthDay, gDay, gMonth or time) into an xs:dateTime. Time-only forms are
      anchored at 1972-01-01 (a leap year, as in the libxslt reference); month/day
      forms are anchored at 1972. Raises a dynamic error on unparseable input —
      callers convert that to NaN/'' per the EXSLT contract.
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

  <!--
      Parses an xs:duration lexical form into a map with keys neg (xs:boolean),
      months (xs:integer), days (xs:integer) and seconds (xs:decimal). Returns the
      empty sequence when the string is not a valid duration.
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
      Formats duration components in the EXSLT/libxslt canonical form: only
      non-zero components are emitted, seconds carry into days, months carry into
      years, and a completely zero duration formats as "P0D". $months must already
      be normalized to any integer (years are derived), $seconds must satisfy
      0 le $seconds lt 86400 after day extraction by the caller.
  -->
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

  <!-- Normalizes a possibly signed seconds total into days + in-day seconds. -->
  <xsl:function name="date:_split-seconds" as="map(*)">
    <xsl:param name="total" as="xs:decimal"/>
    <xsl:variable name="days" as="xs:integer" select="xs:integer(floor($total div 86400))"/>
    <xsl:sequence select="map { 'days': $days, 'seconds': $total - 86400 * $days }"/>
  </xsl:function>

  <!-- ======================================================================
       Current date and time
       ====================================================================== -->

  <!-- Returns the current date and time as YYYY-MM-DDThh:mm:ss. -->
  <xsl:function name="date:date-time" as="xs:string">
    <xsl:sequence select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')"/>
  </xsl:function>

  <!-- Returns the date portion (YYYY-MM-DD) of the argument, or of today. -->
  <xsl:function name="date:date" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then
                            format-date(current-date(), '[Y0001]-[M01]-[D01]')
                          else (try {
                                  if (normalize-space($date-time) castable as xs:date
                                      or normalize-space($date-time) castable as xs:dateTime) then
                                    format-date(date:_as-datetime($date-time), '[Y0001]-[M01]-[D01]')
                                  else ''
                                } catch * { '' })"/>
  </xsl:function>

  <!-- Returns the time portion (hh:mm:ss) of the argument, or of now. -->
  <xsl:function name="date:time" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then
                            format-time(current-time(), '[H01]:[m01]:[s01]')
                          else (try {
                                  if (normalize-space($date-time) castable as xs:time
                                      or normalize-space($date-time) castable as xs:dateTime) then
                                    format-time(xs:time(substring(string(date:_as-datetime($date-time)), 12)), '[H01]:[m01]:[s01]')
                                  else ''
                                } catch * { '' })"/>
  </xsl:function>

  <!-- ======================================================================
       Component extraction (NaN on invalid input, per EXSLT)
       ====================================================================== -->

  <!-- Returns the year of the date or dateTime as a number. -->
  <xsl:function name="date:year" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try { xs:double(year-from-dateTime(date:_as-datetime($date-time))) }
                                catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!-- Returns true when the year of the argument is a leap year. -->
  <xsl:function name="date:leap-year" as="xs:boolean">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then false()
                          else (try {
                                  let $y := year-from-dateTime(date:_as-datetime($date-time))
                                  return (($y mod 4) eq 0 and ($y mod 100) ne 0) or ($y mod 400) eq 0
                                } catch * { false() })"/>
  </xsl:function>

  <!-- Returns the month of the year (1-12) of the argument. -->
  <xsl:function name="date:month-in-year" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try { xs:double(month-from-dateTime(date:_as-datetime($date-time))) }
                                catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!-- Returns the English name of the month ('' on invalid input). -->
  <xsl:function name="date:month-name" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then ''
                          else (try { format-date(date:_as-datetime($date-time), '[MNn]') } catch * { '' })"/>
  </xsl:function>

  <!-- Returns the English month abbreviation ('' on invalid input). -->
  <xsl:function name="date:month-abbreviation" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then ''
                          else (try { format-date(date:_as-datetime($date-time), '[MNn,*-3]') } catch * { '' })"/>
  </xsl:function>

  <!-- Returns the ISO week number of the argument. -->
  <xsl:function name="date:week-in-year" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try { xs:double(format-date(date:_as-datetime($date-time), '[W]')) }
                                catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!-- Returns the day of the year (1-366) of the argument. -->
  <xsl:function name="date:day-in-year" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try { xs:double(format-date(date:_as-datetime($date-time), '[d]')) }
                                catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!-- Returns the day of the month (1-31) of the argument. -->
  <xsl:function name="date:day-in-month" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try { xs:double(day-from-dateTime(date:_as-datetime($date-time))) }
                                catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!-- Returns the ordinal week of the month of the argument (1-5). -->
  <xsl:function name="date:day-of-week-in-month" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try {
                                  xs:double((day-from-dateTime(date:_as-datetime($date-time)) - 1) idiv 7 + 1)
                                } catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!-- Returns the day of the week as a number: 1 = Sunday, ..., 7 = Saturday. -->
  <xsl:function name="date:day-in-week" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try {
                                  let $iso := day-from-dateTime(date:_as-datetime($date-time))
                                  return xs:double(($iso mod 7) + 1)
                                } catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!-- Returns the English name of the day of the week ('' on invalid input). -->
  <xsl:function name="date:day-name" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then ''
                          else (try { format-date(date:_as-datetime($date-time), '[FNn]') } catch * { '' })"/>
  </xsl:function>

  <!-- Returns the English day abbreviation ('' on invalid input). -->
  <xsl:function name="date:day-abbreviation" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then ''
                          else (try { format-date(date:_as-datetime($date-time), '[FNn,*-3]') } catch * { '' })"/>
  </xsl:function>

  <!-- Returns the hour of the day (0-23) of the argument. -->
  <xsl:function name="date:hour-in-day" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try { xs:double(hours-from-dateTime(date:_as-datetime($date-time))) }
                                catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!-- Returns the minute of the hour (0-59) of the argument. -->
  <xsl:function name="date:minute-in-hour" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try { xs:double(minutes-from-dateTime(date:_as-datetime($date-time))) }
                                catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!-- Returns the second of the minute (0-60, allowing leap seconds) of the argument. -->
  <xsl:function name="date:second-in-minute" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try { xs:double(seconds-from-dateTime(date:_as-datetime($date-time))) }
                                catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!-- ======================================================================
       Durations
       ====================================================================== -->

  <!--
      Converts a number of seconds to a duration string (PnDTnHnMnS). Computed with
      decimal arithmetic, so fractional seconds are exact; libxslt's binary-float
      rounding of near-integer inputs is a documented divergence.
  -->
  <xsl:function name="date:duration" as="xs:string">
    <xsl:param name="seconds" as="xs:double"/>
    <xsl:variable name="total" as="xs:decimal" select="abs(xs:decimal($seconds))"/>
    <xsl:variable name="split" as="map(*)" select="date:_split-seconds($total)"/>
    <xsl:sequence select="date:_format-duration($seconds lt 0, 0, $split?days, $split?seconds)"/>
  </xsl:function>

  <!--
      Adds two durations, with libxslt's component normalization: months carry into
      years, seconds carry into days, but days never carry into months. Returns ''
      for invalid input.
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
      Adds a duration to a date or dateTime using calendar arithmetic
      (xs:dateTime + xs:duration) and returns the result as a dateTime string.
      Returns '' for invalid input. Month-end results follow the XPath 3.1 calendar
      rules, which may differ from libxslt's component arithmetic (documented in
      docs/COMPATIBILITY.md).
  -->
  <xsl:function name="date:add" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:param name="duration" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time) or not($duration)) then ''
                          else (try {
                                  format-dateTime(date:_as-datetime($date-time) + xs:duration(normalize-space($duration)),
                                                  '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')
                                } catch * { '' })"/>
  </xsl:function>

  <!--
      Returns the difference between two dates or dateTimes as a duration string.
      The exact result of xs:dateTime subtraction is a dayTimeDuration, so years and
      months cannot appear in the result (libxslt approximates them with average
      month lengths — both forms are documented in docs/COMPATIBILITY.md).
      Returns '' for invalid input.
  -->
  <xsl:function name="date:difference" as="xs:string">
    <xsl:param name="date1" as="xs:string?"/>
    <xsl:param name="date2" as="xs:string?"/>
    <xsl:sequence select="if (not($date1) or not($date2)) then ''
                          else (try {
                                  let $delta := date:_as-datetime($date2) - date:_as-datetime($date1)
                                  let $seconds := $delta div xs:dayTimeDuration('PT1S')
                                  let $split := date:_split-seconds($seconds)
                                  return date:_format-duration($seconds lt 0, 0, $split?days, abs($split?seconds))
                                } catch * { '' })"/>
  </xsl:function>

  <!--
      Returns the number of seconds represented by the argument: the total seconds
      of a duration, or the seconds since the Unix epoch of a dateTime. Returns NaN
      for anything else.
  -->
  <xsl:function name="date:seconds" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else (try {
                                  if (normalize-space($date-time) castable as xs:dayTimeDuration) then
                                    xs:double(xs:dayTimeDuration(normalize-space($date-time)) div xs:dayTimeDuration('PT1S'))
                                  else
                                    xs:double((date:_as-datetime($date-time) - xs:dateTime('1970-01-01T00:00:00Z'))
                                              div xs:dayTimeDuration('PT1S'))
                                } catch * { xs:double('NaN') })"/>
  </xsl:function>

  <!--
      Sums the durations held by a node-set (each node converted with the EXSLT
      string conversion) and returns the result as a duration string. Returns the
      string "NaN" when any node does not hold a valid duration.
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
