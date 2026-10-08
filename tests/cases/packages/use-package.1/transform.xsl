<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:math="http://exslt.org/math"
                xmlns:str="http://exslt.org/strings"
                exclude-result-prefixes="math str">

<!-- REQ-003: consumes two EXSLT modules through xsl:use-package (prefix
     version range "1.0" matches the registered 1.0.0 packages) instead of
     xsl:include. The packages must be registered host-side via
     Bosak.Xslt.Api.XsltFunctionLibrary.RegisterPackage. -->

<xsl:use-package name="urn:fytala:exslt:math" package-version="1.0"/>
<xsl:use-package name="urn:fytala:exslt:strings" package-version="1.0"/>

<xsl:template match="/">
  <out>
    <max><xsl:value-of select="math:max(/data/num)"/></max>
    <power><xsl:value-of select="math:power(2, 10)"/></power>
    <tokens><xsl:value-of select="str:tokenize('a,b,c', ',')"/></tokens>
    <aligned><xsl:value-of select="str:align('pad', '..........', 'right')"/></aligned>
  </out>
</xsl:template>

</xsl:stylesheet>
