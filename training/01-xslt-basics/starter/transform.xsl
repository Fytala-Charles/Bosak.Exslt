<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Training session 01 (starter — replace with your name)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 01 exercise — XSLT basics: turn <team> into the
                   golden <roster> document using a template rule, xsl:for-each,
                   xsl:value-of, and an attribute value template. Self-contained:
                   includes nothing from src/ (see the golden rule in training/README.md).
  SPECIAL NOTES  : The starter compiles and runs but its output does not match
                   case/expected.xml — the training test Starter_differs_from_golden
                   must pass.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="3.0">

  <!--
      The rule fires for <team>. Inside the body, '.' is the team element and
      'member' selects its member children.
      EXERCISE: replace TODO with an attribute value template that counts the
      members, and fill the roster with one <name> per member (README hints).
  -->
  <xsl:template match="team">
    <roster count="TODO">
      <!-- EXERCISE: one <name> per member, holding the member's text -->
    </roster>
  </xsl:template>

</xsl:stylesheet>
