<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Fytala (training reference solution)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 05 reference solution — the completed starter.
                   Compare with your own attempt BEFORE reading this file
                   (see training/05-stateful-scanning/README.md section 7, which
                   also points at the library implementation in src/strings.xsl).
  SPECIAL NOTES  : Self-contained: includes nothing from src/ (golden rule in
                   training/README.md).
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:str="http://exslt.org/strings"
                exclude-result-prefixes="xs str"
                version="3.0">

  <xsl:template match="data">
    <result>
      <overlap><xsl:value-of select="str:replace(overlap, rules/rule/@from, rules/rule/@to)"/></overlap>
      <pairwise><xsl:value-of select="str:replace(pairwise, rules/rule/@from, rules/rule/@to)"/></pairwise>
      <rescan><xsl:value-of select="str:replace(rescan, rules/rule/@from, rules/rule/@to)"/></rescan>
    </result>
  </xsl:template>

  <!-- The scan runs inside a variable so the caller gets a real text node,
       per the EXSLT result-tree contract (see README section 3). -->
  <xsl:function name="str:replace" as="text()">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="search" as="xs:string*"/>
    <xsl:param name="replace" as="xs:string*"/>
    <xsl:variable name="result">
      <xsl:sequence select="str:replace-scan($input, $search, $replace)"/>
    </xsl:variable>
    <xsl:sequence select="$result/text()"/>
  </xsl:function>

  <!--
      One left-to-right pass. Each round asks every rule where it would match
      in what is left, picks the EARLIEST position (ties: the rule that comes
      first in document order), emits the literal text before the match plus
      the replacement, and recurses past the match. Emitted replacement text
      is never scanned again, and a rule with no paired replacement (or no
      match at all) contributes nothing. The empty-search-string case inserts
      its replacement between characters, matching the libxslt reference.
  -->
  <xsl:function name="str:replace-scan" as="xs:string">
    <xsl:param name="remaining" as="xs:string"/>
    <xsl:param name="search" as="xs:string*"/>
    <xsl:param name="replace" as="xs:string*"/>
    <!-- Every candidate carries its rule index, so non-matching rules cannot
         shift the positional pairing between $search and $replace. -->
    <xsl:variable name="candidates" as="map(*)*"
      select="for $j in 1 to count($search)
              return (if ($search[$j] eq '') then
                        (if (string-length($remaining) ge 2) then map { 'i': $j, 'pos': 2 } else ())
                      else if (contains($remaining, $search[$j])) then
                        map { 'i': $j,
                              'pos': string-length(substring-before($remaining, $search[$j])) + 1 }
                      else ())"/>
    <xsl:choose>
      <xsl:when test="empty($candidates)">
        <xsl:sequence select="$remaining"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="first-pos" as="xs:integer" select="min($candidates ! (?pos))"/>
        <!-- Same position: the earliest rule in document order wins. -->
        <xsl:variable name="chosen" as="map(*)" select="($candidates[?pos eq $first-pos])[1]"/>
        <xsl:variable name="i" as="xs:integer" select="$chosen?i"/>
        <xsl:variable name="replacement" as="xs:string"
                      select="if (count($replace) ge $i) then $replace[$i] else ''"/>
        <xsl:sequence select="concat(substring($remaining, 1, $first-pos - 1),
                                     $replacement,
                                     str:replace-scan(substring($remaining, $first-pos + string-length($search[$i])),
                                                      $search, $replace))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
