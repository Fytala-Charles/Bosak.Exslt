<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:math="http://exslt.org/math">

<xsl:output method="text"/>

<xsl:template match="/">
log(1)      : <xsl:value-of select="math:log(1)"/>
log(E)      : <xsl:value-of select="math:log(math:constant('E', 15))"/>
log(10)     : <xsl:value-of select="math:log(10)"/>
log(0)      : <xsl:value-of select="math:log(0)"/>
log(-1)     : <xsl:value-of select="math:log(-1)"/>
exp(0)      : <xsl:value-of select="math:exp(0)"/>
exp(1)      : <xsl:value-of select="math:exp(1)"/>
exp(-1)     : <xsl:value-of select="math:exp(-1)"/>
exp(1000)   : <xsl:value-of select="math:exp(1000)"/>
</xsl:template>

<xsl:include href="../../../src/math.xsl"/>

</xsl:stylesheet>
