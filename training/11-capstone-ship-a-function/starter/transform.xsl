<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Training session 11 (starter — replace with your name)
  CREATE DATE    : 2026-10-06
  PURPOSE        : WORKFLOW START STATE (capstone rehearsal) — proposed EXSLT
                   strings function str:repeat($input, $count), not yet
                   implemented. Step 4 of training/11-capstone-ship-a-function/
                   README.md replaces the terminating slot below with the real
                   tier-2 implementation and completes this header.
                   Self-contained: includes nothing from src/ (golden rule in
                   training/README.md).
  SPECIAL NOTES  : The slot below has the tier-3 shape from src/dynamic.xsl
                   (session 10): a terminating xsl:message instead of a fake
                   implementation. In the real workflow this file would BE
                   src/strings.xsl after your edit.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
  CHANGE HISTORY : |==================|=========|============|========================
                   | Author           | Version | Date       | Notes
                   |==================|=========|============|========================
                   | <you>            | 1.0.0   | 2026-10-06 | <step 4: replace the slot
                   |                  |         |            |  with the implementation>
                   |==================|=========|============|========================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:str="http://exslt.org/strings"
                exclude-result-prefixes="xs str"
                version="3.0">

  <xsl:template match="requests">
    <report>
      <xsl:for-each select="repeat">
        <repeat input="{@input}" count="{@count}">
          <result>
            <xsl:value-of select="str:repeat(@input, @count)"/>
          </result>
        </repeat>
      </xsl:for-each>
    </report>
  </xsl:template>

  <!--
      WORKFLOW START STATE — proposed function, not yet implemented.

      Tier-3 slot shape (session 10, src/dynamic.xsl): a loud message
      instead of a fake answer. README section 4 replaces everything below
      the params with the genuine tier-2 str:repeat plus its tail-recursive
      worker, and fills in the CHANGE HISTORY row above.
  -->
  <xsl:function name="str:repeat" as="xs:string">
    <xsl:param name="input" as="xs:string?"/>
    <xsl:param name="count" as="xs:string?"/>
    <xsl:message terminate="yes"
      select="'str:repeat: proposed function, not yet implemented — workflow START state (training session 11, README step 4).'"/>
    <xsl:sequence select="''"/>
  </xsl:function>

</xsl:stylesheet>
