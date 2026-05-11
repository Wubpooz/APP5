# Send SPARQL query to SPARQL endpoint, store and output result.

import urllib2

endpointURL = "http://dbpedia.org/sparql"
query = """
SELECT distinct ?elvis ?elvisbday WHERE {
  <http://dbpedia.org/resource/Elvis_Presley>
  <http://www.w3.org/2002/07/owl#sameAs> ?elvis .  #find all resources that refer to the same individual as <http://dbpedia.org/resource/Elvis_Presley>
  <http://dbpedia.org/resource/Elvis_Presley>
  <http://dbpedia.org/ontology/birthDate> ?elvisbday .
}
"""
escapedQuery = urllib2.quote(query)
requestURL = endpointURL + "?query=" + escapedQuery
request = urllib2.Request(requestURL)

result = urllib2.urlopen(request)
print result.read()

