<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : XSLT 3.0 package descriptor for the EXSLT dates-and-times
                   module (http://exslt.org/dates-and-times): the full public
                   date:* surface (add, add-duration, date, date-time, date
                   component extraction, difference, duration, leap-year,
                   seconds, sum, time, week-in-year and year).
  SPECIAL NOTES  : REQ-003. Wraps the plain module ../dates-and-times.xsl via
                   xsl:include — the plain file stays the primary artifact; this
                   descriptor only exposes the public EXSLT names for
                   xsl:use-package consumption (the date:_* internals are exposed
                   public — DEVIATION: the engine resolves intra-package helper
                   calls against the exposed component table filtered to public
                   visibility, so private exposure leaves them unfindable; they
                   remain implementation details, not EXSLT surface). Requires
                   host registration via
                   Bosak.Xslt.Api.XsltFunctionLibrary.RegisterPackage (the XSLT
                   spec leaves package location resolution implementation-defined).
  CHANGE HISTORY : 2026-10-08 | 1.0 | REQ-003 creation.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:package name="urn:fytala:exslt:date"
             package-version="1.0.0"
             xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
             xmlns:date="http://exslt.org/dates-and-times"
             version="3.0">

  <xsl:expose component="function"
              names="date:add date:add-duration date:date date:date-time date:day-abbreviation date:day-in-month date:day-in-week date:day-in-year date:day-name date:day-of-week-in-month date:difference date:duration date:hour-in-day date:leap-year date:minute-in-hour date:month-abbreviation date:month-in-year date:month-name date:second-in-minute date:seconds date:sum date:time date:week-in-year date:year"
              visibility="public"/>

  <!-- Internal date:_* helpers. DEVIATION: these are exposed public, not
       private — the engine resolves intra-package helper calls against the
       exposed component table filtered to public visibility, so private
       exposure leaves the helpers unfindable (XPST0017) and the public
       date:* functions cannot run. Using packages should treat date:_*
       names as implementation details; they are not part of the EXSLT
       surface. -->
  <xsl:expose component="function"
              names="date:_add-durations date:_add-to-date date:_build date:_cast-ym-to-days date:_day-in-week0 date:_day-in-year date:_days-in-month date:_difference date:_format-date date:_format-duration date:_format-number date:_format-time-of-day date:_format-year date:_is-leap date:_leap-count date:_normalize-day date:_parse date:_parse-duration date:_specificity date:_sum-fold date:_truncate date:_week-in-year"
              visibility="public"/>

  <xsl:include href="../dates-and-times.xsl"/>

</xsl:package>
