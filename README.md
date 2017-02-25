# Scrapy and XPATH command

* start scrapy shell
```
scrapy shell "http://www.imdb.com/search/title?release_date=1990,2016&user_rating=7.0,10&sort=user_rating,desc"
```

* example of xpath to fetch href link, inspect the html item and put corresponding syntax
```
response.selector.xpath('//span[contains(@class,"lister-item-index")]/text()').extract()
response.selector.xpath('//h3[@class="lister-item-header"]/a/@href').extract()
```

* scrapy start project
``
scrapy startproject imdb
``

* scrapy start spider in command line
```
scrapy crawl 'imdb_spider'
```

## Basic code module(imdb as example)

```python
import scrapy
import sys

class moviespider(scrapy.Spider):

    '''
    once the spider has started, it will send request and first call back is parse func 
    then insert into yield msg queue, if there is response, call callback

    '''

    name = "imdb_spider"
    start_urls = [
        """http://www.imdb.com/search/title?release_date=1980-01-01,2018-01-01&title_type=feature&user_rating=7.0,10"""
    ]
    imdbhome = 'http://www.imdb.com'

    def parse(self, response):
        movie_href = [self.imdbhome + x for x in response.selector.xpath('//h3[@class="lister-item-header"]/a/@href').extract()]
        next_page = response.selector.xpath('//a[@ref-marker="adv_nxt"]/@href').extract()
        for movie in movie_href:
            yield scrapy.Request(movie,callback=self.parse_movie)
        if next_page:
            yield scrapy.Request(self.imdbhome+next_page[0],self.parse)``

```


# Elastic Search

how to start elastic search
under the /bin/ in elasticsearch 
```
./bin/elasticsearch 
```
or we can start with damen
```
./bin/elasticsearch -d
```
you can check the status
```
ps aux |grep elastic
```


* node is logical, can be in one machine or distributed. 

* If we do not use mapping, elastic default store is text

* For each Doctype, we need to define meta sub class to define the index

* ES can have two analyzer, index and search analyzer can be different

* handle string and unicode: can input directly the unicode into es, es will handle 

* In python, need to define a es client to talk to server
```python
from elasticsearch import Elasticsearch

#eleastic search clien(to connect to server)
es = Elasticsearch()
```

* configure the setting.py also
```
# Configure item pipelines
# See http://scrapy.readthedocs.org/en/latest/topics/item-pipeline.html
ITEM_PIPELINES = {
    'imdb.pipelines.ImdbPipeline': 300,
}
```


* Need to configure Token_filter and analyzer for es
```python
ngram_filter = token_filter('ngram_filter',
                            type='nGram',
                            min_gram=1,
                            max_gram=20)

ngram_analyzer = analyzer('ngram_analyzer',
                          type='custom',
                          tokenizer='whitespace',
                          filter=[
                              'lowercase',
                              'asciifolding',
                              ngram_filter
                          ])
```

* Difference between analyzer and search_analyzer

search_analyzer is used for query, analyzer is used for index,if we use ngram for search)analyzer.
"abc" will be searched as a,b,c,ab,bc,abc

* Mapping

Using elasticsearch_dsl python dsl, do not need to write our own query body, generated one will be something like
```
{"mappings": {"movie": {"properties": {"title": {"fields": {"raw": {"type": "keyword"}}, "type": "text"}, "summary": {"type": "text"}, "datePublished": {"type": "date"}, "creators": {"type": "keyword"}, "genres": {"type": "keyword"}, "casts": {"type": "keyword"}, "time": {"type": "integer"}, "countries": {"type": "keyword"}, "plot_keywords": {"type": "keyword"}, "languages": {"type": "keyword"}, "rating": {"type": "float"}, "poster": {"type": "keyword"}, "suggest": {"analyzer": "ngram_analyzer", "search_analyzer": "standard", "type": "completion"}}}}, "settings": {"analysis": {"analyzer": {"ngram_analyzer": {"tokenizer": "whitespace", "filter": ["lowercase", "asciifolding", "ngram_filter"], "type": "custom"}}, "filter": {"ngram_filter": {"min_gram": 1, "max_gram": 20, "type": "nGram"}}}}}
```


