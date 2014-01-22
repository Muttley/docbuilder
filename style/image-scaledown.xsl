<?xml version='1.0'?>
<!DOCTYPE xsl:stylesheet [
	<!ENTITY lowercase "'abcdefghijklmnopqrstuvwxyz'">
	<!ENTITY uppercase "'ABCDEFGHIJKLMNOPQRSTUVWXYZ'">
]>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fo="http://www.w3.org/1999/XSL/Format"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:stext="http://nwalsh.com/xslt/ext/com.nwalsh.saxon.TextFactory"
	xmlns:xtext="com.nwalsh.xalan.Text"
	xmlns:lxslt="http://xml.apache.org/xslt"
	exclude-result-prefixes="xlink stext xtext lxslt"
	extension-element-prefixes="stext xtext"
	version='1.0'>

	<xsl:template name="image.scaledownonly">
		<xsl:choose>
			<xsl:when test="$ignore.image.scaling != 0">0</xsl:when>
			<xsl:when test="@scaledownonly"><xsl:value-of select="@scaledownonly"/></xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="image.content.width">
		<xsl:param name="scalefit" select="0"/>
		<xsl:param name="scaledownonly" select="0"/>
		<xsl:param name="scale" select="'1.0'"/>

		<xsl:choose>
			<xsl:when test="$ignore.image.scaling != 0">auto</xsl:when>
			<xsl:when test="$scaledownonly = 1">scale-down-to-fit</xsl:when>
			<xsl:when test="contains(@contentwidth,'%')">
				<xsl:value-of select="@contentwidth"/>
			</xsl:when>
			<xsl:when test="@contentwidth">
				<xsl:call-template name="length-spec">
					<xsl:with-param name="length" select="@contentwidth"/>
					<xsl:with-param name="default.units" select="'px'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="number($scale) != 1.0">
				<xsl:value-of select="$scale * 100"/>
				<xsl:text>%</xsl:text>
			</xsl:when>
			<xsl:when test="$scalefit = 1">scale-to-fit</xsl:when>
			<xsl:otherwise>auto</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="image.content.height">
		<xsl:param name="scalefit" select="0"/>
		<xsl:param name="scaledownonly" select="0"/>
		<xsl:param name="scale" select="'1.0'"/>

		<xsl:choose>
			<xsl:when test="$ignore.image.scaling != 0">auto</xsl:when>
			<xsl:when test="$scaledownonly = 1">scale-down-to-fit</xsl:when>
			<xsl:when test="contains(@contentdepth,'%')">
				<xsl:value-of select="@contentdepth"/>
			</xsl:when>
			<xsl:when test="@contentdepth">
				<xsl:call-template name="length-spec">
					<xsl:with-param name="length" select="@contentdepth"/>
					<xsl:with-param name="default.units" select="'px'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="number($scale) != 1.0">
				<xsl:value-of select="$scale * 100"/>
				<xsl:text>%</xsl:text>
			</xsl:when>
			<xsl:when test="$scalefit = 1">scale-to-fit</xsl:when>
			<xsl:otherwise>auto</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="process.image">
		<!-- When this template is called, the current node should be  -->
		<!-- a graphic, inlinegraphic, imagedata, or videodata. All    -->
		<!-- those elements have the same set of attributes, so we can -->
		<!-- handle them all in one place.                             -->

		<!-- Compute each attribute value with its own customizable template call -->
		<xsl:variable name="scaledownonly">
			<xsl:call-template name="image.scaledownonly"/>
		</xsl:variable>

		<xsl:variable name="scalefit">
			<xsl:call-template name="image.scalefit"/>
		</xsl:variable>

		<xsl:variable name="scale">
			<xsl:call-template name="image.scale"/>
		</xsl:variable>

		<xsl:variable name="filename">
			<xsl:call-template name="image.filename"/>
		</xsl:variable>

		<xsl:variable name="src">
			<xsl:call-template name="image.src">
				<xsl:with-param name="filename" select="$filename"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="content.type">
			<xsl:call-template name="image.content.type"/>
		</xsl:variable>

		<xsl:variable name="bgcolor">
			<xsl:call-template name="image.bgcolor"/>
		</xsl:variable>

		<xsl:variable name="width">
			<xsl:call-template name="image.width"/>
		</xsl:variable>

		<xsl:variable name="height">
			<xsl:call-template name="image.height"/>
		</xsl:variable>

		<xsl:variable name="content.width">
			<xsl:call-template name="image.content.width">
				<xsl:with-param name="scalefit" select="$scalefit"/>
				<xsl:with-param name="scaledownonly" select="$scaledownonly"/>
				<xsl:with-param name="scale" select="$scale"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="content.height">
			<xsl:call-template name="image.content.height">
				<xsl:with-param name="scalefit" select="$scalefit"/>
				<xsl:with-param name="scaledownonly" select="$scaledownonly"/>
				<xsl:with-param name="scale" select="$scale"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="align">
			<xsl:call-template name="image.align"/>
		</xsl:variable>

		<xsl:variable name="valign">
			<xsl:call-template name="image.valign"/>
		</xsl:variable>

		<xsl:variable name="element.name">
			<xsl:choose>
				<xsl:when test="svg:*" xmlns:svg="http://www.w3.org/2000/svg">
					<xsl:text>fo:instream-foreign-object</xsl:text>
				</xsl:when>
				<xsl:when test="mml:*" xmlns:mml="http://www.w3.org/1998/Math/MathML">
					<xsl:text>fo:instream-foreign-object</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>fo:external-graphic</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:element name="{$element.name}">

			<xsl:if test="$src != ''">
				<xsl:attribute name="src">
					<xsl:value-of select="$src"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:if test="$width != ''">
				<xsl:attribute name="width">
					<xsl:value-of select="$width"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:if test="$height != ''">
				<xsl:attribute name="height">
					<xsl:value-of select="$height"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:if test="$content.width != ''">
				<xsl:attribute name="content-width">
					<xsl:value-of select="$content.width"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:if test="$content.height != ''">
				<xsl:attribute name="content-height">
					<xsl:value-of select="$content.height"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:if test="$content.type != ''">
				<xsl:attribute name="content-type">
					<xsl:value-of select="concat('content-type:',$content.type)"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:if test="$bgcolor != ''">
				<xsl:attribute name="background-color">
					<xsl:value-of select="$bgcolor"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:if test="$align != ''">
				<xsl:attribute name="text-align">
					<xsl:value-of select="$align"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:if test="$valign != ''">
				<xsl:variable name="att.name">
					<xsl:choose>
						<xsl:when test="ancestor::inlinemediaobject or ancestor-or-self::inlinegraphic">
							<xsl:text>alignment-baseline</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>display-align</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:attribute name="{$att.name}">
					<xsl:value-of select="$valign"/>
				</xsl:attribute>
			</xsl:if>

			<!-- copy literal SVG elements to output -->
			<xsl:if test="svg:*" xmlns:svg="http://www.w3.org/2000/svg">
				<xsl:call-template name="process.svg"/>
			</xsl:if>

			<xsl:if test="mml:*" xmlns:mml="http://www.w3.org/1998/Math/MathML">
				<xsl:call-template name="process.mml"/>
			</xsl:if>

		</xsl:element>
	</xsl:template>

	<!-- ==================================================================== -->

</xsl:stylesheet>
