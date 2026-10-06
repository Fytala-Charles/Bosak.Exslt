<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 06 October 2026
  PURPOSE        : EXSLT sets module (http://exslt.org/sets): intersection,
                   difference, distinct, has-same-node, leading and trailing.
  SPECIAL NOTES  : Tier 1 (wrappers): intersection, difference, has-same-node.
                   Tier 2 (genuine): distinct, leading, trailing. leading/trailing
                   reproduce the libxml2 reference rule (leader node must be a
                   member of the first node set) — see docs/COMPATIBILITY.md.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:set="http://exslt.org/sets"
                exclude-result-prefixes="xs"
                version="3.0">

  <!-- Tier 1 — wrapper over the XPath 3.1 "intersect" operator. -->
  <xsl:function name="set:intersection" as="node()*">
    <xsl:param name="node-set1" as="node()*"/>
    <xsl:param name="node-set2" as="node()*"/>
    <xsl:sequence select="$node-set1[. intersect $node-set2]"/>
  </xsl:function>

  <!-- Tier 1 — wrapper over the XPath 3.1 "except" operator. -->
  <xsl:function name="set:difference" as="node()*">
    <xsl:param name="node-set1" as="node()*"/>
    <xsl:param name="node-set2" as="node()*"/>
    <xsl:sequence select="$node-set1 except $node-set2"/>
  </xsl:function>

  <!--
      Tier 1 — wrapper over node identity.
      True when the two node sequences share at least one node (same identity,
      tested with "is"), irrespective of duplicates or ordering.
  -->
  <xsl:function name="set:has-same-node" as="xs:boolean">
    <xsl:param name="node-set1" as="node()*"/>
    <xsl:param name="node-set2" as="node()*"/>
    <xsl:sequence select="some $a in $node-set1, $b in $node-set2 satisfies $a is $b"/>
  </xsl:function>

  <!--
      Tier 2 — genuine implementation.

      Returns the nodes in the input whose string values are distinct, in document
      order; where several nodes share a string value the one that comes first in
      document order is kept.
  -->
  <xsl:function name="set:distinct" as="node()*">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="$nodes[not(some $other in $nodes
                                     satisfies ($other &lt;&lt; . and string($other) eq string(.)))]"/>
  </xsl:function>

  <!--
      Tier 2 — genuine implementation.

      Returns the nodes in $node-set1 that precede, in document order, the first
      node of $node-set2. Reproduces the libxml2 reference behavior
      (xmlXPathNodeLeadingSorted): the result is empty unless that leading node is
      itself a member of $node-set1, and an empty $node-set2 yields $node-set1
      unchanged.
  -->
  <xsl:function name="set:leading" as="node()*">
    <xsl:param name="node-set1" as="node()*"/>
    <xsl:param name="node-set2" as="node()*"/>
    <xsl:choose>
      <xsl:when test="empty($node-set2)">
        <xsl:sequence select="$node-set1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="leader" as="node()"
                      select="$node-set2[not(some $other in $node-set2 satisfies $other &lt;&lt; .)]"/>
        <xsl:sequence select="if ($leader intersect $node-set1) then $node-set1[. &lt;&lt; $leader] else ()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--
      Tier 2 — genuine implementation.

      Symmetric to set:leading: returns the nodes in $node-set1 that follow, in
      document order, the last node of $node-set2. The same libxml2 containment
      rule applies (the trailing node must be a member of $node-set1), and an empty
      $node-set2 yields $node-set1 unchanged.
  -->
  <xsl:function name="set:trailing" as="node()*">
    <xsl:param name="node-set1" as="node()*"/>
    <xsl:param name="node-set2" as="node()*"/>
    <xsl:choose>
      <xsl:when test="empty($node-set2)">
        <xsl:sequence select="$node-set1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="trailer" as="node()"
                      select="$node-set2[not(some $other in $node-set2 satisfies . &lt;&lt; $other)]"/>
        <xsl:sequence select="if ($trailer intersect $node-set1) then $node-set1[$trailer &lt;&lt; .] else ()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