* we can check es results in localhost
```
http://localhost:9200/imdb/_search?pretty
```

index mapping can be checked
```
http://localhost:9200/imdb/_mapping?pretty
```

## Elastic search query

* Match all query: basic check
```
GET /_search
{
    "query": {
        "match_all": {}
    }
}

# For specific index
GET $indexname/_search
{
    "query": {
        "match_all": {}
    }
}
```

* match query: full text
```
GET /_search
{
    "query": {
        "match" : {
            "message" : "this is a test"
        }
    }
}
```

* Term query: term query finds documents that contain the exact term specified in the inverted index. For instance:
like match all, only match words, not full text
```
POST _search
{
  "query": {
    "term" : { "user" : "Kimchy" } 
  }
}
```

* Bool query: A query that matches documents matching boolean combinations of other queries.

```
POST _search
{
  "query": {
    "bool" : {
      "must" : {
        "term" : { "user" : "kimchy" }
      },
      "filter": {
        "term" : { "tag" : "tech" }
      },
      "must_not" : {
        "range" : {
          "age" : { "gte" : 10, "lte" : 20 }
        }
      },
      "should" : [
        { "term" : { "tag" : "wow" } },
        { "term" : { "tag" : "elasticsearch" } }
      ],
      "minimum_should_match" : 1,
      "boost" : 1.0
    }
  }
}
```

> should only need to match "minimum_should_match"
> boost is use for score

* Script query
A query allowing to define scripts as queries. They are typically used in a filter context, for example:
```
GET /_search
{
    "query": {
        "bool" : {
            "must" : {
                "script" : {
                    "script" : {
                        "inline": "doc['num1'].value > 1",
                        "lang": "painless"
                     }
                }
            }
        }
    }
}
```

## Elastic search Internal

> Booleam model: Match query is changed to Bool query intenally
```
{
    "match": { "title": "brown fox"}
}
{
  "bool": {
    "should": [
      { "term": { "title": "brown" }},
      { "term": { "title": "fox"   }}
    ]
  }
}
```

## calculating score

### Term frequency

How often does the term appear in this document? 

__*tf(t in d) = √frequenc*__


> If you don’t care about how often a term appears in a field, and all you care about is that the term is present, then you can disable term frequencies in the field mapping:
```
PUT /my_index
{
  "mappings": {
    "doc": {
      "properties": {
        "text": {
          "type":          "string",
          "index_options": "docs" 
        }
      }
    }
  }
}
```
index_options to docs will disable term frequencies and term positions.

### Inverse document frequency
 > How often does the term appear in all documents in the collection? The more often, the lower the weight. Common terms like and or the contribute little to relevance, as they appear in most documents, while uncommon terms like elastic or hippopotamus help us zoom in on the most interesting documents. The inverse document frequency is calculated as follows:

__*idf(t) = 1 + log ( numDocs / (docFreq + 1))*__

The inverse document frequency (idf) of term t is the logarithm of the number of documents in the index, divided by the number of documents that contain the term.

### Field-length norm
> How long is the field? The shorter the field, the higher the weight. If a term appears in a short field, such as a title field, it is more likely that the content of that field is about the term than if the same term appears in a much bigger body field. 

__*norm(d) = 1 / √numTerms*__

if we do not want to certain field to be normed.
```
PUT /my_index
{
  "mappings": {
    "doc": {
      "properties": {
        "text": {
          "type": "string",
          "norms": { "enabled": false } 
        }
      }
    }
  }
}
```

### Final Score
```
score(q,d)  =  
            queryNorm(q)  
          · coord(q,d)    
          · ∑ (           
                tf(t in d)   
              · idf(t)²      
              · t.getBoost() 
              · norm(t,d)    
            ) (t in q)    
```

