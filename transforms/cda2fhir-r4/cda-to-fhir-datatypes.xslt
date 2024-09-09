<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cda="urn:hl7-org:v3" xmlns:fhir="http://hl7.org/fhir" xmlns:sdtc="urn:hl7-org:sdtc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:lcg="http://www.lantanagroup.com"
    xmlns:b64="https://github.com/ilyakharlamov/xslt_base64" version="2.0" exclude-result-prefixes="lcg cda fhir xs xsi sdtc xhtml b64">

    <!--***   Date and Time functions and templates  *** -->
    <!-- FUNCTION:  to return date part of a CDA TS -->
    <xsl:function name="lcg:dateFromcdaTS" as="xs:string">
        <!-- Just get the date part, ignoring any time data -->
        <xsl:param name="cdaTS" as="xs:string" />

        <xsl:variable name="date" as="xs:string">
            <xsl:choose>
                <xsl:when test="string-length($cdaTS) > 6">
                    <xsl:value-of select="string-join((substring($cdaTS, 1, 4), substring($cdaTS, 5, 2), substring($cdaTS, 7, 2)), '-')" />
                </xsl:when>
                <xsl:when test="string-length($cdaTS) > 4">
                    <xsl:value-of select="string-join((substring($cdaTS, 1, 4), substring($cdaTS, 5, 2)), '-')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring($cdaTS, 1, 4)" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$date" />
    </xsl:function>

    <!-- FUNCTION:  to convert CDA TS to FHIR date -->
    <xsl:function name="lcg:cdaTS2date" as="xs:string">
        <!-- the FHIR specification allows ignoring seconds, but the FHIR XSD does not -->
        <!-- set seconds to 0 for simplicity, unless seconds are in the CDA time -->
        <xsl:param name="cdaTS" as="xs:string" />

        <xsl:variable name="date" as="xs:string" select="lcg:dateFromcdaTS($cdaTS)" />
        <!-- Get a seconds value if there is one -->
        <xsl:variable name="vSeconds">
            <xsl:choose>
                <xsl:when test="substring($cdaTS, 13, 6) and matches(substring($cdaTS, 13, 6), '\.')">
                    <xsl:sequence select="concat(':', substring($cdaTS, 13, 6))" />
                </xsl:when>
                <xsl:when test="substring($cdaTS, 13, 5) and matches(substring($cdaTS, 13, 5), '\.')">
                    <xsl:sequence select="concat(':', substring($cdaTS, 13, 5), '0')" />
                </xsl:when>
                <xsl:when test="substring($cdaTS, 13, 4) and matches(substring($cdaTS, 13, 4), '\.')">
                    <xsl:sequence select="concat(':', substring($cdaTS, 13, 4), '00')" />
                </xsl:when>
                <xsl:when test="substring($cdaTS, 13, 2) and not(matches(substring($cdaTS, 13, 2), '[-+]'))">
                    <xsl:sequence select="concat(':', substring($cdaTS, 13, 2), '.000')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="':00.000'" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- If there is a + or - this has a TZ -->
            <xsl:when test="matches($cdaTS, '[-+]')">
                <xsl:variable name="time" select="concat(substring($cdaTS, 9, 2), ':', substring($cdaTS, 11, 2), $vSeconds)" as="xs:string" />
                <xsl:variable name="timezone" as="xs:string">
                    <xsl:choose>
                        <xsl:when test="contains($cdaTS, '-')">
                            <xsl:sequence select="concat('-', substring(substring-after($cdaTS, '-'), 1, 2), ':', substring(substring-after($cdaTS, '-'), 3, 2))" />
                        </xsl:when>
                        <xsl:when test="contains($cdaTS, '+')">
                            <xsl:sequence select="concat('+', substring(substring-after($cdaTS, '+'), 1, 2), ':', substring(substring-after($cdaTS, '+'), 3, 2))" />
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:sequence select="concat($date, 'T', $time, $timezone)" />
            </xsl:when>
            <!-- check to make sure the xs:time will work, otherwise this will crash -->
            <xsl:when test="string-length($cdaTS) > 8 and concat(substring($cdaTS, 9, 2), ':', substring($cdaTS, 11, 2), ':00.000') castable as xs:time">
                <xsl:variable name="time" as="xs:time">
                    <xsl:sequence select="adjust-time-to-timezone(xs:time(concat(substring($cdaTS, 9, 2), ':', substring($cdaTS, 11, 2), ':00.000')))" />
                </xsl:variable>
                <xsl:sequence select="concat($date, 'T', format-time($time, '[H01]:[m01]:[s01][Z]'))" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$date" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template name="TS2Date">
        <xsl:param name="ts" />
        <xsl:param name="date-only" select="false()" />
        <xsl:variable name="without-offset">
            <xsl:choose>
                <xsl:when test="contains($ts, '-')">
                    <xsl:value-of select="substring-before(translate($ts, 'T', ''), '-')" />
                </xsl:when>
                <xsl:when test="contains($ts, '+')">
                    <xsl:value-of select="substring-before(translate($ts, 'T', ''), '+')" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$ts" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="default-date-part">
            <xsl:choose>
                <xsl:when test="$date-only" />
                <xsl:otherwise>01</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="default-time-part">
            <xsl:choose>
                <xsl:when test="$date-only" />
                <xsl:otherwise>00</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="year" select="substring($without-offset, 1, 4)" />
        <xsl:variable name="month">
            <xsl:choose>
                <xsl:when test="substring($without-offset, 5, 2)">
                    <xsl:value-of select="substring($without-offset, 5, 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$default-date-part" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="day">
            <xsl:choose>
                <xsl:when test="substring($without-offset, 7, 2)">
                    <xsl:value-of select="substring($without-offset, 7, 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$default-date-part" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="hour">
            <xsl:choose>
                <xsl:when test="substring($without-offset, 9, 2)">
                    <xsl:value-of select="substring($without-offset, 9, 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$default-time-part" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="minute">
            <xsl:choose>
                <xsl:when test="substring($without-offset, 11, 2)">
                    <xsl:value-of select="substring($without-offset, 11, 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$default-time-part" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="second">
            <xsl:choose>
                <xsl:when test="substring($without-offset, 13, 2)">
                    <xsl:value-of select="substring($without-offset, 13, 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$default-time-part" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="offset-direction">
            <xsl:if test="contains($ts, '-')">-</xsl:if>
            <xsl:if test="contains($ts, '+')">+</xsl:if>
        </xsl:variable>
        <xsl:variable name="offset">
            <xsl:choose>
                <xsl:when test="contains($ts, '-')">
                    <xsl:value-of select="translate(substring-after($ts, '-'), ':', '')" />
                </xsl:when>
                <xsl:when test="contains($ts, '+')">
                    <xsl:value-of select="translate(substring-after($ts, '+'), ':', '')" />
                </xsl:when>
                <xsl:otherwise />
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$year" />
        <xsl:if test="$month != ''">
            <xsl:text>-</xsl:text>
            <xsl:value-of select="$month" />
        </xsl:if>
        <xsl:if test="$day != ''">
            <xsl:text>-</xsl:text>
            <xsl:value-of select="$day" />
        </xsl:if>

        <!-- add the time, timezone, 'Z', etc, only if full dateTime -->
        <xsl:if test="not($date-only)">
            <xsl:if test="$hour != ''">
                <xsl:text>T</xsl:text>
                <xsl:value-of select="$hour" />
            </xsl:if>
            <xsl:if test="$minute != ''">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="$minute" />
            </xsl:if>
            <xsl:if test="$second != ''">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="$second" />
            </xsl:if>
            <xsl:choose>
                <xsl:when test="string-length($offset) = 2">
                    <xsl:variable name="offset-hour" select="substring($offset, 1, 2)" />
                    <xsl:value-of select="concat($offset-direction, $offset-hour, ':00')" />
                </xsl:when>
                <xsl:when test="string-length($offset) = 4">
                    <xsl:variable name="offset-hour" select="substring($offset, 1, 2)" />
                    <xsl:variable name="offset-minute" select="substring($offset, 3, 2)" />
                    <xsl:value-of select="concat($offset-direction, $offset-hour, ':', $offset-minute)" />
                </xsl:when>
                <xsl:otherwise>Z</xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE: time -->
    <xsl:template match="cda:time[cda:low/@value or cda:high/@value]">
        <xsl:choose>
            <xsl:when test="cda:low/@value or cda:high/@value">
                <period>
                    <xsl:if test="cda:low/@value">
                        <start value="{lcg:cdaTS2date(cda:low/@value)}" />
                    </xsl:if>
                    <xsl:if test="cda:high/@value and ((cda:high/@value > cda:low/@value) or not(cda:low/@value))">
                        <end value="{lcg:cdaTS2date(cda:high/@value)}" />
                    </xsl:if>
                </period>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>WARNING: Unable to map usablePeriod to a FHIR period</xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: usablePeriod -->
    <xsl:template match="cda:useablePeriod[@value or cda:low/@value or cda:high/@value]">
        <xsl:choose>
            <xsl:when test="@value">
                <period>
                    <start value="{lcg:cdaTS2date(@value)}" />
                    <end value="{lcg:cdaTS2date(@value)}" />
                </period>
            </xsl:when>
            <xsl:when test="cda:low/@value or cda:high/@value">
                <period>
                    <xsl:if test="cda:low/@value">
                        <start value="{lcg:cdaTS2date(cda:low/@value)}" />
                    </xsl:if>
                    <xsl:if test="cda:high/@value and ((cda:high/@value > cda:low/@value) or not(cda:low/@value))">
                        <end value="{lcg:cdaTS2date(cda:high/@value)}" />
                    </xsl:if>
                </period>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>WARNING: Unable to map usablePeriod to a FHIR period</xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:birthTime | sdtc:birthTime">
        <xsl:param name="pElementName">birthDate</xsl:param>
        <xsl:if test="not(@nullFlavor)">
            <xsl:element name="{$pElementName}">
                <xsl:attribute name="value" select="lcg:dateFromcdaTS(@value)" />
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="cda:effectiveTime | cda:time" mode="instant">
        <xsl:param name="pElementName">date</xsl:param>
        <xsl:param name="pDataType" />
        <xsl:choose>
            <xsl:when test="./@value and not(cda:low) and not(cda:center)">
                <xsl:element name="{$pElementName}">
                    <xsl:variable name="vValue">
                        <xsl:value-of select="lcg:cdaTS2date(./@value)" />
                    </xsl:variable>
                    <xsl:attribute name="value">
                        <xsl:choose>
                            <xsl:when test="$pDataType = 'instant' and string-length($vValue) = 10">
                                <xsl:value-of select="concat($vValue, 'T00:00:00Z')" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$vValue" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                </xsl:element>
            </xsl:when>
            <xsl:when test="cda:low/@value and not(@value) and not(cda:center)">
                <xsl:element name="{$pElementName}">
                    <xsl:attribute name="value">
                        <xsl:value-of select="lcg:cdaTS2date(cda:low/@value)" />
                    </xsl:attribute>
                </xsl:element>
            </xsl:when>
            <xsl:when test="cda:center/@value and not(@value) and not(cda:low)">
                <xsl:element name="{$pElementName}">
                    <xsl:attribute name="value">
                        <xsl:value-of select="lcg:cdaTS2date(cda:center/@value)" />
                    </xsl:attribute>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise />
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@value or cda:low or cda:high] | cda:time[@value or cda:low or cda:high]" mode="period">
        <xsl:param name="pElementName">period</xsl:param>
        <xsl:element name="{$pElementName}">
            <xsl:call-template name="effectiveTimeInner" />
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:effectiveTime | cda:time" mode="timingPeriod">
        <timingPeriod>
            <xsl:call-template name="effectiveTimeInner" />
        </timingPeriod>
    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="whenGiven">
        <whenGiven>
            <xsl:call-template name="effectiveTimeInner" />
        </whenGiven>
    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="event">
        <event>
            <xsl:call-template name="effectiveTimeInner" />
        </event>
    </xsl:template>

    <xsl:template match="cda:effectiveTime[@operator = 'A']">
        <repeat>
            <frequency value="1" />
            <xsl:choose>
                <xsl:when test="cda:period/@value and not(cda:period/cda:low) and not(cda:period/cda:high)">
                    <duration>
                        <xsl:attribute name="value">
                            <xsl:value-of select="normalize-space(cda:period/@value)" />
                        </xsl:attribute>
                    </duration>
                </xsl:when>
                <xsl:when test="not(cda:period/@value) and cda:period/cda:low/@value">
                    <duration>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:period/cda:low/@value" />
                        </xsl:attribute>
                    </duration>
                </xsl:when>
                <xsl:when test="not(cda:period/@value) and not(cda:period/cda:low/@value) and cda:period/cda:high/@value">
                    <duration>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:period/cda:high/@value" />
                        </xsl:attribute>
                    </duration>
                </xsl:when>
            </xsl:choose>

            <xsl:choose>
                <xsl:when test="cda:period/@unit and not(cda:period/cda:low) and not(cda:period/cda:high)">
                    <units>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:period/@unit" />
                        </xsl:attribute>
                    </units>
                </xsl:when>
                <xsl:when test="not(cda:period/@unit) and cda:period/cda:low/@unit">
                    <units>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:period/cda:low/@unit" />
                        </xsl:attribute>
                    </units>
                </xsl:when>
                <xsl:when test="not(cda:period/@unit) and not(cda:period/cda:low/@unit) and cda:period/cda:high/@unit">
                    <units>
                        <xsl:attribute name="value">
                            <xsl:value-of select="cda:period/cda:high/@unit" />
                        </xsl:attribute>
                    </units>
                </xsl:when>
            </xsl:choose>
        </repeat>
    </xsl:template>

    <xsl:template match="cda:ClinicalDocument/cda:effectiveTime" mode="observation">
        <xsl:comment>INFO: Using document effective time as issued date</xsl:comment>
        <xsl:apply-templates select="." mode="instant">
            <xsl:with-param name="pElementName">issued</xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template name="effectiveTimeInner">
        <xsl:if test="cda:width/@value and cda:width/@unit = 'weeks' and cda:high">
            <xsl:choose>
                <!-- need this to fail gracefully if an invalid date -->
                <xsl:when test="concat(substring(cda:high/@value, 1, 4), '-', substring(cda:high/@value, 5, 2), '-', substring(cda:high/@value, 7, 2)) castable as xs:date">
                    <!-- Convert date string into date - only care about the first 8 chars -->
                    <xsl:variable name="vDate" select="xs:date(concat(substring(cda:high/@value, 1, 4), '-', substring(cda:high/@value, 5, 2), '-', substring(cda:high/@value, 7, 2)))" />
                    <xsl:variable name="vNumDays" select="7 * cda:width/@value" />
                    <!-- Subtract number of days from start date -->
                    <xsl:variable name="vStartDate" select="format-date(($vDate - $vNumDays * xs:dayTimeDuration('P1D')), '[Y][M][D]')" />
                    <!-- Convert back to a string for futher processing -->
                    <start value="{lcg:cdaTS2date($vStartDate)}" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment>WARNING: Invalid source date</xsl:comment>
                    <start>
                        <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                            <xsl:element name="valueCode">
                                <xsl:attribute name="value">unknown</xsl:attribute>
                            </xsl:element>
                        </extension>
                    </start>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="cda:low[@value]">
            <start value="{lcg:cdaTS2date(cda:low/@value)}" />
        </xsl:if>
        <xsl:if test="cda:high[@value] and ((cda:high/@value > cda:low/@value) or not(cda:low/@value))">
            <end value="{lcg:cdaTS2date(cda:high/@value)}" />
        </xsl:if>
        <xsl:if test="@value and not(cda:low/@value)">
            <start value="{lcg:cdaTS2date(@value)}" />
            <end value="{lcg:cdaTS2date(@value)}" />
        </xsl:if>
        <xsl:if test="cda:center/@value and not(cda:width/@value)">
            <start value="{lcg:cdaTS2date(cda:center/@value)}" />
            <end value="{lcg:cdaTS2date(cda:center/@value)}" />
        </xsl:if>
        <xsl:if test="not(@value) and cda:low/@nullFlavor and cda:high/@nullFlavor">
            <start>
                <xsl:apply-templates select="cda:low/@nullFlavor" mode="data-absent-reason-extension" />
            </start>
            <end>
                <xsl:apply-templates select="cda:low/@nullFlavor" mode="data-absent-reason-extension" />
            </end>
        </xsl:if>
        <xsl:if test="not(@value) and cda:low/@nullFlavor and not(cda:high)">
            <start>
                <xsl:apply-templates select="cda:low/@nullFlavor" mode="data-absent-reason-extension" />
            </start>
        </xsl:if>
    </xsl:template>

    <!-- Helper templates -->
    <xsl:template match="cda:effectiveTime" mode="extension-effectiveTime">
        <extension url="http://lantana.com/fhir/Profile/organizer#effectiveTime">
            <valuePeriod>
                <xsl:if test="cda:low">
                    <start>
                        <xsl:attribute name="value">
                            <xsl:value-of select="lcg:cdaTS2date(cda:low/@value)" />
                        </xsl:attribute>
                    </start>
                </xsl:if>
                <xsl:if test="cda:high and ((cda:high/@value > cda:low/@value) or not(cda:low/@value))">
                    <end>
                        <xsl:attribute name="value">
                            <xsl:value-of select="lcg:cdaTS2date(cda:high/@value)" />
                        </xsl:attribute>
                    </end>
                </xsl:if>
            </valuePeriod>
        </extension>
    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="applies">
        <xsl:choose>
            <xsl:when test="@value and @value != ''">
                <appliesDateTime>
                    <xsl:attribute name="value">
                        <xsl:value-of select="lcg:cdaTS2date(@value)" />
                    </xsl:attribute>
                </appliesDateTime>
            </xsl:when>
            <xsl:when test="(cda:low/@value and not(cda:high/@value)) or cda:low/@value = cda:high/@value">
                <appliesDateTime>
                    <xsl:attribute name="value">
                        <xsl:value-of select="lcg:cdaTS2date(cda:low/@value)" />
                    </xsl:attribute>
                </appliesDateTime>
            </xsl:when>
            <xsl:otherwise>
                <appliesPeriod>
                    <xsl:if test="cda:low">
                        <start>
                            <xsl:attribute name="value">
                                <xsl:value-of select="lcg:cdaTS2date(cda:low/@value)" />
                            </xsl:attribute>
                        </start>
                    </xsl:if>
                    <xsl:if test="cda:high and ((cda:high/@value > cda:low/@value) or not(cda:low/@value))">
                        <end>
                            <xsl:attribute name="value">
                                <xsl:value-of select="lcg:cdaTS2date(cda:high/@value)" />
                            </xsl:attribute>
                        </end>
                    </xsl:if>
                </appliesPeriod>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:effectiveTime" mode="appliesPeriod">
        <appliesPeriod>
            <xsl:choose>
                <xsl:when test="@value and @value != ''">
                    <start>
                        <xsl:attribute name="value">
                            <xsl:value-of select="lcg:cdaTS2date(@value)" />
                        </xsl:attribute>
                    </start>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="cda:low">
                        <start>
                            <xsl:attribute name="value">
                                <xsl:value-of select="lcg:cdaTS2date(cda:low/@value)" />
                            </xsl:attribute>
                        </start>
                    </xsl:if>
                    <xsl:if test="cda:high and ((cda:high/@value > cda:low/@value) or not(cda:low/@value))">
                        <end>
                            <xsl:attribute name="value">
                                <xsl:value-of select="lcg:cdaTS2date(cda:high/@value)" />
                            </xsl:attribute>
                        </end>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </appliesPeriod>
    </xsl:template>

    <!-- TEMPLATE: If effectiveTime has no mode figure out what mode it's supposed to have -->
    <xsl:template match="cda:effectiveTime | cda:time" priority="-1">
        <xsl:param name="pStartElementName" />
        <xsl:choose>
            <xsl:when test="cda:width and cda:high">
                <xsl:apply-templates select="." mode="period">
                    <xsl:with-param name="pElementName" select="concat($pStartElementName, 'Period')" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="@xsi:type = 'IVL_TS'">
                <xsl:apply-templates select="." mode="period">
                    <xsl:with-param name="pElementName" select="concat($pStartElementName, 'Period')" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="cda:low or cda:high">
                <xsl:apply-templates select="." mode="period">
                    <xsl:with-param name="pElementName" select="concat($pStartElementName, 'Period')" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="@value">
                <xsl:apply-templates select="." mode="instant">
                    <xsl:with-param name="pElementName" select="concat($pStartElementName, 'DateTime')" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="@nullFlavor">
                <xsl:comment>INFO: CDA effectiveTime/time was null</xsl:comment>
