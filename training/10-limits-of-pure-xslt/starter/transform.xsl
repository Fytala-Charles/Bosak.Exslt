<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Training session 10 (starter — replace with your name)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 10 exercise — a safe operation dispatcher
                   (registry of function items + fold-left summary), the pure
                   XSLT answer to the use case behind dyn:evaluate. Self-contained:
                   includes nothing from src/ (see the golden rule in
                   training/README.md).
  SPECIAL NOTES  : The starter compiles and runs but its output does not match
                   case/expected.xml — the training test Starter_differs_from_golden
                   must pass.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:calc="urn:fytala:training:10:calc"
                exclude-result-prefixes="xs calc"
                version="3.0">

  <xsl:template match="requests">
    <report>
      <xsl:for-each select="calc">
        <calc op="{@op}" a="{@a}" b="{@b}">
          <result>
            <xsl:value-of select="calc:eval(string(@op), xs:integer(@a), xs:integer(@b))"/>
          </result>
        </calc>
      </xsl:for-each>
      <!--
          NAIVE: a second, hand-synced copy of the dispatch logic. It counts
          every row as evaluated and totals number() of whatever eval()
          returned — so an op that slipped past the chain breaks the total,
          and the two copies of the op list have already drifted.
      -->
      <summary evaluated="{count(calc)}"
               rejected="0"
               total="{sum(calc ! number(calc:eval(string(@op), xs:integer(@a), xs:integer(@b))))}"/>
      <rejected/>
    </report>
  </xsl:template>

  <!--
      EXERCISE (see README section 4): NAIVE — a string-dispatch if/else-if
      chain. The op table lives here, inline; the summary above carries a
      hand-maintained second copy. Worse, the final else echoes the op NAME
      for anything unrecognised, so a typo silently becomes "data" and the
      caller cannot tell a result from a rejection.
  -->
  <xsl:function name="calc:eval" as="xs:string">
    <xsl:param name="op" as="xs:string"/>
    <xsl:param name="a" as="xs:integer"/>
    <xsl:param name="b" as="xs:integer"/>
    <xsl:sequence select="if ($op eq 'add') then string($a + $b)
                          else if ($op eq 'sub') then string($a - $b)
                          else if ($op eq 'mul') then string($a * $b)
                          else if ($op eq 'div') then string($a idiv $b)
                          else if ($op eq 'mod') then string($a mod $b)
                          else $op"/>
  </xsl:function>

</xsl:stylesheet>
