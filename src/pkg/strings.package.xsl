<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 08 October 2026
  PURPOSE        : XSLT 3.0 package descriptor for the EXSLT strings module
                   (http://exslt.org/strings): tokenize, split, replace, padding,
                   align, encode-uri and decode-uri.
  SPECIAL NOTES  : REQ-003. Wraps the plain module ../strings.xsl via xsl:include —
                   the plain file stays the primary artifact; this descriptor only
                   exposes the public EXSLT names for xsl:use-package consumption
                   (the str:replace-scan / str:make-tokens / str:utf8-* /
                   str:is-hex-pair / str:hex-to-codepoint / str:restore-uri-marks /
                   str:escape-run-length internals are exposed public — DEVIATION:
                   the engine resolves intra-package helper calls against the
                   exposed component table filtered to public visibility, so
                   private exposure leaves them unfindable; they remain
                   implementation details, not EXSLT surface). Requires host
                   registration via Bosak.Xslt.Api.XsltFunctionLibrary.RegisterPackage
                   (the XSLT spec leaves package location resolution
                   implementation-defined).
  CHANGE HISTORY : 2026-10-08 | 1.0 | REQ-003 creation.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:package name="urn:fytala:exslt:strings"
             package-version="1.0.0"
             xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
             xmlns:str="http://exslt.org/strings"
             version="3.0">

  <xsl:expose component="function"
              names="str:tokenize str:split str:replace str:padding str:align str:encode-uri str:decode-uri"
              visibility="public"/>

  <!-- Internal helpers. DEVIATION: these are exposed public, not private — the
       engine resolves intra-package helper calls against the exposed component
       table filtered to public visibility, so private exposure leaves the
       helpers unfindable (XPST0017) and str:tokenize/split/replace/encode-uri/
       decode-uri cannot run. Using packages should treat str:* helpers as
       implementation details; they are not part of the EXSLT surface. -->
  <xsl:expose component="function"
              names="str:replace-scan str:make-tokens str:restore-uri-marks str:escape-run-length str:utf8-decode str:utf8-accumulate str:is-hex-pair str:hex-to-codepoint"
              visibility="public"/>

  <xsl:include href="../strings.xsl"/>

</xsl:package>
