<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Fytala (training reference solution — capstone rehearsal)
  CREATE DATE    : 06 October 2026
  PURPOSE        : EXSLT strings module addition (capstone rehearsal):
                   str:repeat($input, $count) — repeat a string a given
                   number of times. Self-contained stand-in for the real
                   contribution, which would land in src/strings.xsl.
  SPECIAL NOTES  : Proposed function: no upstream EXSLT spec or libxslt
                   reference exists, so the semantics are the proposal's
                   contract (README section 2): repeat $input $count times;
                   '' for absent, non-integer, or negative $count and for
                   empty $input. Tier 2 (genuine implementation, one
                   tail-recursive worker — session 03's pattern). Hand-written
                   golden pins the contract; see the session's case/meta.json.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
  CHANGE HISTORY : |==================|=========|============|========================
                   | Author           | Version | Date       | Notes
                   |==================|=========|============|========================
                   | Fytala           | 1.0.0   | 2026-10-06 | str:repeat proposal:
                   |                  |         |            | golden case first, then
                   |                  |         |            | this implementation
                   |==================|=========|============|========================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:str="http://exslt.org/strings"
                exclude-result-prefixes="xs str"
                version="3.0">

  <xsl:template match="requests">
    <report>
      <xsl:for-each select="repeat">
        <repeat input="{@input}" count="{@count}">
          <result>
            <xsl:value-of select="str:repeat(@input, @count)"/>
          </result>
        </repeat>
      </xsl:for-each>
    </report>
  </xsl:template>

  <!--
      Tier 2 — genuine implementation.

      Purpose: repeat $input $count times and return the concatenation.
      Parameters: $input (xs:string?, the string to repeat), $count (xs:string?,
      lexical integer — kept as string so invalid input is data, not an
      exception). Returns xs:string.
      Edge posture: absent $input or $count, a $count that is not an integer,
      or a negative $count all yield '' (the EXSLT convention for string
      functions: invalid input is data). $count = 0 yields ''. Semantics are
      the proposal's own contract — there is no upstream reference to diverge
      from, so no divergence entry applies (see tests/ATTRIBUTION.md rules).
  -->
  <xsl:function name="str:repeat" as="xs:string">
    <xsl:param name="input" as="xs:string?"/>
    <xsl:param name="count" as="xs:string?"/>
    <xsl:sequence select="if (not($input) or not($count)
                              or not(normalize-space($count) castable as xs:integer)
                              or xs:integer(normalize-space($count)) lt 0) then ''
                          else str:_repeat(xs:integer(normalize-space($count)), $input, '')"/>
  </xsl:function>

  <!--
      Tail-recursive worker (session 03's loop shape): $built carries the
      string so far; $remaining counts down. Invariant: returns $built with
      $input appended $remaining more times.
  -->
  <xsl:function name="str:_repeat" as="xs:string">
    <xsl:param name="remaining" as="xs:integer"/>
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="built" as="xs:string"/>
    <xsl:sequence select="if ($remaining eq 0) then $built
                          else str:_repeat($remaining - 1, $input, $built || $input)"/>
  </xsl:function>

</xsl:stylesheet>
