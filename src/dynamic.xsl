<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 06 October 2026
  PURPOSE        : EXSLT dynamic module (http://exslt.org/dynamic): dynamic XPath
                   evaluation slots.
  SPECIAL NOTES  : Tier 3 (documented only). Dynamic XPath evaluation cannot be
                   implemented in pure XSLT 3.0; the function slots below raise a
                   terminating xsl:message rather than a fake implementation.
                   See docs/COMPATIBILITY.md and ROADMAP.md (repository root) for
                   the engine support decision (xsl:evaluate / native extension).
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:dyn="http://exslt.org/dynamic"
                exclude-result-prefixes="xs"
                version="3.0">

  <!--
      Tier 3 — requires engine support.

      Evaluates a string as an XPath expression at run time. No conformant pure
      XSLT 3.0 implementation is possible: the stylesheet author would have to
      ship an XPath evaluator written in XSLT. The slot therefore terminates the
      transformation with a clear message.

      Migration paths:
      - xsl:evaluate (XSLT 3.0) supersedes dyn:evaluate once the host engine
        supports it;
      - a Bosak native/commercial extension function is the tracked alternative
        (REQ-121, ROADMAP.md at the repository root).
  -->
  <xsl:function name="dyn:evaluate" as="item()*">
    <xsl:param name="expression" as="xs:string"/>
    <xsl:message terminate="yes"
      select="'Bosak.Exslt: dyn:evaluate() requires dynamic XPath evaluation, which pure XSLT 3.0 cannot provide. ' ||
              'Use xsl:evaluate (XSLT 3.0) or a Bosak engine extension instead. ' ||
              'See docs/COMPATIBILITY.md and ROADMAP.md (repository root).'"/>
    <xsl:sequence select="()"/>
  </xsl:function>

  <!-- Two-argument form: evaluate with a context node. Same engine-support slot. -->
  <xsl:function name="dyn:evaluate" as="item()*">
    <xsl:param name="expression" as="xs:string"/>
    <xsl:param name="context" as="node()?"/>
    <xsl:sequence select="dyn:evaluate($expression)"/>
  </xsl:function>

</xsl:stylesheet>
