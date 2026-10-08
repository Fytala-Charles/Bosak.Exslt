<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Training session 08 (starter — replace with your name)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 08 exercise — date:year (exercise 1, which also
                   builds the shared lenient parser date:_as-datetime), date:leap-year
                   (exercise 2) and date:month-name (exercise 3). Self-contained:
                   includes nothing from src/ (see the golden rule in training/README.md).
  SPECIAL NOTES  : The starter compiles and runs but its output does not match
                   case/expected.xml — the training test Starter_differs_from_golden must pass.
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
      EXERCISE 1 (see README section 4): NAIVE — strict casting. Only full
      xs:dateTime and xs:date spellings parse; a bare year like "2026" is a
      perfectly good EXSLT date (gYear) but gets NaN here, and the strict
      ladder has nowhere shared for exercises 2 and 3 to build on.
  -->
  <xsl:function name="date:year" as="xs:double">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (not($date-time)) then xs:double('NaN')
                          else if (normalize-space($date-time) castable as xs:dateTime)
                               then xs:double(year-from-dateTime(xs:dateTime(normalize-space($date-time))))
                          else if (normalize-space($date-time) castable as xs:date)
                               then xs:double(year-from-date(xs:date(normalize-space($date-time))))
                          else xs:double('NaN')"/>
  </xsl:function>

  <!--
      EXERCISE 2 (see README section 5): NAIVE — "divisible by 4" only, the
      rule every programmer misremembers. 1900 is NOT a leap year (century
      rule); 2000 IS (400-year rule). Pair with the shared parser once
      exercise 1 builds it.
  -->
  <xsl:function name="date:leap-year" as="xs:boolean">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (normalize-space($date-time) castable as xs:dateTime)
                            then (year-from-dateTime(xs:dateTime(normalize-space($date-time))) mod 4) eq 0
                          else if (normalize-space($date-time) castable as xs:date)
                            then (year-from-date(xs:date(normalize-space($date-time))) mod 4) eq 0
                          else false()"/>
  </xsl:function>

  <!--
      EXERCISE 3 (see README section 6): NAIVE — a hand-rolled name list with
      a deliberate one-position indexing slip (and strict xs:date casting, so
      full dateTimes get nothing). Replace with the real formatting route.
  -->
  <xsl:function name="date:month-name" as="xs:string">
    <xsl:param name="date-time" as="xs:string?"/>
    <xsl:sequence select="if (normalize-space($date-time) castable as xs:date) then
                            string(tokenize('January February March April May June July August September October November December', ' ')
                                   [month-from-date(xs:date(normalize-space($date-time))) + 1])
                          else ''"/>
  </xsl:function>

</xsl:stylesheet>
