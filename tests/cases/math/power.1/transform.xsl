<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:math="http://exslt.org/math">

<xsl:output method="text"/>

<xsl:template match="/">
power(2,10)   : <xsl:value-of select="math:power(2, 10)"/>
power(10,-2)  : <xsl:value-of select="math:power(10, -2)"/>
power(2,0.5)  : <xsl:value-of select="math:power(2, 0.5)"/>
power(0,5)    : <xsl:value-of select="math:power(0, 5)"/>
power(1,10)   : <xsl:value-of select="math:power(1, 10)"/>
power(0,0)    : <xsl:value-of select="math:power(0, 0)"/>
power(-2,2)   : <xsl:value-of select="math:power(-2, 2)"/>
power(-2,0.5) : <xsl:value-of select="math:power(-2, 0.5)"/>
power(2,-10)  : <xsl:value-of select="math:power(2, -10)"/>
</xsl:template>

<xsl:include href="../../../src/math.xsl"/>

</xsl:stylesheet>
