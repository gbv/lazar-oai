<?php declare(strict_types=1);

namespace GBV\OAI;

use Psr\Http\Message\RequestInterface;
use GuzzleHttp\Psr7\Response;
use GuzzleHttp\Psr7;
use GuzzleHttp\Client;
use DOMDocument;
use DOMElement;
use DOMXPath;
use DOMNodeList;
use DOMComment;
use GBV\XSLTPipeline;

/**
 * OAI-PMH Proxy implemented as Guzzle Handler.
 *
 * The proxy extends an OAI-PMH service with
 *
 * - rewriting of the baseURL
 * - injection of processing instructions, especially XSLT
 * - support of set intersection (only for ListRecords)
 * - additional metadata formats
 * - optional pretty-printing
 *
 * See <https://packagist.org/packages/picturae/oai-pmh> for a full
 * OAI-PMH server implementation in PHP.
 */
class Proxy
{
    // only these HTTP query arguments are passed to the OAI-PMH backend
    const OAI_ARGUMENTS = [
        'verb', 'identifier', 'metadataPrefix',
        'from', 'until', 'set', 'resumptionToken'
    ];

    const OAI_NS = 'http://www.openarchives.org/OAI/2.0/';

    public function __construct(array $config)
    {
        $this->backend = $config['backend'];  // required
        $this->baseUrl = $config['baseUrl'];  // required
        $this->client  = $config['client'] ?? new Client([
            'http_errors' => false
        ]);

        // processing instructions
        $this->instructions = $config['instructions'] ?? [];
        if ($config['xslt'] ?? false) {
            $this->instructions['xml-stylesheet'] =
                'type="text/xsl" href="'.$config['xslt'].'"';
        }

        $this->formats = $config['formats'] ?? [];
        $this->pretty = $config['pretty'] ?? true;
        $this->intersectSets = $config['intersectSets'] ?? [];
        $this->tokenFile = new TokenFile($config['tokenFile'] ?? null);
    }

    public function __invoke(RequestInterface $request)
    {
        $headers = $request->getHeaders();
        $headers = array_diff_key($headers, array_flip(['Cookie', 'Host']));
        
        parse_str($request->getUri()->getQuery(), $query);

        // if resumptionToken: get query from tokenFile
        if (isset($query['resumptionToken'])) {
            $token = $query['resumptionToken'];
            $firstQuery = $this->tokenFile->get($token);
            if ($firstQuery) {
                $firstQuery['resumptionToken'] = $token;
                $query = $firstQuery;
            }
        } else {
            $query = $this->transformQuery($query);
        }

        // pass query to OAI-PMH backend
        $args = array_intersect_key($query, array_flip(static::OAI_ARGUMENTS));
        $response = $this->client->request(
            $request->getMethod(),
            $this->backend,
            [ 'headers' => $headers, 'query' => $args ]
        );
        # error_log($this->backend.'?'.http_build_query($args));

        // transform response and return as Promise
        $dom = $this->transformBody((string)$response->getBody(), $query);

        // save query with token
        $token =  static::xpath($dom, '//oai:resumptionToken')[0];
        if ($token) {
            $this->tokenFile->add($token->nodeValue, $query);
        }

        $response = $response->withBody(Psr7\stream_for($dom->saveXML()));

        return \GuzzleHttp\Promise\promise_for($response);
    }

    public function getRecord(string $format, string $id)
    {
        $query = $this->transformQuery([
            'verb' => 'GetRecord',
            'metadataPrefix' => $format,
            'identifier' => $id
        ]);
        $args = array_intersect_key($query, array_flip(static::OAI_ARGUMENTS));
        $response = $this->client->request('GET', $this->backend, [ 'query' => $args, ]);

        $dom = $this->transformBody((string)$response->getBody(), $query);

        return static::xpath($dom, '//oai:GetRecord/oai:record/oai:metadata/*')[0];
    }

    public function transformBody(string $body, array $query): DOMDocument
    {
        $dom = new DOMDocument();
        $dom->loadXML($body); // TODO: catch error

        $prefix = $query['targetPrefix'] ?? '';
        $verb = $query['verb'] ?? '';

        if ($verb === 'ListIdentifiers' || $verb === 'ListRecords') {
            if (count($query['sets']) > 1) {
                $dom = $this->filterRecords($dom, $query);
            }
            if ($verb === 'ListRecords') {
                $dom = $this->rewriteRecords($dom, $prefix);
            }
        } elseif ($verb == 'GetRecord') {
            $dom = $this->rewriteRecords($dom, $prefix);
        } elseif ($verb == 'ListMetadataFormats' && count($this->formats)) {
            $dom = $this->rewriteMetadataFormats($dom);
        } elseif ($verb == 'ListSets') {
            $listSetsNode = static::xpath($dom, '//oai:ListSets')[0];
            $sets = [];
            foreach (static::xpath($listSetsNode, 'oai:set') as $setNode) {
                $setSpec = static::xpath($setNode, 'oai:setSpec')[0]->nodeValue;
                $setName = static::xpath($setNode, 'oai:setName')[0];
                $sets[$setSpec] = $setName ? $setName->nodeValue : '';
            }
            foreach ($this->intersectSets as $set1 => $pattern) {
                if (!$sets[$set1]) {
                    continue;
                }
                foreach ($sets as $set2 => $setName) {
                    if (!preg_match("/$pattern/", $set2)) {
                        continue;
                    }
                    $setNode = $dom->createElement('set');
                    $setNode->appendChild($dom->createElement('setSpec', "$set1*$set2"));
                    $setNode->appendChild($dom->createElement('setName', $sets[$set1]." ".$setName));
                    $listSetsNode->appendChild($setNode);
                }
            }
        }

        // add processing instructions
        foreach ($this->instructions as $name => $content) {
            $pi = $dom->createProcessingInstruction($name, $content);
            $dom->insertBefore($pi, $dom->documentElement);
        }

        // rewrite request element
        foreach (static::xpath($dom, '//oai:request') as $node) {
            $node->textContent = $this->baseUrl;
            if ($prefix && $node->getAttribute('metadataPrefix')) {
                $node->setAttribute('metadataPrefix', $query['targetPrefix']);
            }
            if (count($query['sets'])) {
                $node->setAttribute('set', implode("*", $query['sets']));
            }
        }

        // enforce pretty-printing
        if ($this->pretty) {
            $dom->preserveWhiteSpace = false;
            $dom->formatOutput = true;
        }
 
        return $dom;
    }

