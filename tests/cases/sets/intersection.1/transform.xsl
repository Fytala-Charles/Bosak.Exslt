<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:set="http://exslt.org/sets">

<xsl:variable name="i" select="//city[contains(@name,'i')]"/>
<xsl:variable name="e" select="//city[contains(@name,'e')]"/>
<xsl:variable name="all" select="//city"/>

<xsl:output method="text"/>

<xsl:template match="/">
intersection(i,e)  : <xsl:for-each select="set:intersection($i, $e)"><xsl:value-of select="@name"/>;</xsl:for-each>
intersection(i,all): <xsl:for-each select="set:intersection($i, $all)"><xsl:value-of select="@name"/>;</xsl:for-each>
intersection(i,/)  : [<xsl:for-each select="set:intersection($i, /..)"><xsl:value-of select="@name"/>;</xsl:for-each>]
intersection order : <xsl:for-each select="set:intersection($e, $i)"><xsl:value-of select="@name"/>;</xsl:for-each>
</xsl:template>

<xsl:include href="../../../src/sets.xsl"/>

</xsl:stylesheet>
