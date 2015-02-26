<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:mods="http://www.loc.gov/mods/v3"  xmlns:java="http://xml.apache.org/xalan/java" exclude-result-prefixes="mods">
  <xsl:variable name="modsPrefix">mods_</xsl:variable>
  <xsl:variable name="modsSuffix">_ms</xsl:variable>
  <xsl:include href="/usr/local/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/slurp_all_MODS_to_solr.xslt"/>
  <!--
    SECTION 1:

    Our root MODS processing template; this is where we split out specific MODS
    collections that need special metadata field templates. Not all collections
    will need this; if they don't, the generic stuff below takes care of them.
    
    Collections being given special treatment in here should also have templates
    in the second and third sections below.
  -->

  <xsl:template match="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]" name="index_MODS_UCLA">
    <xsl:param name="content"/>

    <!-- encode the whole mods record into a solr field -->
    <field name="mods_xml">
      <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
      <xsl:copy-of select="$content/mods:mods"/>
      <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
    </field>

    <!-- xslt 1.0 doesn't allow use of multiple modes; we need wrapper code -->
    <xsl:for-each select="$content/mods:mods">
      <xsl:choose>
        <xsl:when
          test="starts-with($PID, 'edu.ucla.library.specialCollections.losAngelesDailyNews')
          or starts-with($PID, 'edu.ucla.library.universityArchives.historicPhotographs')
          or starts-with($PID, 'edu.ucla.library.specialCollections.latimes')">
          <xsl:apply-templates select="mods:*" mode="CollectingLA"/>
        </xsl:when>
        <xsl:when test="starts-with($PID, 'edu.ucla.library.dep.tahrir')">
          <xsl:apply-templates select="mods:*" mode="Tahrir"/>
        </xsl:when>
      </xsl:choose>
      <!-- We always get the generic treatment -->
      <xsl:apply-templates mode="slurping_MODS" select="current()">
	 <xsl:with-param name="suffix" select="'ms'"/>
      	 <xsl:with-param name="pid" select="$PID"/>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template>

  <!--
   SECTION 2:

   Below this are processing templates used by collections that have special
   metadata processing needs.
  -->

  <!-- We pull out cla topics for the visualization index -->
  <xsl:template match="mods:subject[@authority='cla_topic']" mode="CollectingLA">
    <!-- cla_topic_mt field is created automatically from submitted _ms one -->
    <field name="cla_topic_ms">
      <xsl:value-of select="mods:topic"/>
    </field>
  </xsl:template>
  
  <xsl:template match="mods:originInfo[mods:dateCreated[@encoding='iso8601']]" mode="CollectingLA">
    <xsl:variable name="dateStart"
      select="java:edu.ucla.library.IsoToSolrDateConverter.getStartDateFromIsoDateString(normalize-space(mods:dateCreated[@encoding='iso8601']))" />
    <xsl:variable name="dateEnd"
      select="java:edu.ucla.library.IsoToSolrDateConverter.getEndDateFromIsoDateString(normalize-space(mods:dateCreated[@encoding='iso8601']))" />
    <field name="mods_dateCreated_dt">
      <xsl:value-of select="$dateStart"/>
    </field>
    <field name="mods_dateCreated_start_dt">
      <xsl:value-of select="$dateStart"/>
    </field>
    <field name="mods_dateCreated_end_dt">
      <xsl:value-of select="$dateEnd"/>
    </field>
  </xsl:template>
  
  <!-- Temporary workaround to allow us to separate out the Arabic subjects -->
  <xsl:template match="mods:subject[@authority='local']" mode="Tahrir">
    <!-- mods_topic_ar_mt is created automatically for us -->
    <field name="mods_topic_ar_ms">
      <xsl:value-of select="mods:topic"/>
    </field>
  </xsl:template>
	
  <!-- This prevents text from just being printed to the doc without field elements JUST TRY COMMENTING IT OUT -->
  <xsl:template match="text()" mode="CollectingLA"/>
  <xsl:template match="text()" mode="Tahrir"/>
</xsl:stylesheet>

