**1. Scrapy and XPATH command**

1.1 start scrapy shell
```
scrapy shell "http://www.imdb.com/search/title?release_date=1990,2016&user_rating=7.0,10&sort=user_rating,desc"
```

1.2 example of xpath to fetch href link, inspect the html item and put corresponding syntax
```
response.selector.xpath('//span[contains(@class,"lister-item-index")]/text()').extract()
response.selector.xpath('//h3[@class="lister-item-header"]/a/@href').extract()
```

1.3 scrapy start project
``
scrapy startproject imdb
``

1.4 scrapy start spider in command line
```
scrapy crawl 'imdb_spider'
```

2. Basic code module(imdb as example)

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


**2. Elastic Search**
2.1 
node is logical, can be in one machine or distributed. 

2.2 
If we do not use mapping, elastic default store is text

2.3 
For each Doctype, we need to define meta sub class to define the index