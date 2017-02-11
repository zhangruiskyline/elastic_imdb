curl -XPOST 'localhost:9200/_analyze?pretty' -d'
{
  "analyzer": "ngram_analyzer",
  "text":     "Thequickbrownfox."
}
'

