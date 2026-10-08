<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : XSLT 3.0 package descriptor for the EXSLT common module
                   (http://exslt.org/common): exsl:node-set and exsl:object-type.
  SPECIAL NOTES  : REQ-003. Wraps the plain module ../exsl.xsl via xsl:include —
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
<xsl:package name="urn:fytala:exslt:common"
             package-version="1.0.0"
             xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
             xmlns:exsl="http://exslt.org/common"
             version="3.0">

  <xsl:expose component="function"
              names="exsl:node-set exsl:object-type"
              visibility="public"/>

  <xsl:include href="../exsl.xsl"/>

</xsl:package>