### Ignore TF and IDF
In this example, we try to search as hotel, we do not care whether it has wifi or garden, but we need the pool.
so put constant score on "wifi" and "garden", while bosst "pool"
```
GET /_search
{
  "query": {
    "bool": {
      "should": [
        { "constant_score": {
          "query": { "match": { "description": "wifi" }}
        }},
        { "constant_score": {
          "query": { "match": { "description": "garden" }}
        }},
        { "constant_score": {
          "boost":   2 
          "query": { "match": { "description": "pool" }}
        }}
      ]
    }
  }
}
```

### search explain
```
GET $index_name/_search?explain
```
There will be field called "_explanation" in results

### Function score query
The function_score allows you to modify the score of documents that are retrieved by a query. 

> The function_score query provides several types of score functions.

* script_score
* weight
* random_score
* field_value_factor
* decay functions: gauss, linear, exp



## Decay function
Example: Guassian
```
GET /_search
{
  "query": {
    "function_score": {
      "functions": [
        {
          "gauss": {
            "location": { 
              "origin": { "lat": 51.5, "lon": 0.12 },
              "offset": "2km",
              "scale":  "3km"
            }
          }
        },
        {
          "gauss": {
            "price": { 
              "origin": "50", 
              "offset": "50",
              "scale":  "20"
            }
          },
          "weight": 2 
        }
      ]
    }
  }
}
```
## Score with script

For example, we have this calcualtion
```
if (price < threshold) {
  profit = price * margin
} else {
  profit = price * (1 - discount) * margin
}
return profit / target
```

The we can use this script
```
GET /_search
{
  "function_score": {
    "functions": [
      { ...location clause... }, 
      { ...price clause... }, 
      {
        "script_score": {
          "params": { 
            "threshold": 80,
            "discount": 0.1,
            "target": 10
          },
          "script": "price  = doc['price'].value; margin = doc['margin'].value;
          if (price < threshold) { return price * margin / target };
          return price * (1 - discount) * margin / target;" 
        }
      }
    ]
  }
}
```

## Aggregation
* Buckets
    * subbuckets
* Metrics
    * stats
    * min
    * max
    * avg
* Can write own script 
```
{
    "aggs" : {
        "avg_grade" : { "avg" : { "field" : "grade" } }
    }
}
```

> in Aggregation, if we do not want certain field to be included, can put *missing* value
```
{
    "aggs" : {
        "tag_cardinality" : {
            "cardinality" : {
                "field" : "tag",
                "missing": "N/A" 
            }
        }
    }
}
```

# Elasticsearch-DSL Python

## Search object
```python
s = Search(using=client)
s = s.using(client)
s = Search().using(client).query("match", title="python")
response = s.execute()
```

## Queries
Match the command query to python code
```
# {"multi_match": {"query": "python django", "fields": ["title", "body"]}}
MultiMatch(query='python django', fields=['title', 'body'])


# {"match": {"title": {"query": "web framework", "type": "phrase"}}}
Match(title={"query": "web framework", "type": "phrase"})

Q("multi_match", query='python django', fields=['title', 'body'])
Q({"multi_match": {"query": "python django", "fields": ["title", "body"]}})
```

## Add Query to search object
```python
q = Q("multi_match", query='python django', fields=['title', 'body'])
s = s.query(q)
s = s.query("multi_match", query='python django', fields=['title', 'body'])
s.query = Q('bool', must=[Q('match', title='python'), Q('match', body='best')])
```

## Query Combination
```python
Q("match", title='python') | Q("match", title='django')
# {"bool": {"should": [...]}}

Q("match", title='python') & Q("match", title='django')
# {"bool": {"must": [...]}}

~Q("match", title="python")
# {"bool": {"must_not": [...]}}
q = Q('bool',
    must=[Q('match', title='python')],
    should=[Q(...), Q(...)],
    minimum_should_match=1
)
s = Search().query(q)
```