    // helper function
    public static function xpath($node, string $query): DOMNodeList
    {
        $dom = $node instanceof DOMDocument ? $node : $node->ownerDocument;
        $xpath = new DOMXPath($dom);
        $xpath->registerNamespace('oai', static::OAI_NS);
        return $xpath->query($query, $node);
    }

    // helper function
    public static function xmlChild(DOMElement $node, string $name, bool $create = false)
    {
        foreach ($node->childNodes as $child) {
            if ($child->nodeName == $name) {
                return $child;
            }
        }
        return $create ? $node->appendChild(new DOMElement($name)) : null;
    }


    public function transformQuery(array $query): array
    {
        // split sets if multiple sets provided as '*' separated list
        if (isset($query['set'])) {
            $sets = explode('*', $query['set']);
            asort($sets); // smaller sets first
            if (count($sets) > 1) {
                $query['set'] = $sets[0];
            }
            $query['sets'] = $sets;
        } else {
            $query['sets'] = [];
        }

        // change metadata prefix to apply pipeline on
        $prefix = $query['metadataPrefix'] ?? '';
        $format = $this->formats[$prefix] ?? [];
        $pipeline = $format['pipeline'] ?? null;
        if ($pipeline) {
            $query['metadataPrefix'] = $pipeline[0];
            $query['targetPrefix'] = $prefix;
        } else {
            unset($query['targetPrefix']);
        }

        return $query;
    }

    public function extendFormat(DOMElement $node, $format)
    {
        if ($format['schema'] ?? 0) {
            $elem = static::xmlChild($node, 'schema', true);
            $elem->textContent = $format['schema'];
        }
        if ($format['namespace'] ?? 0) {
            $elem = static::xmlChild($node, 'metadataNamespace', true);
            $elem->textContent = $format['namespace'];
        }
    }

    public function rewriteMetadataFormats(DOMDocument $dom): DOMDocument
    {
        $formats = $this->formats;

        // extend existing format description
        foreach (static::xpath($dom, '//oai:metadataFormat') as $node) {
            $name = static::xmlChild($node, 'metadataPrefix');
            $name && $name = $name->textContent;
            if (isset($formats[$name])) {
                $format = $formats[$name];
                $this->extendFormat($node, $format);
                unset($formats[$name]);
            }
        }

        // add formats
        $root = static::xpath($dom, '//oai:ListMetadataFormats')->item(0);
        foreach ($formats as $name => $format) {
            $node = $root->appendChild(new DOMElement('metadataFormat'));
            $prefix = $node->appendChild(new DOMElement('metadataPrefix'));
            $prefix->textContent = $name;
            $this->extendFormat($node, $format);
        }

        return $dom;
    }

    public function rewriteRecords(DOMDocument $dom, string $prefix)
    {
        $format = $this->formats[$prefix] ?? null;

        $pipeline = new XSLTPipeline();
        $pipeline->appendFiles(array_slice($format['pipeline'] ?? [], 1));

        foreach (static::xpath($dom, '//oai:record') as $record) {
            foreach (static::xpath($record, 'oai:metadata/*') as $metadata) {
                $metadata->setAttribute('xmlns:'.$metadata->prefix, $metadata->namespaceURI);
                // file_put_contents('/tmp/tmp.xml', $dom->saveXML($metadata));

                // move metadata to a new document (why?)
                $m = new DOMDocument();
                $m->appendChild($m->importNode($metadata, true));

                $result = $pipeline->transformToDoc($m);
                if ($result->documentElement) {
                    $node = $dom->importNode($result->documentElement, true);
                    $metadata->parentNode->replaceChild($node, $metadata);
                } else {
                    // remove the whole record
                    $comment = new DOMComment("skipped record not available in $prefix format");
                    $record->parentNode->replaceChild($comment, $record);
                }
            }
        }

        return $dom;
    }


    public function filterRecords(DOMDocument $dom, array $query): DOMDocument
    {
        $sets = $query['sets'];

        if ($query['verb'] === 'ListIdentifiers') {
            $recPath = '//oai:header';
            $setPath = 'oai:setSpec';
        } else {
            $recPath = '//oai:record';
            $setPath = 'oai:header/oai:setSpec';
        }

        foreach (static::xpath($dom, $recPath) as $rec) {
            $setSpecs = [];
            foreach (static::xpath($rec, $setPath) as $setSpec) {
                $setSpecs[] = $setSpec->textContent;
            }

            $foundSets = array_intersect($sets, $setSpecs);
            if (count($foundSets) != count($sets)) {
                $rec->parentNode->removeChild($rec);
            }
        }

        return $dom;
    }
}