<!--                <xsl:copy />-->
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>WARNING: Unknown effective time format</xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: Add a leading zero to a real number that start with .
         FHIR doesn't like values such as ".4" -->
    <xsl:template name="add-leading-zero-to-real">
        <xsl:param name="pValue" />
        <xsl:choose>
            <xsl:when test="number($pValue) and starts-with($pValue, '.')">
                <xsl:value-of select="concat('0', $pValue)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$pValue" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: doseQuantity -->
    <xsl:template match="cda:doseQuantity | cda:rateQuantity">
        <!-- RG: Refactoring note - Look for use of this template, and see if we can refactor the whole Dosage datatype out of the resources and into this file -->
        <xsl:param name="pElementName">doseQuantity</xsl:param>
        <xsl:param name="pSimpleQuantity" select="false()" />

        <xsl:if test="$pSimpleQuantity = false() or not(@nullFlavor)">
            <xsl:element name="{$pElementName}">
                <xsl:if test="@value">
                    <value>
                        <xsl:attribute name="value">
                            <xsl:call-template name="add-leading-zero-to-real">
                                <xsl:with-param name="pValue" select="@value" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </value>
                    <!--<xsl:choose>
                        <xsl:when test="@value and starts-with(@value, '.')">
                            <value>
                                <xsl:attribute name="value">
                                    <xsl:value-of select="concat('0', @value)" />
                                </xsl:attribute>
                            </value>
                        </xsl:when>
                        <xsl:when test="@value">
                            <value>
                                <xsl:attribute name="value">
                                    <xsl:value-of select="@value" />
                                </xsl:attribute>
                            </value>
                        </xsl:when>
                    </xsl:choose>-->
                </xsl:if>
                <xsl:if test="@unit">
                    <unit value="{@unit}" />
                </xsl:if>
                <!-- A simple quantity doesn't allow a nullFlavor but we won't be in here if that param was true()-->
                <xsl:if test="@nullFlavor">
                    <code value="{lcg:fcnMapNullFlavor(@nullFlavor)}" />
                    <system value="http://terminology.hl7.org/CodeSystem/v3-NullFlavor" />
                </xsl:if>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE: name -->
    <xsl:template match="cda:name" mode="display">
        <xsl:if test="cda:prefix">
            <xsl:value-of select="cda:prefix" />
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="cda:family and cda:given">
                <xsl:for-each select="cda:given">
                    <xsl:value-of select="." />
                    <xsl:text> </xsl:text>
                </xsl:for-each>
                <xsl:value-of select="cda:family/text()" />
            </xsl:when>
            <xsl:when test="cda:given and not(cda:family)">
                <xsl:value-of select="cda:given" />
            </xsl:when>
            <xsl:when test="cda:family and not(cda:given)">
                <xsl:value-of select="cda:family/text()" />
            </xsl:when>
            <xsl:otherwise>NAME NOT GIVEN</xsl:otherwise>
        </xsl:choose>
        <xsl:if test="cda:suffix">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="cda:suffix" />
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE: name -->
    <xsl:template match="cda:name[not(@nullFlavor)]">
        <xsl:param name="pFamilyRequired" select="false()" />
        <xsl:variable name="name-string">
            <xsl:for-each select="text() | cda:*">
                <xsl:value-of select="normalize-space(.)" />
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="use">
            <xsl:choose>
                <xsl:when test="@use = 'L'">usual</xsl:when>
                <xsl:when test="@use = 'P'">nickname</xsl:when>
                <xsl:when test="descendant::*/@qualifier = 'BR'">maiden</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string-length(normalize-space($name-string)) > 0">
                <name>
                    <xsl:if test="string-length($use) > 0">
                        <use value="{$use}" />
                    </xsl:if>
                    <!--<xsl:if test="string-length(normalize-space(.)) > 0">
                        <xsl:choose>
                            <xsl:when test="cda:*">
                                <text>
                                    <xsl:attribute name="value">
                                        <xsl:value-of select="normalize-space(cda:family)" />
                                        <xsl:text>,</xsl:text>
                                        <xsl:for-each select="cda:suffix">
                                            <xsl:text> </xsl:text>
                                            <xsl:value-of select="normalize-space(.)" />
                                            <xsl-text>,</xsl-text>
                                        </xsl:for-each>
                                        <xsl:for-each select="cda:prefix">
                                            <xsl:text> </xsl:text>
                                            <xsl:value-of select="normalize-space(.)" />
                                        </xsl:for-each>
                                        <xsl:for-each select="cda:given">
                                            <xsl:text> </xsl:text>
                                            <xsl:value-of select="normalize-space(.)" />
                                        </xsl:for-each>
                                        <xsl:if test="string-length($use) > 0">
                                            <text> (</text>
                                            <xsl:value-of select="$use" />
                                            <text> name)</text>
                                        </xsl:if>
                                    </xsl:attribute>
                                </text>
                            </xsl:when>
                            <xsl:otherwise>
                                <text value="{$name-string}" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>-->
                    <xsl:choose>
                        <!-- US Core Practitioner requires a Family, so if it's not present add a DAR
                                 pFamilyRequired parameter = true()-->
                        <xsl:when test="string-length(cda:family) &gt; 0">
                            <family value="{cda:family}" />
                        </xsl:when>
                        <xsl:when test="$pFamilyRequired">
                            <family>
                                <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                                    <valueCode value="unknown" />
                                </extension>
                            </family>
                        </xsl:when>
                        <xsl:otherwise />
                    </xsl:choose>
                    <!--</xsl:for-each>-->
                    <xsl:for-each select="cda:given">
                        <xsl:if test="string-length(.) &gt; 0">
                            <given value="{.}" />
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:for-each select="cda:prefix">
                        <xsl:if test="string-length(.) &gt; 0">
                            <prefix value="{.}" />
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:for-each select="cda:suffix">
                        <xsl:if test="string-length(.) &gt; 0">
                            <suffix value="{.}" />
                        </xsl:if>
                    </xsl:for-each>
                </name>
            </xsl:when>
            <xsl:when test="cda:*[@nullFlavor]">
                <name>
                    <xsl:for-each select="cda:family">
                        <xsl:if test="@nullFlavor">
                            <family>
                                <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                            </family>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:for-each select="cda:given">
                        <xsl:if test="@nullFlavor">
                            <given>
                                <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                            </given>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:for-each select="cda:prefix">
                        <xsl:if test="@nullFlavor">
                            <prefix>
                                <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                            </prefix>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:for-each select="cda:suffix">
                        <xsl:if test="@nullFlavor">
                            <suffix>
                                <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                            </suffix>
                        </xsl:if>
                    </xsl:for-each>
                </name>

            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE: telecom -->
    <xsl:template match="cda:telecom">
        <xsl:variable name="type">
            <xsl:choose>
                <xsl:when test="contains(@value, ':')">
                    <xsl:value-of select="substring-before(@value, ':')" />
                </xsl:when>
                <xsl:otherwise>tel</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="value">
            <xsl:choose>
                <xsl:when test="contains(@value, 'http')">
                    <xsl:value-of select="normalize-space(@value)" />
                </xsl:when>
                <xsl:when test="contains(@value, ':')">
                    <!-- Added normalize-space to trim spaces -->
                    <xsl:value-of select="normalize-space(substring-after(@value, ':'))" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@value" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="@nullFlavor">
                <telecom>
                    <!-- US Core forces a system value if telecom is present -->
                    <system value="other" />
                    <value>
                        <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                    </value>
                </telecom>
            </xsl:when>
            <xsl:otherwise>
                <telecom>
                    <system>
                        <xsl:attribute name="value">
                            <xsl:choose>
                                <xsl:when test="lower-case($type) = 'tel'">phone</xsl:when>
                                <xsl:when test="lower-case($type) = 'mailto'">email</xsl:when>
                                <xsl:when test="lower-case($type) = 'http'">url</xsl:when>
                                <xsl:when test="lower-case($type) = 'https'">url</xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="lower-case($type)" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                    </system>
                    <value>
                        <xsl:choose>
                            <xsl:when test="@value">
                                <xsl:attribute name="value">
                                    <xsl:value-of select="$value" />
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- TODO: Believe this extension needs to appear 1st in the datatype resource -->
                                <!-- this appears to cause problems with the FHIR->JSON converter -->
                                <!--<extension url="http://terminology.hl7.org/CodeSystem/v3-NullFlavor"> 
									<valueCode value="UNK"/>
								</extension>-->
                                <xsl:attribute name="value">Unknown</xsl:attribute>
                            </xsl:otherwise>
                        </xsl:choose>
                    </value>
                    <xsl:if test="@use">
                        <use>
                            <xsl:attribute name="value">
                                <xsl:choose>
                                    <xsl:when test="@use = 'H' or @use = 'HP' or @use = 'HV'">home</xsl:when>
                                    <xsl:when test="@use = 'WP' or @use = 'DIR' or @use = 'PUB'">work</xsl:when>
                                    <xsl:when test="@use = 'MC'">mobile</xsl:when>
                                    <!-- default to work -->
                                    <xsl:otherwise>work</xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                        </use>
                    </xsl:if>
                    <xsl:apply-templates select="cda:useablePeriod" />
                </telecom>
            </xsl:otherwise>

        </xsl:choose>
    </xsl:template>

    <!-- TEMPLATE:addr -->
    <xsl:template match="cda:addr[not(@nullFlavor)]">
        <xsl:param name="pElementName">address</xsl:param>
        <xsl:param name="pExtraText" />

        <xsl:variable name="addr-string">
            <xsl:for-each select="text() | cda:*">
                <xsl:value-of select="normalize-space(.)" />
            </xsl:for-each>
        </xsl:variable>
        <xsl:if test="string-length($addr-string) > 0 or string-length($pExtraText) > 0">
            <xsl:element name="{$pElementName}">
                <xsl:if test="@use">
                    <use>
                        <xsl:attribute name="value">
                            <xsl:choose>
                                <xsl:when test="@use = 'H' or @use = 'HP' or @use = 'HV'">home</xsl:when>
                                <xsl:when test="@use = 'WP' or @use = 'DIR' or @use = 'PUB'">work</xsl:when>
                                <!-- default to work -->
                                <xsl:otherwise>work</xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                    </use>
                </xsl:if>
                <xsl:if test="string-length($pExtraText)">
                    <text value="{normalize-space($pExtraText)}" />
                </xsl:if>
                <xsl:for-each select="cda:streetAddressLine[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <line value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:city[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <city value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:county[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <!-- SG: Updating this from county to district - no county in FHIR -->
                        <district value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:state[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <state value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:postalCode[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <postalCode value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="cda:country[not(@nullFlavor)]">
                    <xsl:if test="string-length(.) &gt; 0">
                        <country value="{normalize-space(.)}" />
                    </xsl:if>
                </xsl:for-each>
                <xsl:apply-templates select="cda:useablePeriod" />
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- TEMPLATE:addr -->
    <xsl:template match="
            cda:addr[@nullFlavor] |
            cda:addr[cda:streetAddressLine[@nullFlavor]] |
            cda:addr[cda:city[@nullFlavor]] |
            cda:addr[cda:county[@nullFlavor]] |
            cda:addr[cda:state[@nullFlavor]] |
            cda:addr[cda:postalCode[@nullFlavor]] |
            cda:addr[country[@nullFlavor]]">
        <xsl:param name="pElementName">address</xsl:param>

        <xsl:element name="{$pElementName}">
            <xsl:if test="@use">
                <use>
                    <xsl:attribute name="value">
                        <xsl:choose>
                            <xsl:when test="@use = 'H' or @use = 'HP' or @use = 'HV'">home</xsl:when>
                            <xsl:when test="@use = 'WP' or @use = 'DIR' or @use = 'PUB'">work</xsl:when>
                            <!-- default to work -->
                            <xsl:otherwise>work</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                </use>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="@nullFlavor">
                    <xsl:apply-templates select="." mode="data-absent-reason-extension" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="cda:streetAddressLine[@nullFlavor]">
                        <line>
                            <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                        </line>
                    </xsl:for-each>
                    <xsl:for-each select="cda:city[@nullFlavor]">
                        <city>
                            <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                        </city>
                    </xsl:for-each>
                    <xsl:for-each select="cda:county[@nullFlavor]">
                        <district>
                            <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                        </district>
                    </xsl:for-each>
                    <xsl:for-each select="cda:state[@nullFlavor]">
                        <state>
                            <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                        </state>
                    </xsl:for-each>
                    <xsl:for-each select="cda:postalCode[@nullFlavor]">
                        <postalCode>
                            <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                        </postalCode>
                    </xsl:for-each>
                    <xsl:for-each select="cda:country[@nullFlavor]">
                        <country>
                            <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                        </country>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="cda:useablePeriod" />
        </xsl:element>


    </xsl:template>

    <!-- TEMPLATE: id, setId -->
    <xsl:template match="cda:id | cda:setId">
        <xsl:param name="pElementName">identifier</xsl:param>

        <xsl:variable name="oid" select="@root" />
        <xsl:variable name="value">
            <xsl:choose>
                <xsl:when test="$oid = '2.16.840.1.113883.4.873'">
                    <xsl:call-template name="get-substring-after-last">
                        <xsl:with-param name="pString" select="@extension" />
                        <xsl:with-param name="pDelimiter" select="'/'" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="lower-case(@extension)" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="root-uri">
            <xsl:choose>
                <!-- SG 2023-11-15: Updating the below based on the rules here: 
                    https://build.fhir.org/ig/HL7/ccda-on-fhir/mappingGuidance.html (see: CDA id → FHIR Identifier with Example Mapping) Case: "Root = URI OID, Value = URL"-->
                <xsl:when test="$oid = '2.16.840.1.113883.4.873'">
                    <xsl:value-of select="substring-before(@extension, concat('/', $value))" />
                </xsl:when>
                <xsl:when test="key('oid-uri-mapping-key', $oid)">
                    <xsl:value-of select="key('oid-uri-mapping-key', $oid)[1]/@uri" />
                </xsl:when>
                <!--<xsl:when test="$oid-uri-mapping/map[@oid = $oid]">
                    <xsl:value-of select="$oid-uri-mapping/map[@oid = $oid][1]/@uri" />
                </xsl:when>-->
                <xsl:when test="contains(@root, '.')">
                    <xsl:text>urn:oid:</xsl:text>
                    <xsl:value-of select="@root" />
                </xsl:when>
                <xsl:when test="not(@root) and not(@extension) and @nullFlavor" />
                <xsl:otherwise>
                    <xsl:text>urn:uuid:</xsl:text>
                    <xsl:value-of select="lower-case(@root)" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string-length($root-uri) > 0 and @nullFlavor">
                <xsl:element name="{$pElementName}">
                    <system value="{lower-case($root-uri)}" />
                    <value>
                        <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                    </value>
                </xsl:element>
            </xsl:when>
            <xsl:when test="@nullFlavor">
                <xsl:element name="{$pElementName}">
                    <system>
                        <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                    </system>
                    <value>
                        <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                    </value>
                </xsl:element>
            </xsl:when>
            <!-- Check assigningAuthorityName first -->
            <xsl:when test="@root and @extension and @assigningAuthorityName">
                <xsl:element name="{$pElementName}">
                    <system value="{lower-case($root-uri)}" />
                    <value value="{$value}" />
                    <assigner>
                        <display value="{@assigningAuthorityName}" />
                    </assigner>
                </xsl:element>
            </xsl:when>
            <!-- If no assigningAuthorityName -->
            <xsl:when test="@root and @extension">
                <xsl:element name="{$pElementName}">
                    <system value="{lower-case($root-uri)}" />
                    <value value="{$value}" />
                </xsl:element>
            </xsl:when>
            <xsl:when test="@root and not(@extension)">
                <xsl:element name="{$pElementName}">
                    <system value="urn:ietf:rfc:3986" />
                    <value value="{$root-uri}" />
                </xsl:element>
            </xsl:when>
            <xsl:when test="@extension and not(@root)">
                <xsl:element name="{$pElementName}">
                    <value value="{$value}" />
                </xsl:element>
            </xsl:when>
        </xsl:choose>

    </xsl:template>

    <!-- TEMPLATE: All different kinds of code
    cda:raceCode, sdtc:raceCode are used in mode extension-raceCode, which calls this template 
     Param: pElementName - defaults to CodeableConcept - name of outer element
     Param: pIncludeCoding - defaults to true whether or not to include a coding element as the inner element 
  -->
    <xsl:template match="
            cda:code | cda:confidentialityCode | cda:maritalStatusCode | cda:routeCode | cda:raceCode | sdtc:raceCode |
            cda:ethnicGroupCode | cda:religiousAffiliationCode | cda:targetSiteCode | cda:priorityCode | cda:translation |
            cda:methodCode | cda:approachSiteCode | sdtc:functionCode | cda:functionCode | cda:dischargeDispositionCode | sdtc:dischargeDispositionCode">
        <xsl:param name="pElementName" select="'CodeableConcept'" />
        <xsl:param name="pIncludeCoding" select="true()" />
        <xsl:param name="pRequireDataAbsentReason" select="false()" />
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName" select="$pElementName" />
            <xsl:with-param name="pIncludeCoding" select="$pIncludeCoding" />
            <xsl:with-param name="pRequireDataAbsentReason" select="$pRequireDataAbsentReason" />
        </xsl:call-template>
    </xsl:template>

    <!-- TEMPLATE (named):newCreateCodeableConcept - creates a codeableConcept element-->
    <xsl:template name="newCreateCodableConcept">
        <xsl:param name="pElementName" />
        <xsl:param name="pIncludeCoding" select="true()" />
        <xsl:param name="includeTranslations" select="true()" />
        <xsl:param name="pRequireDataAbsentReason" select="false()" />
        <!--<xsl:variable name="originalTextReference">
            <xsl:value-of select="substring(cda:originalText/cda:reference/@value, 2)" />
        </xsl:variable>-->
        <xsl:variable name="originalText">
            <xsl:choose>
                <xsl:when test="cda:originalText/cda:reference">
                    <xsl:call-template name="get-reference-text">
                        <xsl:with-param name="pTextElement" select="cda:originalText" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="cda:originalText">
                    <xsl:value-of select="cda:originalText" />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="isValue" select="false()" />
        <xsl:variable name="vCode" select="@code" />
        <xsl:variable name="display">
            <xsl:apply-templates select="@displayName" />
        </xsl:variable>
        <xsl:variable name="content">
            <xsl:call-template name="createCodeableConceptContent">
                <xsl:with-param name="codeSystem" select="@codeSystem" />
                <xsl:with-param name="code" select="@code" />
                <xsl:with-param name="displayName" select="$display" />
                <xsl:with-param name="isValue" select="$isValue" />
                <!--                <xsl:with-param name="pNullFlavor" select="$vNullFlavor" />-->
                <xsl:with-param name="pRequireDataAbsentReason" select="$pRequireDataAbsentReason" />
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="translations">
            <xsl:for-each select="cda:translation | cda:code">
                <xsl:variable name="vTranslationCode" select="@code" />
                <xsl:variable name="vTranslationDisplay">
                    <xsl:choose>
                        <xsl:when test="$code-display-mapping/map[@code = $vTranslationCode]">
                            <xsl:value-of select="$code-display-mapping/map[@code = $vTranslationCode]/@display" />
                        </xsl:when>
                        <xsl:when test="@displayName">
                            <xsl:value-of select="normalize-space(@displayName)" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="normalize-space(cda:originalText)" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!--<xsl:variable name="vNullFlavorInTranslation">
                    <xsl:choose>
                        <xsl:when test="not(@nullFlavor) and not(@code) and not(@codeSystem)">NI</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@nullFlavor" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>-->
                <xsl:variable name="this-translation">
                    <xsl:call-template name="createCodeableConceptContent">
                        <xsl:with-param name="codeSystem" select="@codeSystem" />
                        <xsl:with-param name="code" select="@code" />
                        <xsl:with-param name="displayName" select="$vTranslationDisplay" />
                        <xsl:with-param name="isValue" select="$isValue" />
                        <!--                        <xsl:with-param name="pNullFlavor" select="$vNullFlavorInTranslation" />-->
                        <xsl:with-param name="pRequireDataAbsentReason" />
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$pIncludeCoding = true()">
                        <coding>
                            <xsl:copy-of select="$this-translation" />
                        </coding>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$this-translation" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>

        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="$pIncludeCoding = true()">
                    <coding>
                        <xsl:copy-of select="$content" />
                    </coding>
                    <xsl:if test="$includeTranslations">
                        <xsl:copy-of select="$translations" />
                    </xsl:if>
                    <xsl:if test="string-length($originalText) &gt; 0 and normalize-space($originalText) != ''">
                        <xsl:element name="text">
                            <xsl:attribute name="value">
                                <xsl:value-of select="normalize-space($originalText)" />
                            </xsl:attribute>
                        </xsl:element>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$content" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>

    </xsl:template>
    <xsl:template name="createCodeableConcept">
        <xsl:param name="pSystem" />
        <xsl:param name="pCode" />
        <xsl:param name="pDisplay" />
        <xsl:param name="pText" />
        <xsl:param name="pInnerElement" select="'coding'" />
        <xsl:param name="pOuterElement" select="'CodeableConcept'" />

        <xsl:element name="{$pOuterElement}">
            <xsl:call-template name="createCoding">
                <xsl:with-param name="pSystem" select="$pSystem" />
                <xsl:with-param name="pCode" select="$pCode" />
                <xsl:with-param name="pDisplay" select="$pDisplay" />
                <xsl:with-param name="pElement" select="$pInnerElement" />
            </xsl:call-template>
            <xsl:if test="$pText">
                <text>
                    <xsl:value-of select="$pText" />
                </text>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template name="createCoding">
        <xsl:param name="pSystem" />
        <xsl:param name="pCode" />
        <xsl:param name="pDisplay" />
        <xsl:param name="pElement" />

        <xsl:element name="{$pElement}">
            <system>
                <xsl:attribute name="value" select="$pSystem" />
            </system>
            <code>
                <xsl:attribute name="value" select="$pCode" />
            </code>
            <display>
                <xsl:attribute name="value" select="$pDisplay" />
            </display>
        </xsl:element>
    </xsl:template>

    <xsl:template name="createCodeableConceptContent">
        <xsl:param name="codeSystem" />
        <xsl:param name="code" />
        <xsl:param name="displayName" />
        <xsl:param name="isValue" select="false()" />
        <!--        <xsl:param name="pNullFlavor" />-->
        <xsl:param name="pRequireDataAbsentReason" select="false()" />

        <xsl:choose>
            <xsl:when test="($pRequireDataAbsentReason and not($code) and not($codeSystem)) or (@nullFlavor and (not($code) or not($codeSystem)))">
                <xsl:choose>
                    <xsl:when test="not(@nullFlavor)">
                        <extension url="http://hl7.org/fhir/StructureDefinition/data-absent-reason">
                            <valueCode value="unknown" />
                        </extension>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="codeOrValueElementName">
                    <xsl:choose>
                        <xsl:when test="not($isValue)">code</xsl:when>
                        <xsl:otherwise>value</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:if test="$codeSystem">
                    <system>
                        <xsl:attribute name="value">
                            <xsl:call-template name="convertOID">
                                <xsl:with-param name="oid" select="$codeSystem" />
                            </xsl:call-template>
                        </xsl:attribute>
                    </system>
                </xsl:if>
                <xsl:if test="$code">
                    <xsl:element name="{$codeOrValueElementName}">
                        <xsl:attribute name="value">
                            <xsl:value-of select="$code" />
                        </xsl:attribute>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="string-length($displayName) > 0">
                    <display>
                        <xsl:attribute name="value">
                            <xsl:value-of select="$displayName" />
                        </xsl:attribute>
                    </display>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="cda:administrativeGenderCode">
        <xsl:param name="pElementName">gender</xsl:param>
        <xsl:variable name="cda-gender" select="@code" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="$cda-gender = 'M'">
                    <xsl:attribute name="value">male</xsl:attribute>
                </xsl:when>
                <xsl:when test="$cda-gender = 'F'">
                    <xsl:attribute name="value">female</xsl:attribute>
                </xsl:when>
                <xsl:when test="$cda-gender = 'UN'">
                    <xsl:attribute name="value">other</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="value">unknown</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:interpretationCode">
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName" select="'interpretation'" />
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'INT']" mode="scale">
        <xsl:param name="pElementName" select="'valueQuantity'" />
        <xsl:element name="{$pElementName}">
            <value>
                <xsl:attribute name="value">
                    <xsl:value-of select="@value" />
                </xsl:attribute>
            </value>
            <system value="http://unitsofmeasure.org" />
            <code>
                <xsl:attribute name="value">{score}</xsl:attribute>
            </code>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'TS']">
        <xsl:param name="pElementName" select="'valueDateTime'" />
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="value">
                <xsl:value-of select="lcg:cdaTS2date(@value)" />
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'BL']">
        <xsl:param name="pElementName" select="'valueBoolean'" />
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="value">
                <xsl:value-of select="@value" />
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'ST' or @xsi:type = 'ED']">
        <xsl:param name="pElementName" select="'valueString'" />
        <xsl:variable name="content">
            <xsl:choose>
                <xsl:when test="@nullFlavor">
                    <xsl:value-of select="@nullFlavor" />
                </xsl:when>
                <xsl:when test="cda:reference">
                    <xsl:call-template name="get-reference-text">
                        <xsl:with-param name="pTextElement" select="." />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="." />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="value">
                <xsl:value-of select="$content" />
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'INT'] | cda:sequenceNumber">
        <xsl:param name="pElementName" select="'valueInteger'" />
        <xsl:element name="{$pElementName}">
            <xsl:attribute name="value">
                <xsl:value-of select="@value" />
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'PQ'][not(@nullFlavor)]">
        <xsl:param name="pElementName" select="'valueQuantity'" />
        <xsl:param name="pVitalSign" select="false()" />

        <!-- Make sure units are correct -->
        <xsl:variable name="vUnit">
            <xsl:choose>
                <xsl:when test="$pVitalSign = true()">
                    <xsl:choose>
                        <xsl:when test="@unit = '[in_us]'">[in_i]</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@unit" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@unit" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$pElementName}">
            <xsl:if test="@value">
                <xsl:choose>
                    <xsl:when test="@value and starts-with(@value, '.')">
                        <value>
                            <xsl:attribute name="value">
                                <xsl:value-of select="concat('0', @value)" />
                            </xsl:attribute>
                        </value>
                    </xsl:when>
                    <xsl:otherwise>
                        <value>
                            <xsl:attribute name="value">
                                <xsl:value-of select="@value" />
                            </xsl:attribute>
                        </value>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:if test="@unit">
                <unit>
                    <xsl:attribute name="value">
                        <xsl:value-of select="$vUnit" />
                    </xsl:attribute>
                </unit>
            </xsl:if>
            <!-- If this is a vital sign need system and unit-->
            <xsl:if test="$pVitalSign = true()">
                <system value="http://unitsofmeasure.org" />
                <code>
                    <xsl:attribute name="value">
                        <xsl:value-of select="$vUnit" />
                    </xsl:attribute>
                </code>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'REAL'][not(@nullFlavor)]">
        <xsl:param name="pElementName" select="'valueQuantity'" />

        <xsl:element name="{$pElementName}">
            <value>
                <xsl:attribute name="value">
                    <xsl:call-template name="add-leading-zero-to-real">
                        <xsl:with-param name="pValue" select="@value" />
                    </xsl:call-template>
                </xsl:attribute>
            </value>
            <!--<xsl:choose>
                <xsl:when test="@value and starts-with(@value, '.')">
                    <value>
                        <xsl:attribute name="value">
                            <xsl:value-of select="concat('0', @value)" />
                        </xsl:attribute>
                    </value>
                </xsl:when>
                <xsl:when test="@value">
                    <value>
                        <xsl:attribute name="value">
                            <xsl:value-of select="@value" />
                        </xsl:attribute>
                    </value>
                </xsl:when>
            </xsl:choose>-->
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'CD' or @xsi:type = 'CE']">
        <xsl:param name="pElementName" select="'valueCodeableConcept'" />
        <xsl:param name="pIncludeCoding" select="true()" />
        <xsl:call-template name="newCreateCodableConcept">
            <xsl:with-param name="pElementName" select="$pElementName" />
            <xsl:with-param name="pIncludeCoding" select="$pIncludeCoding" />
        </xsl:call-template>
    </xsl:template>

    <!--<xsl:template match="cda:value[@xsi:type = 'IVL_REAL']">
        <valueRange>
            <xsl:apply-templates select="cda:low" mode="range" />
            <xsl:apply-templates select="cda:high" mode="range" />
        </valueRange>
    </xsl:template>-->

    <xsl:template match="cda:high | cda:low" mode="range">
        <xsl:variable name="pElementName" select="local-name()" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="@value">
                    <value>
                        <xsl:attribute name="value">
                            <xsl:call-template name="add-leading-zero-to-real">
                                <xsl:with-param name="pValue" select="@value" />
                            </xsl:call-template>
                            <!--<xsl:value-of select="@value" />-->
                        </xsl:attribute>
                    </value>
                </xsl:when>
                <xsl:when test="cda:translation/@value">
                    <value>
                        <xsl:attribute name="value">
                            <xsl:call-template name="add-leading-zero-to-real">
                                <xsl:with-param name="pValue" select="cda:translation/@value" />
                            </xsl:call-template>
                            <!--<xsl:value-of select="cda:translation/@value" />-->
                        </xsl:attribute>
                    </value>
                </xsl:when>
                <xsl:when test="@nullFlavor">
                    <value>
                        <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                    </value>
                </xsl:when>
            </xsl:choose>
            <xsl:if test="@unit">
                <unit>
                    <xsl:attribute name="value">
                        <xsl:value-of select="@unit" />
                    </xsl:attribute>
                </unit>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:value[@xsi:type = 'IVL_REAL'] | cda:value[@xsi:type = 'IVL_PQ']">
        <xsl:param name="pElementName" select="'valueRange'" />
        <xsl:element name="{$pElementName}">
            <xsl:choose>
                <xsl:when test="cda:low/@nullFlavor and (cda:high/@value or cda:high/cda:translation/@value)" />
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:low" mode="range" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="cda:high/@nullFlavor and (cda:low/@value or cda:low/cda:translation/@value)" />
                <xsl:otherwise>
                    <xsl:apply-templates select="cda:high" mode="range" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="cda:observation/cda:referenceRange">
        <!-- Rule: must have at least a low or a high or a text -->
        <referenceRange>
            <xsl:for-each select="cda:observationRange">
                <xsl:for-each select="cda:value">
                    <xsl:choose>
                        <xsl:when test="@nullFlavor">
                            <xsl:apply-templates select="@nullFlavor" mode="data-absent-reason-extension" />
                        </xsl:when>
                        <xsl:when test="@xsi:type = 'IVL_PQ'">
                            <xsl:choose>
                                <xsl:when test="cda:low/@nullFlavor and (cda:high/@value or cda:high/cda:translation/@value)" />
                                <xsl:otherwise>
                                    <xsl:apply-templates select="cda:low" mode="range" />
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:choose>
                                <xsl:when test="cda:high/@nullFlavor and (cda:low/@value or cda:low/cda:translation/@value)" />
                                <xsl:otherwise>
                                    <xsl:apply-templates select="cda:high" mode="range" />
                                </xsl:otherwise>
                            </xsl:choose>
                            <!--<xsl:apply-templates select="." />-->
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:comment>WARNING: Unsupported observation reference range type: <xsl:value-of select="@xsi:type" />
                            </xsl:comment>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
                <!-- Put whatever is in text into a variable -->
                <xsl:variable name="vText">
                    <xsl:value-of select="cda:text" />
                </xsl:variable>
                <!-- Put whatever is in value with xsi:type = ST into a variable -->
                <xsl:variable name="vValueST">
                    <xsl:choose>
                        <xsl:when test="cda:value/@xsi:type = 'ST'">
                            <xsl:value-of select="cda:value[@xsi:type = 'ST']" />
                        </xsl:when>
                        <xsl:otherwise />
                    </xsl:choose>
                </xsl:variable>

                <!-- If there is no value in either, AND there was no low or high, then put a note into text to pass FHIR validation
                     If there is no value in either, there is no text. 
                     If they are different concatenate, if they are the same just use text -->
                <xsl:choose>
                    <xsl:when test="not(cda:value/@xsi:type = 'IVL_PQ') and not(cda:value/cda:low) and not(cda:value/cda:high) and not($vText/string()) and not($vValueST/string())">
                        <text>
                            <xsl:attribute name="value">
                                <xsl:value-of select="'No reference range supplied'" />
                            </xsl:attribute>
                        </text>
                    </xsl:when>
                    <xsl:when test="not($vText/string()) and not($vValueST/string())" />
                    <xsl:when test="not($vText/string())">
                        <text>
                            <xsl:attribute name="value">
                                <xsl:value-of select="$vValueST" />
                            </xsl:attribute>
                        </text>
                    </xsl:when>
                    <xsl:when test="not($vValueST/string())">
                        <text>
                            <xsl:attribute name="value">
                                <xsl:value-of select="$vText" />
                            </xsl:attribute>
                        </text>
                    </xsl:when>
                    <xsl:when test="$vText = $vValueST">
                        <text>
                            <xsl:attribute name="value">
                                <xsl:value-of select="$vText" />
                            </xsl:attribute>
                        </text>
                    </xsl:when>
                    <xsl:otherwise>
                        <text>
                            <xsl:attribute name="value">
                                <xsl:value-of select="concat($vText, '; ', $vValueST)" />
                            </xsl:attribute>
                        </text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </referenceRange>
    </xsl:template>


    <xsl:template name="II2Identifier">
        <xsl:param name="this" />

        <!-- if an II with @root only, then system is IETF, and value is the URI
			if @extension, then system is the @root and value is the @extension
			-->
        <xsl:choose>
            <xsl:when test="$this/@extension">
                <system>
                    <xsl:attribute name="value">urn:oid:<xsl:value-of select="$this/@root" /></xsl:attribute>
                </system>
                <value>
                    <xsl:attribute name="value">
                        <xsl:value-of select="$this/@extension" />
                    </xsl:attribute>
                </value>
            </xsl:when>
            <xsl:otherwise>
                <system value="urn:ietf:rfc:3986" />
                <value>
                    <xsl:attribute name="value">urn:oid:<xsl:value-of select="$this/@root" /></xsl:attribute>
                </value>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="@displayName">
        <xsl:variable name="vCode">
            <xsl:value-of select="parent::node()/@code" />
        </xsl:variable>
        <xsl:variable name="vDisplay">
            <xsl:choose>
                <!-- code/display mapping checks for FHIR's more stringent display checks - obviously this isn't going to catch everything,
                     but will clean up our testing warnings -->
                <xsl:when test="$code-display-mapping/map[@code = $vCode]">
                    <xsl:value-of select="$code-display-mapping/map[@code = $vCode]/@display" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="." />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$vDisplay" />
    </xsl:template>

</xsl:stylesheet>
