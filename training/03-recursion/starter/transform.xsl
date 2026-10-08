<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Training session 03 (starter — replace with your name)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 03 exercise — recursive str:padding (exercise 1) and
                   str:align (exercise 2). Self-contained: includes nothing from src/
                   (see the golden rule in training/README.md).
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

  <xsl:template match="scores">
    <report>
      <title><xsl:value-of select="str:align('High Scores', str:padding(25, '-'), 'center')"/></title>
      <xsl:for-each select="player">
        <row><xsl:value-of select="str:align(@name, str:padding(12), 'left')"/><xsl:value-of select="str:align(@points, str:padding(6), 'right')"/></row>
      </xsl:for-each>
      <rule><xsl:value-of select="str:padding(18, '=-')"/></rule>
    </report>
  </xsl:template>

  <!--
      Given for the exercise — study, do not change.
      XSLT has no default parameter values, so the short form of a function is a
      separate one-argument definition that supplies the default and delegates.
  -->
  <xsl:function name="str:padding" as="xs:string">
    <xsl:param name="length" as="xs:integer"/>
    <xsl:sequence select="str:padding($length, ())"/>
  </xsl:function>

  <!--
      EXERCISE 1 (see README section 4): this is the NAIVE attempt — a single
      substring() can cut the pad characters down but can never REPEAT them.
      It happens to work when $length <= string-length($chars); implement the
      real recursive version per the README hints.
  -->
  <xsl:function name="str:padding" as="xs:string">
    <xsl:param name="length" as="xs:integer"/>
    <xsl:param name="chars" as="xs:string?"/>
    <xsl:variable name="pad" as="xs:string"
                  select="if (not($chars) or $chars eq '') then ' ' else $chars"/>
    <xsl:sequence select="substring($pad, 1, $length)"/>
  </xsl:function>

  <!-- Given for the exercise — the two-argument form of str:align (left). -->
  <xsl:function name="str:align" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="padding" as="xs:string"/>
    <xsl:sequence select="str:align($string, $padding, ())"/>
  </xsl:function>

  <!--
      EXERCISE 2 (see README section 5): this stub always left-aligns. Implement
      'right' and 'center' ('centre'), and the truncation rule, per the hints.
  -->
  <xsl:function name="str:align" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="padding" as="xs:string"/>
    <xsl:param name="alignment" as="xs:string?"/>
    <xsl:variable name="gap" as="xs:integer"
                  select="string-length($padding) - string-length($string)"/>
    <xsl:sequence select="concat($string, substring($padding, 1, $gap))"/>
  </xsl:function>

</xsl:stylesheet>
