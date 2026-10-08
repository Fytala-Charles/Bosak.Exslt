<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : XSLT 3.0 package descriptor for the EXSLT math module
                   (http://exslt.org/math): min, max, highest, lowest, sqrt,
                   power, constant, log, sin, cos, tan, asin, acos, atan,
                   atan2 and exp.
  SPECIAL NOTES  : REQ-003. Wraps the plain module ../math.xsl via xsl:include —
                   the plain file stays the primary artifact; this descriptor only
                   exposes the public EXSLT names for xsl:use-package consumption.
                   Requires host registration via
                   Bosak.Xslt.Api.XsltFunctionLibrary.RegisterPackage (the XSLT
                   spec leaves package location resolution implementation-defined).
  CHANGE HISTORY : 2026-10-08 | 1.0 | REQ-003 creation.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:package name="urn:fytala:exslt:math"
             package-version="1.0.0"
             xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
             xmlns:math="http://exslt.org/math"
             version="3.0">

  <xsl:expose component="function"
              names="math:min math:max math:highest math:lowest math:sqrt math:power math:constant math:log math:sin math:cos math:tan math:asin math:acos math:atan math:atan2 math:exp"
              visibility="public"/>

  <xsl:include href="../math.xsl"/>

</xsl:package>
