<?xml version="1.0" ?>



<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"

        xmlns:str="http://exslt.org/strings"

	exclude-result-prefixes="str">

	<xsl:template match="/">

		<out>

			<xsl:value-of select="str:encode-uri('a_^_é_中_𐀄',false())"/>



		</out>

	</xsl:template>



<xsl:include href="../../../src/strings.xsl"/>

</xsl:stylesheet>

