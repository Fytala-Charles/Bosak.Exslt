<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:math="http://exslt.org/math">

<xsl:output method="text"/>

<xsl:template match="/">
sin(0)        : <xsl:value-of select="math:sin(0)"/>
cos(0)        : <xsl:value-of select="math:cos(0)"/>
tan(0)        : <xsl:value-of select="math:tan(0)"/>
sin(pi/2)     : <xsl:value-of select="math:sin(1.5707963267948966)"/>
cos(pi)       : <xsl:value-of select="math:cos(3.141592653589793)"/>
tan(pi/4)     : <xsl:value-of select="math:tan(0.7853981633974483)"/>
asin(1)       : <xsl:value-of select="math:asin(1)"/>
asin(2)       : <xsl:value-of select="math:asin(2)"/>
acos(1)       : <xsl:value-of select="math:acos(1)"/>
atan(1)       : <xsl:value-of select="math:atan(1)"/>
atan2(1,1)    : <xsl:value-of select="math:atan2(1, 1)"/>
atan2(1,0)    : <xsl:value-of select="math:atan2(1, 0)"/>
atan2(0,0)    : <xsl:value-of select="math:atan2(0, 0)"/>
</xsl:template>

<xsl:include href="../../../src/math.xsl"/>

</xsl:stylesheet>
