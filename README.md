# lazar.gbv.de

Dieses git-Repository enthält den Quellcode der Homepage des DFG-Projekt LaZAR unter [LaZAR](http://lazar.gbv.de/) sowie verschiedene XSLT-Skripte Konvertierung des internen easyBD-Datenformates von LaZAR.

[![Build Status](https://travis-ci.org/gbv/lazar.gbv.de.svg?branch=master)](https://travis-ci.org/gbv/lazar.gbv.de)


## Umfang der Homepage

- Startseite
- Schnittstellen
    - OAI-PMH Proxy
    - Linked Open Data (RDF)

### OAI-PMH-Proxy

Der OAI-PMH-Proxy erweitert die OAI-Schnittstelle des zugrunde liegenden Datenbanksystems easyDB um Schnittmengen von sets für Abfragen vom Typ `ListRecords`. Außerdem wird die Konvertierung von easyDB-XML nach DataCite-XML und nach Dublin Core im Proxy vorgenommen.

Der Quellcode des Proxy befindet sich im Unterverzeichnis `src/`.

### Linked Open Data

Linked-Open Data wird in rudimentärer Form durch Konvertierung von DataCite-XML nach HTML+RDFa bereitgestellt.

## XSLT-Skripte

In easyDB können mittels XSLT Formate zur Auslieferung per OAI-PMH definiert werden. Grundlage ist das easyDB-XML-Format.  Die Skripte zur Konvertierung und weitere Tools befinden sich im Verzeichni `xslt/`:

    cd xslt

Zum Testen kann mit `getrecord` ein Datensätz per OAI-PMH heruntergeladen werdbereitgestellt../getrecord oai:lazar.gbv.de:4c5b995c-32b5-45c0-8ad4-8f5c3964bcdb > easydb.xml

Die Umgebungsvariable `OAIMPH` setzt einen anderen OAI-Endpunkt. Als zweiter Parameter kann ein Metadatenformat statt `easydb` angegeben werden (z.B. `oai_dc`).

Das Skript `makerecord` führt die Konvertierung lokal mit xsltproc durch:

    ./makerecord oai:lazar.gbv.de:4c5b995c-32b5-45c0-8ad4-8f5c3964bcdb datacite

entspricht

    ./getrecord oai:lazar.gbv.de:4c5b995c-32b5-45c0-8ad4-8f5c3964bcdb > easydb.xml
    ./xslt.php easydb.xml easydb2datacite.xsl

Im Unterverzeichnis `test` befinden sich Beispieldatensätze für Regressionstest. Mit

    ./runtest

werden alle Beispiele überprüft.

Zusätzlich sollten die Zieldateien mit `xmlint` validiert werden, z.B.

    xmllint --noout --schema schemas/datacite.xsd datacite.xml

## Installation

Das Repository liegt auf GitHub unter <https://github.com/gbv/lazar.gbv.de>.

    $ git clone https://github.com/gbv/lazar.gbv.de.git
    $ cd lazar.gbv.de

Die Homepage benötigt mindestens PHP 7 und composer zur Paketverwaltung:

    $ composer update --no-dev

Außerdem muss libxslt für PHP aktiviert sein (z.B. Debian-Paket `php-xsl`).

Das Einstiegsverzeichnis für den Webserver ist `public/`. Für Apache ist eine
`.htaccess` enthalten.


Die XSLT-Skripte müssen in der LaZAR-Administrationsoberfläche aktualisiert
werden. Zum lokalen Testen wird xsltproc benötigt.


## Entwicklung

Benötigt PHPUnit und PHP Codesniffer:

    $ composer update

In `Makefile` sind die üblichen Aktionen zusammengefasst:

    $ make style    # PHP-Code aufräumen
    $ make test     # PHP-Tests und XSLT-Tests
    $ make web      # Anwendung testweise auf Port 8008 starten

