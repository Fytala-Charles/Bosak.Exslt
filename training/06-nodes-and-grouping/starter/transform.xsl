<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Training session 06 (starter — replace with your name)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 06 exercise — set:has-same-node (exercise 1),
                   set:distinct (exercise 2) and set:difference (exercise 3).
                   Self-contained: includes nothing from src/ (see the golden rule
                   in training/README.md).
  SPECIAL NOTES  : The starter compiles and runs but its output does not match
                   case/expected.xml — the training test Starter_differs_from_golden must pass.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:set="http://exslt.org/sets"
                exclude-result-prefixes="xs set"
                version="3.0">

  <xsl:template match="inventory">
    <result>
      <cross-shelf><xsl:value-of select="set:has-same-node(shelf[@id eq 'a']/item, shelf[@id eq 'b']/item)"/></cross-shelf>
      <overlap><xsl:value-of select="set:has-same-node(shelf[@id eq 'a']/item, shelf[@id eq 'a']/item[1] | shelf[@id eq 'b']/item)"/></overlap>
      <distinct>
        <xsl:sequence select="set:distinct(shelf/item)"/>
      </distinct>
      <a-minus-b>
        <xsl:sequence select="set:difference(shelf[@id eq 'a']/item, shelf[@id eq 'b']/item)"/>
      </a-minus-b>
      <all-minus-a>
        <xsl:sequence select="set:difference(shelf/item, shelf[@id eq 'a']/item)"/>
      </all-minus-a>
    </result>
  </xsl:template>

  <!--
      EXERCISE 1 (see README section 4): NAIVE — '=' compares node VALUES, so
      any two elements holding equal text count as "the same". The two shelves
      share no element, yet this returns true for them. Identity needs 'is'.
  -->
  <xsl:function name="set:has-same-node" as="xs:boolean">
    <xsl:param name="node-set1" as="node()*"/>
    <xsl:param name="node-set2" as="node()*"/>
    <xsl:sequence select="some $a in $node-set1, $b in $node-set2 satisfies $a = $b"/>
  </xsl:function>

  <!--
      EXERCISE 2 (see README section 5): NAIVE — distinct-values returns the
      distinct VALUES as strings (note the return type). EXSLT set:distinct
      must return NODES — the first, in document order, among the nodes whose
      string values are equal — so callers keep positions and attributes.
  -->
  <xsl:function name="set:distinct" as="xs:string*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="distinct-values($nodes)"/>
  </xsl:function>

  <!--
      EXERCISE 3 (see README section 6): NAIVE — a value comparison keeps only
      nodes whose VALUE occurs nowhere in $node-set2. Value-equal elements in
      the other shelf are still different nodes; EXSLT difference is by IDENTITY.
  -->
  <xsl:function name="set:difference" as="node()*">
    <xsl:param name="node-set1" as="node()*"/>
    <xsl:param name="node-set2" as="node()*"/>
    <xsl:sequence select="$node-set1[not(. = $node-set2)]"/>
  </xsl:function>

</xsl:stylesheet>
