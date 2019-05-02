<?php include '../header.php'; ?>

<h1>Schnittstellen zur LaZAR</h1>
<p>
  Die öffentlichen Inhalte des 
  <a href="../">Forschungsdatenrepositorium LaZAR</a>
  können über verschiedene Schnittstellen
  abgerufen werden.
</p>
<h2 id="oai">OAI-PMH</h2>
<p>
  Unter <code><a href="oai">oai</a></code> steht eine
  <a href="http://www.openarchives.org/pmh/">OAI-PMH</a> Schnittstelle zur Verfügung.
</p>
<p>
  Der OAI-PMH-Endpunkt unterstützt als Nicht-Standard-Erweiterung des OAI-Protokolls 
  Kombinationen von sets für Abfragen vom Typ <code>ListRecords</code>. Beispiel:
  <ul>
    <li>
  <code><a href="oai?verb=ListRecords&metadataPrefix=easydb&set=tagfilter:lza*pool:1:2"
    >set=tagfilter:lza*pool:1:2</a></code>
    </li>
  </ul>
</p>

<h2 id="rdf">RDF</h2>
<p>
  Der <a href="lod">Abruf als Linked Open Data (LOD)</a> 
  ist in Entwicklung.
</p>

<?php include '../footer.php';
