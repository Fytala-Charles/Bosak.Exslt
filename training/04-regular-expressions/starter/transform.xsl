<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Training session 04 (starter — replace with your name)
  CREATE DATE    : 2026-10-06
  PURPOSE        : Training session 04 exercise — str:tokenize (exercise 1),
                   str:split (exercise 2) and str:encode-uri (exercise 3).
                   Self-contained: includes nothing from src/ (see the golden rule
                   in training/README.md).
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

  <!--
      Given for the exercise — study, do not change.
      Wraps each NON-EMPTY string in a <token> element. The filter matters:
      the Bosak engine keeps zero-length tokens from fn:tokenize (the XPath
      spec says to drop them), so the empties are removed here, in one place
      both exercise functions can reuse. See README section 3.
  -->
  <xsl:function name="str:make-tokens" as="element(token)*">
    <xsl:param name="strings" as="xs:string*"/>
    <xsl:for-each select="$strings[. ne '']">
      <token>
        <xsl:value-of select="."/>
      </token>
    </xsl:for-each>
  </xsl:function>

  <!-- Given for the exercise — the one-argument form: whitespace delimiters. -->
  <xsl:function name="str:tokenize" as="element(token)*">
    <xsl:param name="string" as="xs:string"/>
    <xsl:sequence select="str:tokenize($string, ())"/>
  </xsl:function>

  <!--
      EXERCISE 1 (see README section 4): NAIVE — the delimiters are a set of
      LITERAL characters, but fn:tokenize reads its second argument as a REGULAR
      EXPRESSION. Here '.' means "any character", so this splits inside every
      word. (The whitespace default below is only there so the one-argument
      call runs; the escaping of literal delimiters is the exercise.)
      Build the pattern the honest way and let str:make-tokens filter.
  -->
  <xsl:function name="str:tokenize" as="element(token)*">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="delimiters" as="xs:string?"/>
    <xsl:sequence select="str:make-tokens(tokenize($string, if (not($delimiters)) then '\s+' else $delimiters))"/>
  </xsl:function>

  <!--
      EXERCISE 2 (see README section 5): NAIVE — wraps whatever fn:tokenize
      returns, zero-length tokens included. The golden output drops them.
      The empty-pattern branch (split into characters) is GIVEN: it is
      character arithmetic from session 03, not regular expressions.
  -->
  <xsl:function name="str:split" as="element(token)*">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="pattern" as="xs:string?"/>
    <xsl:choose>
      <xsl:when test="$pattern eq ''">
        <xsl:sequence select="str:make-tokens(string-to-codepoints($string) ! codepoints-to-string(.))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="tokenize($string, $pattern)">
          <token>
            <xsl:value-of select="."/>
          </token>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--
      EXERCISE 3 (see README section 6): STUB — returns the URI unchanged.
      Percent-encode every character outside the unreserved set (README
      explains the two modes and the ASCII scope of this exercise).
  -->
  <xsl:function name="str:encode-uri" as="xs:string">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:param name="encode-reserved" as="xs:boolean"/>
    <xsl:sequence select="$uri"/>
  </xsl:function>

</xsl:stylesheet>
