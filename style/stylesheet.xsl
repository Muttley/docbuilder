<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:fo="http://www.w3.org/1999/XSL/Format"
				xmlns:date="http://exslt.org/dates-and-times"
				extension-element-prefixes="date"
				version="1.0">

	<xsl:import href="docbook-xsl-1.77.1/fo/docbook.xsl"/>

	<xsl:param name="body.font.family" select="'Verdana'"/>
	<xsl:param name="body.margin.top">1.7cm</xsl:param>
	<xsl:param name="body.start.indent" select="'0em'"/>
	<xsl:param name="chapter.autolabel" select="'0'"/>
	<xsl:param name="default.table.width" select="'100%'"/>
	<xsl:param name="draft.mode" select="'no'"/>
	<xsl:param name="footer.rule" select="0"/>
	<xsl:param name="fop1.extensions" select="'1'"/>
	<xsl:param name="generate.toc" select="'article toc,title,figure,table'"/>
	<xsl:param name="header.column.widths">0 1 0</xsl:param>
	<xsl:param name="header.rule" select="0"/>
	<xsl:param name="paper.type" select="'A4'"/>
	<xsl:param name="region.before.extent">1.5cm</xsl:param>
	<xsl:param name="section.autolabel" select="'1'"/>
	<xsl:param name="shade.verbatim" select="1"/>
	<xsl:param name="title.font.family" select="'Verdana'"/>
	<xsl:param name="toc.section.depth">3</xsl:param>

	<!-- Center figures -->

	<xsl:attribute-set name="figure.properties">
		<xsl:attribute name="text-align">center</xsl:attribute>
	</xsl:attribute-set>

	<!-- Keep tables together -->

	<xsl:attribute-set name="formal.object.properties">
		<xsl:attribute name="keep-together.within-column">always</xsl:attribute>
	</xsl:attribute-set>

	<!-- Set code block font and style. Will always try to keep code blocks on -->
	<!-- same page -->

	<xsl:attribute-set name="monospace.verbatim.properties">
		<xsl:attribute name="font-family">Consolas</xsl:attribute>
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="keep-together.within-column">always</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="shade.verbatim.style">
	  <xsl:attribute name="background-color">#F0F0F0</xsl:attribute>
	  <xsl:attribute name="border-width">0.5pt</xsl:attribute>
	  <xsl:attribute name="border-style">solid</xsl:attribute>
	  <xsl:attribute name="border-color">#575757</xsl:attribute>
	  <xsl:attribute name="padding">3pt</xsl:attribute>
	</xsl:attribute-set>

	<!-- styles for document links -->

	<xsl:attribute-set name="xref.properties">
	  <xsl:attribute name="font-style">italic</xsl:attribute>
	</xsl:attribute-set>

	<!-- Macro that allows us to insert hard page breaks wherever we want in the document -->

	<xsl:template match="processing-instruction('hard-pagebreak')">
		<fo:block break-after='page'/>
	</xsl:template>

	<!-- Insert a hard page break before and after the table of contents -->

	<xsl:template name="component.toc.separator">
		<fo:block break-after="page"/>
	</xsl:template>

	<xsl:template name="article.titlepage.separator">
		<fo:block break-after="page"/>
	</xsl:template>

</xsl:stylesheet>
