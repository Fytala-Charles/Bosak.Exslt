<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="3.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:date="http://exslt.org/dates-and-times"
                extension-element-prefixes="date">

<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

<xsl:template match="date">
result   : <xsl:value-of select="date:day-name(@value)"/>
</xsl:template>

<xsl:include href="../../../src/dates-and-times.xsl"/>

</xsl:stylesheet>
