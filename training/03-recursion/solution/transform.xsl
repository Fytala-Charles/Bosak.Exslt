<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Fytala (training reference solution)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 03 reference solution — the completed starter.
                   Compare with your own attempt BEFORE reading this file
                   (see training/03-recursion/README.md section 7, which also
                   points at the library implementation in src/strings.xsl).
  SPECIAL NOTES  : Self-contained: includes nothing from src/ (golden rule in
                   training/README.md).
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

  <!-- Short form: the default pad character is a space, supplied by delegating. -->
  <xsl:function name="str:padding" as="xs:string">
    <xsl:param name="length" as="xs:integer"/>
    <xsl:sequence select="str:padding($length, ())"/>
  </xsl:function>

  <!-- Normalizes the pad characters and seeds the accumulator with ''. -->
  <xsl:function name="str:padding" as="xs:string">
    <xsl:param name="length" as="xs:integer"/>
    <xsl:param name="chars" as="xs:string?"/>
    <xsl:variable name="pad" as="xs:string"
                  select="if (not($chars) or $chars eq '') then ' ' else $chars"/>
    <xsl:sequence select="str:padding-chars($length, $pad, '')"/>
  </xsl:function>

  <!--
      Recursive worker: tail recursion with an accumulator. Each call appends
      $chars once more; the guard stops when the accumulator reaches the target
      length, and substring() trims the last over-appended characters (which
      happens whenever $length is not a multiple of string-length($chars)).
      A non-positive $length never enters the recursion: substring() of it is ''.
  -->
  <xsl:function name="str:padding-chars" as="xs:string">
    <xsl:param name="length" as="xs:integer"/>
    <xsl:param name="chars" as="xs:string"/>
    <xsl:param name="built" as="xs:string"/>
    <xsl:sequence select="if (string-length($built) ge $length) then substring($built, 1, $length)
                          else str:padding-chars($length, $chars, concat($built, $chars))"/>
  </xsl:function>

  <!-- Two-argument form: default alignment is 'left'. -->
  <xsl:function name="str:align" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="padding" as="xs:string"/>
    <xsl:sequence select="str:align($string, $padding, ())"/>
  </xsl:function>

  <!--
      The padding STRING defines the target width; the missing characters are
      supplied by str:padding built from the same characters, so '=-' fills
      '=-=-=-=-', not '========'. Center puts the odd extra character on the
      right ($gap idiv 2 floors the left share).
  -->
  <xsl:function name="str:align" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="padding" as="xs:string"/>
    <xsl:param name="alignment" as="xs:string?"/>
    <xsl:variable name="width" as="xs:integer" select="string-length($padding)"/>
    <xsl:variable name="gap" as="xs:integer" select="$width - string-length($string)"/>
    <xsl:choose>
      <xsl:when test="$gap le 0">
        <xsl:sequence select="substring($string, 1, $width)"/>
      </xsl:when>
      <xsl:when test="$alignment = ('center', 'centre')">
        <xsl:variable name="left" as="xs:integer" select="$gap idiv 2"/>
        <xsl:sequence select="concat(str:padding($left, $padding),
                                     $string,
                                     str:padding($gap - $left, $padding))"/>
      </xsl:when>
      <xsl:when test="$alignment eq 'right'">
        <xsl:sequence select="concat(str:padding($gap, $padding), $string)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="concat($string, str:padding($gap, $padding))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
