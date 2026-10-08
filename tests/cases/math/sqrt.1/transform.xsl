<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:math="http://exslt.org/math">

<xsl:output method="text"/>

<xsl:template match="/">
sqrt(4)    : <xsl:value-of select="math:sqrt(4)"/>
sqrt(0)    : <xsl:value-of select="math:sqrt(0)"/>
sqrt(0.25) : <xsl:value-of select="math:sqrt(0.25)"/>
sqrt(2)    : <xsl:value-of select="math:sqrt(2)"/>
sqrt(1e6)  : <xsl:value-of select="math:sqrt(1000000)"/>
sqrt(-1)   : <xsl:value-of select="math:sqrt(-1)"/>
</xsl:template>

<xsl:include href="../../../src/math.xsl"/>

</xsl:stylesheet>
