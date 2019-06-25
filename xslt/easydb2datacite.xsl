<?xml version="1.0" encoding="UTF-8"?>
<!--
     LaZAR-DB Export nach DataCite
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:datacite="http://datacite.org/schema/kernel-4"
  xmlns:edb="https://schema.easydb.de/EASYDB/1.0/objects/"
  exclude-result-prefixes="edb xsl">

  <xsl:output method="xml" indent="yes" encoding="UTF-8" />

  <!-- Wurzelelement -->
  <xsl:template match="edb:objects">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- LaZAR-Objekttyp "Sprache" -->
  <xsl:template match="edb:sprache[parent::edb:objects]">
    <datacite:resource>
      <xsl:call-template name="identifier"/>
      <datacite:titles>
        <xsl:for-each select="edb:name[@type='text_l10n_oneline']/*[string()]">
          <xsl:call-template name="title"/>
        </xsl:for-each>
      </datacite:titles>
      <datacite:alternateIdentifiers>
        <xsl:apply-templates select="edb:isocode"/>
        <xsl:apply-templates select="edb:custom" mode="alternateIdentifier"/>
      </datacite:alternateIdentifiers>
      <datacite:resourceType resourceTypeGeneral="Other">http://schema.org/Language</datacite:resourceType>
    </datacite:resource>
  </xsl:template>

  <xsl:template match="edb:isocode">
    <datacite:alternateIdentifier alternateIdentifierType="URI">
      <xsl:choose>
        <xsl:when test="string-length()=2">http://id.loc.gov/vocabulary/iso639-1/</xsl:when>
        <xsl:when test="string-length()=3">http://id.loc.gov/vocabulary/iso639-2/</xsl:when>
      </xsl:choose>
      <xsl:value-of select="."/>
    </datacite:alternateIdentifier>
  </xsl:template>

  <xsl:template match="edb:custom[@name='glottolog']" mode="alternateIdentifier">
    <datacite:alternateIdentifier alternateIdentifierType="URI">
      <xsl:value-of select="edb:string[@name='url']"/>
    </datacite:alternateIdentifier>
  </xsl:template>

  <!-- LaZAR-Objekttyp "Ort" -->
  <xsl:template match="edb:ort[parent::edb:objects]">
    <datacite:resource>
      <xsl:call-template name="identifier"/>
      <datacite:titles>
        <xsl:for-each select="edb:name[@type='text_l10n_oneline']/*[string()]">
          <xsl:call-template name="title"/>
        </xsl:for-each>
      </datacite:titles>
      <datacite:alternateIdentifiers>
        <xsl:apply-templates select="edb:custom[@name='geonames_uri']" mode="alternateIdentifier"/>
      </datacite:alternateIdentifiers>
      <datacite:resourceType resourceTypeGeneral="Other">http://schema.org/Place</datacite:resourceType>
      <xsl:apply-templates select="edb:exakte_koordinaten"/>
    </datacite:resource>
  </xsl:template>

  <xsl:template match="edb:custom[@name='geonames_uri']" mode="alternateIdentifier">
    <datacite:alternateIdentifier alternateIdentifierType="URI">
      <xsl:value-of select="edb:string[@name='conceptURI']"/>
    </datacite:alternateIdentifier>
  </xsl:template>

  <xsl:template match="edb:exakte_koordinaten[text()]">
    <datacite:GeoLocation>
      <datacite:geoLocationPoint>
        <datacite:pointLatitude>
          <xsl:value-of select="normalize-space(substring-before(.,','))"/>
        </datacite:pointLatitude>
        <datacite:pointLongitude>
          <xsl:value-of select="normalize-space(substring-after(.,','))"/>
        </datacite:pointLongitude>
      </datacite:geoLocationPoint>
    </datacite:GeoLocation>
  </xsl:template>

  <!-- LaZAR-Objekttyp "Objekttyp" -->
  <xsl:template match="edb:objekttyp">
    <datacite:resource
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4/metadata.xsd">
      <!-- required fields -->
      <xsl:call-template name="identifier"/>
      <datacite:creators>
        <xsl:apply-templates select="edb:_nested__objekttyp__urheber/edb:objekttyp__urheber"/>
      </datacite:creators>
      <datacite:titles>
        <xsl:apply-templates select="edb:_nested__objekttyp__titel/edb:objekttyp__titel"/>
      </datacite:titles>
      <xsl:call-template name="publisher"/>
      <xsl:call-template name="publicationYear"/>
      <xsl:call-template name="subjects"/>
      <xsl:call-template name="resourceType"/>
      <!-- optional fields -->
      <xsl:call-template name="contributors"/>
      <xsl:call-template name="descriptions"/>
      <xsl:call-template name="dates"/>
      <xsl:call-template name="languages"/>
      <xsl:call-template name="alternateIdentifiers"/>
      <xsl:call-template name="relatedIdentifiers"/>
      <xsl:call-template name="size"/>
      <xsl:apply-templates select="edb:version"/>
      <xsl:call-template name="rights"/>
    </datacite:resource>
  </xsl:template>

  <!-- 1 Identifier (required) -->
  <xsl:template name="identifier">
    <datacite:identifier>
      <xsl:choose>
        <xsl:when test="false()">
          <xsl:attribute name="identifierType">DOI</xsl:attribute>
          <!-- TODO: DOI -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="identifierType">URI</xsl:attribute>
          <xsl:text>https://lazar.gbv.de/id/</xsl:text>
          <xsl:value-of select="edb:_uuid"/>
        </xsl:otherwise>
      </xsl:choose>
    </datacite:identifier>
  </xsl:template>
 
  <!-- 2 Creator (required) -->
  <xsl:template match="edb:objekttyp__urheber">
    <datacite:creator>
      <xsl:apply-templates select="edb:urheber/edb:person_urheber"/>
      <!-- 2.3 affiliation -->
      <!-- TODO: affiliation is not available anymore!? -->
      <xsl:variable name="affiliation"
           select="edb:affiliation/edb:affiliation/edb:_standard/*[text()][1]"/>
      <xsl:if test="$affiliation">
        <datacite:affiliation>
          <xsl:value-of select="$affiliation"/>
        </datacite:affiliation>
      </xsl:if> 
    </datacite:creator>
  </xsl:template>

  <xsl:template match="edb:person_urheber">
    <!-- 2.1 creatorName -->
    <datacite:creatorName>
      <xsl:value-of select="edb:name[@type='text_oneline']"/>
    </datacite:creatorName>
    <!-- 2.2 nameIdentifier -->
    <xsl:apply-templates select="edb:custom"/>
  </xsl:template>

  <xsl:template match="edb:custom[@name='orcid']">
    <datacite:nameIdentifier nameIdentifierScheme="ORCID" schemeURI="http://orcid.org/">
      <xsl:value-of select="edb:string[@name='url']"/>
    </datacite:nameIdentifier>
  </xsl:template>

  <xsl:template match="edb:custom[@name='orcid']" mode="alternateIdentifier">
    <datacite:alternateIdentifier alternateIdentifierType="URI">
      <xsl:value-of select="edb:string[@name='url']"/>
    </datacite:alternateIdentifier>
  </xsl:template>

  <xsl:template match="edb:custom[@name='gnd']">
    <datacite:nameIdentifier nameIdentifierScheme="GND" schemeURI="http://d-nb.info/gnd/">
      <xsl:value-of select="edb:string[@name='conceptURI']"/>
    </datacite:nameIdentifier>
  </xsl:template>

  <xsl:template match="edb:custom[@name='gnd']" mode="alternateIdentifier">
    <datacite:alternateIdentifier alternateIdentifierType="URI">
      <xsl:value-of select="edb:string[@name='conceptURI']"/>
    </datacite:alternateIdentifier>
  </xsl:template>

  <xsl:template match="edb:custom[@name='grid']">
    <datacite:nameIdentifier nameIdentifierScheme="GRID"> <!-- TODO: schemeURI -->
      <xsl:value-of select="edb:string[@name='url']"/>    <!-- TODO: not tested yet -->
    </datacite:nameIdentifier>
  </xsl:template>

  <xsl:template match="edb:custom[@name='grib']" mode="alternateIdentifier">
    <datacite:alternateIdentifier alternateIdentifierType="URI">
      <xsl:value-of select="edb:string[@name='url']"/>
    </datacite:alternateIdentifier>
  </xsl:template>

  <!-- 3 Title (required) -->
  <xsl:template match="edb:objekttyp__titel">
    <xsl:for-each select="edb:titel/*[string()]">
      <xsl:call-template name="title"/>
    </xsl:for-each> 
  </xsl:template>

  <xsl:template name="title">
    <xsl:variable name="lang">
      <xsl:choose>
        <xsl:when test="substring-before(local-name(),'-')">
          <xsl:value-of select="substring-before(local-name(),'-')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="local-name()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <datacite:title xml:lang="{$lang}">
      <xsl:value-of select="."/>
    </datacite:title>
  </xsl:template>

  <!-- 4 Publisher (required) -->
  <xsl:template name="publisher">
    <datacite:publisher>LaZAR</datacite:publisher>
  </xsl:template>

  <!-- 5 Publication Year (required) -->
  <xsl:template name="publicationYear">
    <xsl:variable name="dates" select="edb:_nested__objekttyp__datum/edb:objekttyp__datum"/>
    <xsl:variable name="pubdates" select="$dates[edb:datumstyp/edb:datumstyp/edb:name/edb:de-DE='Publikationsdatum']"/>
    <xsl:variable name="year" select="substring($pubdates/edb:anfang,1,4)"/>
    <xsl:if test="string($year)">
      <datacite:publicationYear>
        <xsl:value-of select="$year"/>
      </datacite:publicationYear>
    </xsl:if>
    <xsl:if test="not($year)">
      <!-- just take the last date in the list -->
      <datacite:publicationYear>
        <xsl:copy-of select="substring($dates[last()]/edb:anfang,1,4)"/>
      </datacite:publicationYear>
    </xsl:if>
  </xsl:template>

  <!-- 6 Subject (required) -->
  <xsl:template name="subjects">

    <!-- TODO: add orte, methoden, affiliation, easydb:thema -->

    <xsl:variable name="gnd" select="edb:_nested__objekttyp__keywords_gnd/edb:objekttyp__keywords_gnd"/>
    <xsl:variable name="getty" select="edb:_nested__objekttyp__keywords_getty/edb:objekttyp__keywords_getty"/>

    <xsl:if test="$gnd|$getty">
      <datacite:subjects>
        <xsl:for-each select="$gnd">
          <datacite:subject schemeURI="http://bartoc.org/en/node/430">
            <xsl:apply-templates select="edb:custom[@name='keyword']"/>
          </datacite:subject>
        </xsl:for-each>
        <xsl:for-each select="$getty">
          <datacite:subject schemeURI="http://vocab.getty.edu/dataset/aat">
            <xsl:apply-templates select="edb:custom[@name='keyword']"/>
          </datacite:subject>
        </xsl:for-each>
      </datacite:subjects>
    </xsl:if>
  </xsl:template>

  <xsl:template match="edb:custom[@name='keyword']">
    <xsl:variable name="uri" select="edb:string[@name='conceptURI']"/>
    <xsl:if test="$uri">
      <xsl:attribute name="valueURI">
        <xsl:value-of select="$uri"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:value-of select="edb:string[@name='conceptName']"/>
  </xsl:template>

  <!-- 7 Contributor (optional) -->
  <xsl:template name="contributors">
    <xsl:variable name="contributors" 
                  select="edb:_nested__objekttyp__contributor/edb:objekttyp__contributor"/>
    <xsl:if test="$contributors">
      <datacite:contributors>
        <xsl:for-each select="$contributors">
          <xsl:variable name="person" select="edb:person/edb:person_urheber"/>
          <xsl:variable name="role">
            <xsl:apply-templates select="edb:rolle/edb:person_rolle"/>
          </xsl:variable>
          <datacite:contributor>
            <xsl:attribute name="contributorType">
              <xsl:if test="$role != 'Translator'">
                <xsl:value-of select="$role"/>
              </xsl:if>
              <xsl:if test="$role = 'Translator'">Other</xsl:if>
            </xsl:attribute>
            <datacite:contributorName>
              <xsl:value-of select="$person/edb:name[@type='text_oneline']"/>
            </datacite:contributorName>
            <!-- nameIdentifier -->
            <xsl:apply-templates select="$person/edb:custom"/>
          </datacite:contributor>
          <!-- TODO: affiliation -->
        </xsl:for-each>
      </datacite:contributors>
    </xsl:if>
  </xsl:template>

  <xsl:template match="edb:person_rolle">
    <xsl:value-of select="edb:name/edb:en-US"/>
  </xsl:template>

  <!-- 8 Date (optional) -->
  <xsl:template name="dates">
    <!-- Entstehungs- und/oder Publikationsdatum -->
    <xsl:variable name="dates" select="edb:_nested__objekttyp__datum/edb:objekttyp__datum"/>
    <xsl:if test="$dates">
      <datacite:dates>
        <xsl:for-each select="$dates">
          <datacite:date>
            <xsl:attribute name="dateType">
              <xsl:choose>
                <xsl:when test="edb:datumstyp/edb:datumstyp[_id='2']">Issued</xsl:when>
                <xsl:otherwise>Created</xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
            <!-- Datumswert, ggf. als Zeitraum -->
            <xsl:value-of select="edb:anfang"/>
            <xsl:if test="string(edb:ende)">
              <xsl:text>/</xsl:text>
              <xsl:value-of select="edb:ende"/>
            </xsl:if>
          </datacite:date>
        </xsl:for-each>
      </datacite:dates>
    </xsl:if>
  </xsl:template>

  <!-- 9 Language (optional) -->
  <xsl:template name="languages">
    <!-- DataCite only wants a primary language. WTF? -->
    <xsl:variable name="sprachen"
      select="edb:_nested__objekttyp__sprachen/edb:objekttyp__sprachen[1]/edb:sprache/edb:sprache"/>
    <xsl:for-each select="$sprachen/edb:isocode[string-length(text()) > 0]">
      <datacite:language>
        <xsl:value-of select="."/>
      </datacite:language>
    </xsl:for-each>
  </xsl:template>

  <!-- 10 Resource Type (required) -->
  <xsl:template name="resourceType">
    <xsl:choose>
      <!-- Konvolut -->
     <xsl:when test="edb:tags/edb:tag[@id='1']"> <!-- TODO -->
        <datacite:resourceType resourceTypeGeneral="Collection">Collection</datacite:resourceType>
      </xsl:when>
      <!-- Datei oder Ausschnitt -->
      <xsl:otherwise>
        <xsl:variable name="class" select="edb:datei/edb:files/edb:file/edb:class"/>
        <!-- Datei-Klasse -->
        <xsl:variable name="type">
          <xsl:choose>
            <xsl:when test="$class='image'">Image</xsl:when>
            <xsl:when test="$class='video'">Audiovisual</xsl:when>
            <!-- not tested! -->
            <xsl:when test="$class='audio'">Sound</xsl:when>
            <!-- not tested! -->
            <xsl:when test="$class='office'">Text</xsl:when>
            <xsl:otherwise>Other</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <datacite:resourceType resourceTypeGeneral="{$type}">
          <xsl:value-of select="$type"/>
        </datacite:resourceType>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- 11 AlternativeIdentifier (optional) -->
  <xsl:template name="alternateIdentifiers">
    <datacite:alternateIdentifiers>
      <datacite:alternateIdentifier alternateIdentifierType="LaZAR URL">
        <xsl:value-of select="edb:_urls/edb:url[@type='easydb-id']"/>
      </datacite:alternateIdentifier>
      <datacite:alternateIdentifier alternateIdentifierType="UUID">
        <xsl:value-of select="edb:_uuid"/>
      </datacite:alternateIdentifier>
      <xsl:for-each select="edb:_nested__objekttyp__alternative_id/edb:objekttyp__alternative_id">
        <datacite:alternateIdentifier alternateIdentifierType="unknown">
          <xsl:value-of select="edb:name"/>
        </datacite:alternateIdentifier>
      </xsl:for-each>
    </datacite:alternateIdentifiers>
  </xsl:template>

  <!-- 12 RelatedIdentifier (optional) -->
  <xsl:template name="relatedIdentifiers">
    <datacite:relatedIdentifiers>
      <!-- Deep Link to record view in easydb -->
      <datacite:relatedIdentifier relatedIdentifierType="URL" relationType="IsIdenticalTo">
        <xsl:value-of select="edb:_urls/edb:url[@type='easydb-id']"/>
      </datacite:relatedIdentifier>

      <xsl:if test="edb:tags/edb:tag[@id='2']">
        <datacite:relatedIdentifier relatedIdentifierType="URL" relationType="IsIdenticalTo">
          <xsl:value-of select="edb:datei/edb:files/edb:file/edb:versions/edb:version[1]/edb:deep_link_url"/>
        </datacite:relatedIdentifier>
      </xsl:if>
    </datacite:relatedIdentifiers>
  </xsl:template>

  <!-- 13 Size (optional) -->
  <xsl:template name="size">
    <xsl:variable name="size">
      <xsl:choose>
        <!-- Datei -->
        <xsl:when test="edb:tags/edb:tag[@id='2']">
          <xsl:value-of select="substring-after(edb:datei/edb:files/edb:file/edb:compiled,', ')"/>
        </xsl:when>
        <!-- TODO: Konvolute und Ausschnitte? -->
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="string($size)">
      <datacite:sizes>
        <datacite:size>
          <xsl:value-of select="$size"/>
        </datacite:size>
      </datacite:sizes>
    </xsl:if>
  </xsl:template>

  <!-- 14 Format (optional): TODO -->

  <!-- 15 Version (optional) -->
  <xsl:template match="edb:version">
    <datacite:version>
      <xsl:value-of select="."/>
    </datacite:version>
  </xsl:template>

  <!-- 16 Rights (optional) -->
  <xsl:template name="rights">
    <xsl:choose>
      <xsl:when test="edb:tags/edb:tag[@id='10']">
        <datacite:rightsList>
          <datacite:rights rightsURI="https://creativecommons.org/publicdomain/zero/1.0/">CC0 1.0 Universal (CC0 1.0) Public Domain Dedication</datacite:rights>
        </datacite:rightsList>
      </xsl:when>
      <xsl:when test="edb:tags/edb:tag[@id='11']">
        <datacite:rightsList>
          <datacite:rights rightsURI="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International (CC BY 4.0)</datacite:rights>
        </datacite:rightsList>
      </xsl:when>
      <xsl:when test="edb:tags/edb:tag[@id='12']">
        <datacite:rightsList>
          <datacite:rights rightsURI="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)</datacite:rights>
        </datacite:rightsList>
      </xsl:when>
      <xsl:when test="edb:tags/edb:tag[@id='13']">
        <datacite:rightsList>
          <datacite:rights rightsURI="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)</datacite:rights>
        </datacite:rightsList>
      </xsl:when>
      <xsl:when test="edb:tags/edb:tag[@id='14']">
        <datacite:rightsList>
          <datacite:rights rightsURI="http://creativecommons.org/licenses/by-nc-nd/4.0/">Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)</datacite:rights>
        </datacite:rightsList>
      </xsl:when>
      <xsl:when test="edb:tags/edb:tag[@id='22']">
        <datacite:rightsList>
          <datacite:rights rightsURI="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)</datacite:rights>
        </datacite:rightsList>
      </xsl:when>
      <xsl:when test="edb:tags/edb:tag[@id='17']">
        <datacite:rightsList>
          <datacite:rights rightsURI="http://creativecommons.org/licenses/by-nd/4.0/">Creative Commons Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)</datacite:rights>
        </datacite:rightsList>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- 17 Description (optional) -->
  <xsl:template name="descriptions">
    <xsl:variable name="descriptions" select="edb:beschreibung/*[string()]"/>
    <!-- TODO: Methoden => Methods -->
    <xsl:if test="$descriptions">
      <datacite:descriptions>
        <xsl:for-each select="$descriptions">
          <xsl:variable name="language" select="substring-before(local-name(),'-')"/>
          <datacite:description descriptionType="Abstract" xml:lang="{$language}">
            <xsl:value-of select="."/>
          </datacite:description>
        </xsl:for-each>
      </datacite:descriptions>
    </xsl:if>
  </xsl:template>

  <!-- 18 Geolocation (optional): TODO -->

  <!-- 19 FundingReference (optional): n/a -->

  <!-- ignore the rest -->
  <xsl:template match="@*|node()"/>

</xsl:stylesheet>
