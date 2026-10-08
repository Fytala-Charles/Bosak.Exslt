<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:math="http://exslt.org/math">

<xsl:output method="text"/>

<xsl:template match="/">
constant('PI',1)      : <xsl:value-of select="math:constant('PI', 1)"/>
constant('PI',3)      : <xsl:value-of select="math:constant('PI', 3)"/>
constant('PI',15)     : <xsl:value-of select="math:constant('PI', 15)"/>
constant('E',5)       : <xsl:value-of select="math:constant('E', 5)"/>
constant('SQRRT2',4)  : <xsl:value-of select="math:constant('SQRRT2', 4)"/>
constant('SQRT1_2',3) : <xsl:value-of select="math:constant('SQRT1_2', 3)"/>
constant('LN2',3)     : <xsl:value-of select="math:constant('LN2', 3)"/>
constant('LN10',3)    : <xsl:value-of select="math:constant('LN10', 3)"/>
constant('LOG2E',3)   : <xsl:value-of select="math:constant('LOG2E', 3)"/>
constant('PI',0)      : <xsl:value-of select="math:constant('PI', 0)"/>
constant('BOGUS',3)   : <xsl:value-of select="math:constant('BOGUS', 3)"/>
</xsl:template>

<xsl:include href="../../../src/math.xsl"/>

</xsl:stylesheet>
