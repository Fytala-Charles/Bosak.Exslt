<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Fytala (training reference solution)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 06 reference solution — the completed starter.
                   Compare with your own attempt BEFORE reading this file
                   (see training/06-nodes-and-grouping/README.md section 8, which
                   also points at the library implementation in src/sets.xsl).
  SPECIAL NOTES  : Self-contained: includes nothing from src/ (golden rule in
                   training/README.md).
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

  <!-- True when the two node sets share at least one node — same identity,
       tested with 'is' — irrespective of duplicates or ordering. -->
  <xsl:function name="set:has-same-node" as="xs:boolean">
    <xsl:param name="node-set1" as="node()*"/>
    <xsl:param name="node-set2" as="node()*"/>
    <xsl:sequence select="some $a in $node-set1, $b in $node-set2 satisfies $a is $b"/>
  </xsl:function>

  <!--
      The nodes whose string values are distinct, in document order; where
      several nodes share a string value, the one first in document order is
      kept. A node is kept when NO other node both precedes it ('<<') and has
      an equal string value — the predicate keeps the firsts of each
      value-group and drops the rest.
  -->
  <xsl:function name="set:distinct" as="node()*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="$nodes[not(some $other in $nodes
                                     satisfies ($other &lt;&lt; . and string($other) eq string(.)))]"/>
  </xsl:function>

  <!-- The nodes of $node-set1 that are NOT in $node-set2, by identity —
       exactly the 'except' operator. -->
  <xsl:function name="set:difference" as="node()*">
    <xsl:param name="node-set1" as="node()*"/>
    <xsl:param name="node-set2" as="node()*"/>
    <xsl:sequence select="$node-set1 except $node-set2"/>
  </xsl:function>

</xsl:stylesheet>
