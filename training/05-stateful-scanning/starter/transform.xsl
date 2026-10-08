<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Training session 05 (starter — replace with your name)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 05 exercise — implement the left-to-right
                   scanner behind str:replace. Self-contained: includes nothing
                   from src/ (see the golden rule in training/README.md).
  SPECIAL NOTES  : The starter compiles and runs but its output does not match
                   case/expected.xml — the training test Starter_differs_from_golden must pass.
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

  <!--
      Given for the exercise — study, do not change.
      EXSLT str:replace returns a result-tree TEXT NODE, not a bare string:
      legacy call sites run path steps on the result (e.g. $result/self::text()).
      Running the scan inside a variable builds that text node, and
      $result/text() returns it. See README section 3.
  -->
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
      EXERCISE (see README sections 4-5): NAIVE — applies each rule in turn
      with fn:replace. Two flaws: replacement text is RE-SCANNED by later
      rules, and rule order — not match position — decides what happens where
      rules overlap. Rewrite as one left-to-right scan.
  -->
  <xsl:function name="str:replace-scan" as="xs:string">
    <xsl:param name="remaining" as="xs:string"/>
    <xsl:param name="search" as="xs:string*"/>
    <xsl:param name="replace" as="xs:string*"/>
    <xsl:sequence select="if (empty($search)) then $remaining
                          else str:replace-scan(replace($remaining, $search[1], $replace[1]),
                                                $search[position() gt 1],
                                                $replace[position() gt 1])"/>
  </xsl:function>

</xsl:stylesheet>
