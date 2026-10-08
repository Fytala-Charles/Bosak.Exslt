<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Fytala (training reference solution)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 04 reference solution — the completed starter.
                   Compare with your own attempt BEFORE reading this file
                   (see training/04-regular-expressions/README.md section 8,
                   which also points at the library implementation in src/strings.xsl).
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

  <xsl:template match="data">
    <result>
      <log>
        <xsl:sequence select="str:tokenize(log, ' .:')"/>
      </log>
      <words>
        <xsl:sequence select="str:tokenize(sentence)"/>
      </words>
      <csv>
        <xsl:sequence select="str:split(csv, ',')"/>
      </csv>
      <chars>
        <xsl:sequence select="str:split(word, '')"/>
      </chars>
      <path>
        <encoded><xsl:value-of select="str:encode-uri(path, true())"/></encoded>
        <iri><xsl:value-of select="str:encode-uri(path, false())"/></iri>
      </path>
      <query>
        <encoded><xsl:value-of select="str:encode-uri(query, true())"/></encoded>
        <iri><xsl:value-of select="str:encode-uri(query, false())"/></iri>
      </query>
    </result>
  </xsl:template>

  <!-- Wraps each non-empty string in a <token> element (no namespace), per the
       EXSLT tokenize/split contract; also absorbs the engine's zero-length
       tokens from fn:tokenize (see README section 3). -->
  <xsl:function name="str:make-tokens" as="element(token)*">
    <xsl:param name="strings" as="xs:string*"/>
    <xsl:for-each select="$strings[. ne '']">
      <token>
        <xsl:value-of select="."/>
      </token>
    </xsl:for-each>
  </xsl:function>

  <!-- Single-argument form: split on whitespace runs. -->
  <xsl:function name="str:tokenize" as="element(token)*">
    <xsl:param name="string" as="xs:string"/>
    <xsl:sequence select="str:tokenize($string, ())"/>
  </xsl:function>

  <!--
      The EXSLT delimiters argument is a set of LITERAL characters (any ONE of
      them separates tokens), so each character is regex-escaped before being
      handed to fn:tokenize, and the alternatives are joined with '|'. With no
      delimiters the string is split on whitespace runs.
  -->
  <xsl:function name="str:tokenize" as="element(token)*">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="delimiters" as="xs:string?"/>
    <xsl:variable name="pattern" as="xs:string"
      select="if (exists($delimiters) and $delimiters ne '')
              then string-join(for $c in string-to-codepoints($delimiters)
                               return replace(codepoints-to-string($c),
                                              '(\.|\[|\]|\\|\||\-|\^|\$|\*|\+|\?|\(|\)|\{|\})', '\\$1'),
                               '|')
              else '\s+'"/>
    <xsl:sequence select="str:make-tokens(tokenize($string, $pattern))"/>
  </xsl:function>

  <!--
      Regex-based split: separators are discarded, empty pieces dropped (by
      str:make-tokens). No pattern means whitespace runs; an EMPTY pattern
      means "split into individual characters" and is pure codepoint
      arithmetic, not a regex.
  -->
  <xsl:function name="str:split" as="element(token)*">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="pattern" as="xs:string?"/>
    <xsl:choose>
      <xsl:when test="$pattern eq ''">
        <xsl:sequence select="str:make-tokens(string-to-codepoints($string) ! codepoints-to-string(.))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="str:make-tokens(tokenize($string, if (not($pattern)) then '\s+' else $pattern))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--
      ASCII-scoped percent-encoding (see README section 6 for the full contract
      and why non-ASCII input is out of scope here): characters outside the
      keep-set become '%' plus two uppercase hex digits of the codepoint.
      $encode-reserved = true() keeps ONLY the unreserved set (encode-for-uri
      semantics); false() also keeps the reserved characters (iri-to-uri).
  -->
  <xsl:function name="str:encode-uri" as="xs:string">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:param name="encode-reserved" as="xs:boolean"/>
    <xsl:variable name="unreserved" as="xs:string"
      select="'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~'"/>
    <xsl:variable name="reserved" as="xs:string" select="':/?#%[]@!$&amp;()*+,;='"/>
    <xsl:variable name="keep" as="xs:string"
      select="if ($encode-reserved) then $unreserved else concat($unreserved, $reserved)"/>
    <xsl:sequence select="str:encode-uri-scan($uri, $keep)"/>
  </xsl:function>

  <!-- Session 03's tail recursion, now over characters instead of counts. -->
  <xsl:function name="str:encode-uri-scan" as="xs:string">
    <xsl:param name="remaining" as="xs:string"/>
    <xsl:param name="keep" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$remaining eq ''">
        <xsl:sequence select="''"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="c" as="xs:string" select="substring($remaining, 1, 1)"/>
        <xsl:variable name="code" as="xs:integer" select="string-to-codepoints($c)[1]"/>
        <xsl:variable name="encoded" as="xs:string"
          select="if (contains($keep, $c)) then $c
                  else concat('%',
                              substring('0123456789ABCDEF', $code idiv 16 + 1, 1),
                              substring('0123456789ABCDEF', $code mod 16 + 1, 1))"/>
        <xsl:sequence select="concat($encoded, str:encode-uri-scan(substring($remaining, 2), $keep))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