## Filter
```python
s = Search()
s = s.filter('terms', tags=['search', 'python'])
s = Search()
s = s.query('bool', filter=[Q('terms', tags=['search', 'python'])])
```

## Aggregation
 * define aggregation

```python
a = A('terms', field='category')
# {'terms': {'field': 'category'}}

a.metric('clicks_per_category', 'sum', field='clicks')\
    .bucket('tags_per_category', 'terms', field='tags')
# {
#   'terms': {'field': 'category'},
#   'aggs': {
#     'clicks_per_category': {'sum': {'field': 'clicks'}},
#     'tags_per_category': {'terms': {'field': 'tags'}}
#   }
# }
```

 * Add Aggregation into search object
```python
s = Search()
a = A('terms', field='category')
s.aggs.bucket('category_terms', a)
# {
#   'aggs': {
#     'category_terms': {
#       'terms': {
#         'field': 'category'
#       }
#     }
#   }
# }
```

Use the elastic search DSL to construct in python format
```python
s = Search()

s.aggs.bucket('per_category', 'terms', field='category')
s.aggs['per_category'].metric('clicks_per_category', 'sum', field='clicks')
s.aggs['per_category'].bucket('tags_per_category', 'terms', field='tags')
```

## Sorting & Pagination
```python
s = Search().sort(
    'category',
    '-title',
    {"lines" : {"order" : "asc", "mode" : "avg"}}
)
s = s[10:20]
```

## Suggestion
```python
s = s.suggest('my_suggestion', 'pyhton', term={'field': 'title'})
```


# Kibana

* open source data analysis and virtualization tool
* works with elastic search
* Web based application

## Usage
```
#run in /bin under kibana folder
./kibana
```
* specify the index name same as index in elastic search
* Can use console command to do all stuffs

# Docker

The illustration of docker is:
![Alt text](https://github.com/zhangruiskyline/elastic_demo/blob/master/img/docker-stages.png)


* All docker instances share same OS kernal, not like VM.
* Sample of docker file
```
FROM python:3.4-alpine 
ADD . /code 
WORKDIR /code 
RUN pip install -r requirements.txt 
CMD ["python", "app.py"]
```

## Docker commands
* docker ps: check the running status of docker image
* docker images: check the current available docker image
    * docker images rm $imageID : remove image; using image ID
* Docker install: 
```shell
docker pull elasticsearch
```
* Run docker elastic search

First to shutdown local elastic search, otherwise there will be port conflicts. 
Then run in a daemon instance
   
```shell
docker run -d -p 9200:9200 $imagesID
```
Check status on http://localhost:9200

* Debug inside docker image via command lines
```shell
docker exec -it $imageid /bin/bash 
```

### docker compose
Compose is a tool for defining and running multi-container Docker applications. 
With Compose, you use a Compose file to configure your application’s services. 
Then, using a single command, you create and start all the services from your configuration.

There are no differences between the actual image that gets build between docker-compose build and a 
"manual" docker build in terms of the contents of the image.

The difference is only in naming/tagging of the build result, which docker-compose does automatically for you. 
Other than that the docker-compose build is no different behind the scenes and simply a wrapper for the normal 
docker build.

docker compose has a configuration .yml file

Common commands
```shell
docker-compose up [-d]
docker-compose down [-v | --volumes] 
#notice if we add --volume, it will only shutdown docker run, but running states will be saved in docker
# Otherwise it will delete all from docker disk
docker-compose ps
```

> create yml file

* internal docker container exchange information via port 9300, only expose doecker 1's 9200 to outside



# Jinja2

use block to abstract the common in base.html
```html
{% block xxxx %}
{% endblock %}
```
in other html file
```html
{% extends "base.html" %}
{% block xxx %}
```
only need to change the differen part than base.html
