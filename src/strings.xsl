<?xml version="1.0" encoding="UTF-8"?>
<!--
  =======================================================================================
  AUTHOR         : Charles Korthout
  CREATE DATE    : 06 October 2026
  PURPOSE        : EXSLT strings module (http://exslt.org/strings): tokenize,
                   replace, padding, align, split, encode-uri and decode-uri.
  SPECIAL NOTES  : Tier 1 (wrapper): str:tokenize, built on fn:tokenize. Tier 2
                   (genuine): the rest. EXSLT tokenize and split return "token"
                   elements (no namespace) per the spec and the libxslt reference
                   implementation; fn:tokenize returns strings — see the per-function
                   notes when migrating.
  CHANGE HISTORY : 2026-10-06 | 1.0 -> 1.1 | str:decode-uri repaired: percent-escape
                   runs now decode as UTF-8 byte sequences (libxslt-compatible
                   round-trip); previously each %XX became a Latin-1 codepoint,
                   which turned non-ASCII input into control characters
                   (SERE0006 on serialization). str:encode-uri full mode now
                   leaves the RFC 2396 mark characters ! * ' ( ) and @
                   unencoded, matching libxslt/libxml2.
  COPYRIGHT      : Fytala
  LICENSE        : LICENSE (Apache-2.0)
  =======================================================================================
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:str="http://exslt.org/strings"
                exclude-result-prefixes="xs str"
                version="3.0">

  <!--
      Tier 1 — wrapper over fn:tokenize.

      The EXSLT delimiters argument is a set of LITERAL characters (any one of them
      separates tokens); each character is regex-escaped before being handed to
      fn:tokenize. With no delimiters argument the string is split on whitespace.

      Unlike fn:tokenize, EXSLT str:tokenize returns a "token" element per token
      (in no namespace) so that XSLT 1.0 stylesheets could apply templates to the
      result. When migrating, prefer fn:tokenize directly and drop the elements.
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

  <!-- Single-argument form of str:tokenize: split on whitespace. -->
  <xsl:function name="str:tokenize" as="element(token)*">
    <xsl:param name="string" as="xs:string"/>
    <xsl:sequence select="str:tokenize($string, ())"/>
  </xsl:function>

  <!--
      Tier 2 — genuine implementation.

      Replaces occurrences of a set of search strings with a set of replacement
      strings. Per the EXSLT spec:
      - the second argument is a sequence of search strings, the third a sequence of
        replacement strings; search string i maps to replacement string i, and a
        missing replacement means the empty string;
      - replacement is a single left-to-right pass over the input; at each position
        the earliest match wins, ties broken by lowest search-string index;
      - search strings are matched literally, not as regular expressions;
      - an empty search string inserts its replacement between characters (not at
        the very start or end of the string), matching the libxslt reference.
  -->
  <xsl:function name="str:replace" as="text()">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="from" as="xs:string*"/>
    <xsl:param name="to" as="xs:string*"/>
    <!--
        The EXSLT result is a result tree fragment holding the replaced text, and
        legacy call sites run path steps on it (e.g. $result/self::text()). Build the
        string in a variable so a real text node is returned, not an atomic value.
    -->
    <xsl:variable name="result">
      <xsl:sequence select="str:replace-scan($input, $from, $to)"/>
    </xsl:variable>
    <xsl:sequence select="$result/text()"/>
  </xsl:function>

  <xsl:function name="str:replace-scan" as="xs:string">
    <xsl:param name="remaining" as="xs:string"/>
    <xsl:param name="from" as="xs:string*"/>
    <xsl:param name="to" as="xs:string*"/>
    <!-- Every match carries its from-index, so entries that do not match cannot
         shift the index alignment. -->
    <xsl:variable name="matches" as="map(*)*"
      select="for $j in 1 to count($from)
              return (if ($from[$j] eq '') then
                        (if (string-length($remaining) ge 2) then map { 'i': $j, 'pos': 2 } else ())
                      else if (contains($remaining, $from[$j])) then
                        map { 'i': $j,
                              'pos': string-length(substring-before($remaining, $from[$j])) + 1 }
                      else ())"/>
    <xsl:choose>
      <xsl:when test="empty($matches)">
        <xsl:sequence select="$remaining"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="best-pos" as="xs:integer" select="min($matches ! (?pos))"/>
        <!-- Ties break to the lowest from-index; the for loop preserves that order. -->
        <xsl:variable name="chosen" as="map(*)" select="($matches[?pos eq $best-pos])[1]"/>
        <xsl:variable name="i" as="xs:integer" select="$chosen?i"/>
        <xsl:variable name="replacement" as="xs:string"
                      select="if (count($to) ge $i) then $to[$i] else ''"/>
        <xsl:sequence select="concat(substring($remaining, 1, $best-pos - 1),
                                     $replacement,
                                     str:replace-scan(substring($remaining, $best-pos + string-length($from[$i])),
                                                      $from, $to))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--
      Tier 2 — genuine implementation.

      Returns a string of exactly $length characters, built by repeating and
      truncating the padding characters (a single space by default). Length is
      measured in characters, not bytes.
  -->
  <xsl:function name="str:padding" as="xs:string">
    <xsl:param name="length" as="xs:integer"/>
    <xsl:param name="chars" as="xs:string?"/>
    <xsl:variable name="pad" as="xs:string"
                  select="if (not($chars) or $chars eq '') then ' ' else $chars"/>
    <xsl:sequence select="if ($length le 0) then ''
                          else substring(string-join((1 to (($length idiv string-length($pad)) + 1)) ! $pad, ''),
                                         1, $length)"/>
  </xsl:function>

  <!-- Single-argument form of str:padding: pad with spaces. -->
  <xsl:function name="str:padding" as="xs:string">
    <xsl:param name="length" as="xs:integer"/>
    <xsl:sequence select="str:padding($length, ())"/>
  </xsl:function>

  <!--
      Tier 2 — genuine implementation.

      Aligns a string within a padding string that defines the target width.
      $alignment is 'left' (default), 'right' or 'center' ('centre' accepted).
      If the string is longer than the padding, it is truncated to the padding
      length; if shorter, the padding supplies the missing characters (center puts
      the odd extra character on the right).
  -->
  <xsl:function name="str:align" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="padding" as="xs:string"/>
    <xsl:param name="alignment" as="xs:string?"/>
    <xsl:variable name="width" as="xs:integer" select="string-length($padding)"/>
    <xsl:variable name="length" as="xs:integer" select="string-length($string)"/>
    <xsl:choose>
      <xsl:when test="$length ge $width">
        <xsl:sequence select="substring($string, 1, $width)"/>
      </xsl:when>
      <xsl:when test="$alignment = ('center', 'centre')">
        <xsl:variable name="left" as="xs:integer" select="($width - $length) idiv 2"/>
        <xsl:sequence select="concat(substring($padding, 1, $left),
                                     $string,
                                     substring($padding, $left + 1, $width - $length - $left))"/>
      </xsl:when>
      <xsl:when test="$alignment eq 'right'">
        <xsl:sequence select="concat(substring($padding, 1, $width - $length), $string)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="concat($string, substring($padding, 1, $width - $length))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Two-argument form of str:align: left alignment. -->
  <xsl:function name="str:align" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:param name="padding" as="xs:string"/>
    <xsl:sequence select="str:align($string, $padding, ())"/>
  </xsl:function>

  <!--
      Tier 2 — genuine implementation.

      Splits a string on a regular expression and returns the pieces as "token"
      elements (no namespace). The separators themselves are discarded and empty
      tokens (from leading/trailing/adjacent separators) are dropped. With no
      pattern the string is split on whitespace runs; an empty pattern splits the
      string into individual characters.
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

  <!-- Wraps a sequence of strings in "token" elements (no namespace); zero-length
      tokens are dropped, per the EXSLT tokenize/split contract. -->
  <xsl:function name="str:make-tokens" as="element(token)*">
    <xsl:param name="strings" as="xs:string*"/>
    <xsl:for-each select="$strings[. ne '']">
      <token>
        <xsl:value-of select="."/>
      </token>
    </xsl:for-each>
  </xsl:function>

  <!-- Single-argument form of str:split: split on whitespace runs. -->
  <xsl:function name="str:split" as="element(token)*">
    <xsl:param name="string" as="xs:string"/>
    <xsl:sequence select="str:split($string, ())"/>
  </xsl:function>

  <!--
      Tier 2 — genuine implementation.

      Encodes reserved characters in a URI for use in a URI. When $encode-reserved
      is true, every character outside [a-zA-Z0-9\-_.!~*'()@] is percent-encoded,
      matching libxslt: its full mode leaves the RFC 2396 "mark" characters
      ! * ' ( ) unencoded, and the underlying libxml2 xmlURIEscapeStr always
      leaves @ unencoded (a hardcoded exception, even in full mode). fn:encode-for-uri
      encodes all six, so its output is post-processed to restore them — safe
      because encode-for-uri always encodes '%' itself, so a %21 token in its
      output can only come from a literal '!'.
      When false, only characters illegal in a URI are escaped and reserved
      characters are preserved (fn:iri-to-uri); libxslt also escapes every
      literal '%' in this mode, so '%' is pre-escaped to '%25' before
      iri-to-uri (which leaves '%' alone but would double-escape its own
      output if run first).
  -->
  <xsl:function name="str:encode-uri" as="xs:string">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:param name="encode-reserved" as="xs:boolean"/>
    <xsl:sequence select="if ($encode-reserved)
                          then str:restore-uri-marks(encode-for-uri($uri))
                          else iri-to-uri(replace($uri, '%', '%25'))"/>
  </xsl:function>

  <!-- Restores the characters libxslt's full-mode str:encode-uri leaves unencoded
       but fn:encode-for-uri percent-encodes: the RFC 2396 "mark" characters
       ! * ' ( ) and @ (xmlURIEscapeStr's hardcoded exception). The escape
       tokens cannot occur except from the literal characters (encode-for-uri
       encodes '%' itself), so a plain replace chain is exact. -->
  <xsl:function name="str:restore-uri-marks" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="replace(replace(replace(replace(replace(replace(
                            $s, '%21', '!'), '%2A', '*'), '%27', ''''), '%28', '('), '%29', ')'), '%40', '@')"/>
  </xsl:function>

  <!--
      Tier 2 — genuine implementation.

      Percent-decodes a URI. XPath 3.1 offers no decoding function, so this scans
      the string for maximal runs of consecutive %XX escapes and decodes each run
      as a UTF-8 byte sequence (matching libxslt, which treats percent-escapes as
      UTF-8 bytes — so decode-uri(encode-uri(x)) round-trips non-ASCII text).
      Literal characters between runs pass through unchanged, as does a '%' that
      is not followed by two hexadecimal digits. Malformed UTF-8 inside a run
      (a stray continuation byte, or a bad/truncated multi-byte sequence) is not
      an error: the offending byte is passed through as a raw codepoint and
      decoding continues with the next byte — see docs/COMPATIBILITY.md.
  -->
  <xsl:function name="str:decode-uri" as="xs:string">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:variable name="mark" as="xs:integer" select="string-length(substring-before($uri, '%')) + 1"/>
    <xsl:choose>
      <xsl:when test="not(contains($uri, '%'))">
        <xsl:sequence select="$uri"/>
      </xsl:when>
      <xsl:when test="$mark + 2 gt string-length($uri)
                      or not(str:is-hex-pair(substring($uri, $mark + 1, 2)))">
        <xsl:sequence select="concat(substring($uri, 1, $mark), str:decode-uri(substring($uri, $mark + 1)))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="run-length" as="xs:integer" select="str:escape-run-length($uri, $mark)"/>
        <xsl:variable name="bytes" as="xs:integer*"
          select="for $i in 1 to $run-length idiv 3
                  return str:hex-to-codepoint(substring($uri, $mark + 3 * $i - 2, 2))"/>
        <xsl:sequence select="concat(substring($uri, 1, $mark - 1),
                                     codepoints-to-string(str:utf8-decode($bytes)),
                                     str:decode-uri(substring($uri, $mark + $run-length)))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Returns the length of the maximal run of consecutive %XX escapes starting
       at $pos (a multiple of 3, or 0 when $pos is not at an escape). -->
  <xsl:function name="str:escape-run-length" as="xs:integer">
    <xsl:param name="s" as="xs:string"/>
    <xsl:param name="pos" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="substring($s, $pos, 1) eq '%'
                      and str:is-hex-pair(substring($s, $pos + 1, 2))">
        <xsl:sequence select="3 + str:escape-run-length($s, $pos + 3)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="0"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Decodes a UTF-8 byte sequence (integers 0-255) into Unicode codepoints.
       Structural validation only: a lead byte with a bad or truncated
       continuation run, or a stray continuation byte, is passed through as a
       raw codepoint and decoding resumes at the following byte. -->
  <xsl:function name="str:utf8-decode" as="xs:integer*">
    <xsl:param name="bytes" as="xs:integer*"/>
    <xsl:variable name="b1" as="xs:integer?" select="$bytes[1]"/>
    <xsl:choose>
      <xsl:when test="empty($bytes)">
        <xsl:sequence select="()"/>
      </xsl:when>
      <xsl:when test="$b1 lt 192">
        <!-- ASCII byte or stray continuation byte: pass through. -->
        <xsl:sequence select="($b1, str:utf8-decode(subsequence($bytes, 2)))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="width" as="xs:integer"
          select="if ($b1 lt 224) then 2 else if ($b1 lt 240) then 3 else 4"/>
        <xsl:variable name="seq" as="xs:integer*" select="subsequence($bytes, 1, $width)"/>
        <xsl:choose>
          <xsl:when test="count($seq) eq $width
                          and (every $b in subsequence($seq, 2) satisfies ($b ge 128 and $b lt 192))">
            <xsl:variable name="lead" as="xs:integer"
              select="if ($width eq 2) then $b1 - 192
                 else if ($width eq 3) then $b1 - 224
                 else $b1 - 240"/>
            <xsl:sequence select="(str:utf8-accumulate($lead, subsequence($seq, 2)),
                                   str:utf8-decode(subsequence($bytes, $width + 1)))"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- Bad or truncated continuation run: pass the lead byte through. -->
            <xsl:sequence select="($b1, str:utf8-decode(subsequence($bytes, 2)))"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Accumulates continuation bytes (each contributes its low 6 bits) into a
       partially-built codepoint. -->
  <xsl:function name="str:utf8-accumulate" as="xs:integer">
    <xsl:param name="prefix" as="xs:integer"/>
    <xsl:param name="bytes" as="xs:integer*"/>
    <xsl:choose>
      <xsl:when test="empty($bytes)">
        <xsl:sequence select="$prefix"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="str:utf8-accumulate(64 * $prefix + $bytes[1] - 128, subsequence($bytes, 2))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Returns true when the two characters form a hexadecimal byte. -->
  <xsl:function name="str:is-hex-pair" as="xs:boolean">
    <xsl:param name="pair" as="xs:string"/>
    <xsl:sequence select="string-length($pair) eq 2
                          and string(translate(upper-case($pair), '0123456789ABCDEF', '')) eq ''"/>
  </xsl:function>

  <!-- Converts a two-digit hexadecimal string to a Unicode codepoint. -->
  <xsl:function name="str:hex-to-codepoint" as="xs:integer">
    <xsl:param name="pair" as="xs:string"/>
    <xsl:variable name="digits" as="xs:string" select="upper-case($pair)"/>
    <xsl:sequence select="16 * (string-length(substring-before('0123456789ABCDEF', substring($digits, 1, 1))))
                        + string-length(substring-before('0123456789ABCDEF', substring($digits, 2, 1)))"/>
  </xsl:function>

</xsl:stylesheet>
