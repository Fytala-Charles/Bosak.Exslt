<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Fytala (training reference solution)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 10 reference solution — the safe operation
                   dispatcher: a registry mapping op-names to function items,
                   guarded lookup, and a fold-left/filter/for-each summary
                   pipeline. This is the pure-XSLT answer to the use case that
                   motivates dyn:evaluate for KNOWN operations.
                   Compare with your own attempt BEFORE reading this file
                   (see training/10-limits-of-pure-xslt/README.md section 6,
                   which also shows the tier-3 dyn:evaluate slot in
                   src/dynamic.xsl).
  SPECIAL NOTES  : Self-contained: includes nothing from src/ (golden rule in
                   training/README.md). Every construct used here (anonymous
                   functions, named function references, function items in maps,
                   for-each/filter/fold-left, function items as parameters) was
                   empirically verified on Bosak 0.12.3-beta before authoring
                   (see README section 4). One verified quirk matters here:
                   calling the empty sequence (a missing map key lookup) as a
                   function raises XPTY0004 — hence the map:contains guard.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:calc="urn:fytala:training:10:calc"
                exclude-result-prefixes="xs map calc"
                version="3.0">

  <xsl:template match="requests">
    <xsl:variable name="summary" as="map(*)" select="calc:summary(calc)"/>
    <report>
      <xsl:for-each select="calc">
        <calc op="{@op}" a="{@a}" b="{@b}">
          <xsl:choose>
            <xsl:when test="map:contains(calc:ops(), string(@op))">
              <result>
                <xsl:value-of select="calc:ops()(string(@op))(xs:integer(@a), xs:integer(@b))"/>
              </result>
            </xsl:when>
            <xsl:otherwise>
              <rejected/>
            </xsl:otherwise>
          </xsl:choose>
        </calc>
      </xsl:for-each>
      <summary evaluated="{$summary?evaluated}"
               rejected="{$summary?rejected}"
               total="{$summary?total}"/>
      <rejected>
        <xsl:value-of select="for-each(
                                filter(calc, function($r) { not(map:contains(calc:ops(), string($r/@op))) }),
                                function($r) { string($r/@op) })"
                      separator=","/>
      </rejected>
    </report>
  </xsl:template>

  <!--
      The registry: op-name -> function item. 'max' is a NAMED function
      reference (calc:max2#2); the rest are anonymous functions. Adding an op
      is one line here and zero lines anywhere else — the dispatch table has
      exactly one copy. 'div' is integer division (idiv) so every op returns
      xs:integer.
  -->
  <xsl:function name="calc:ops" as="map(*)">
    <xsl:sequence select="map {
        'add': function($a, $b) { $a + $b },
        'sub': function($a, $b) { $a - $b },
        'mul': function($a, $b) { $a * $b },
        'div': function($a, $b) { $a idiv $b },
        'mod': function($a, $b) { $a mod $b },
        'max': calc:max2#2
      }"/>
  </xsl:function>

  <!-- Named function, referenced from the registry by calc:max2#2. -->
  <xsl:function name="calc:max2" as="xs:integer">
    <xsl:param name="a" as="xs:integer"/>
    <xsl:param name="b" as="xs:integer"/>
    <xsl:sequence select="max(($a, $b))"/>
  </xsl:function>

  <!--
      The summary pipeline: one fold-left over the requests carrying a map
      accumulator { evaluated, rejected, total }. The dispatch decision is
      made in exactly one place (map:contains against calc:ops), so the
      counts and the total can never drift apart from the per-row results.
  -->
  <xsl:function name="calc:summary" as="map(*)">
    <xsl:param name="requests" as="element(calc)*"/>
    <xsl:sequence select="fold-left(
                            $requests,
                            map { 'evaluated': 0, 'rejected': 0, 'total': 0 },
                            function($acc, $r) {
                              if (map:contains(calc:ops(), string($r/@op))) then
                                map { 'evaluated': $acc?evaluated + 1,
                                      'rejected': $acc?rejected,
                                      'total': $acc?total + calc:ops()(string($r/@op))(xs:integer($r/@a), xs:integer($r/@b)) }
                              else
                                map { 'evaluated': $acc?evaluated,
                                      'rejected': $acc?rejected + 1,
                                      'total': $acc?total }
                            })"/>
  </xsl:function>

</xsl:stylesheet>
