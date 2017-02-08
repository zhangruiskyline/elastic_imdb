1. Scrapy and XPATH

scrapy shell "http://www.imdb.com/search/title?release_date=1990,2016&user_rating=7.0,10&sort=user_rating,desc"
-- get this page

response.selector.xpath('//span[contains(@class,"lister-item-index")]/text()').extract()
response.selector.xpath('//h3[@class="lister-item-header"]/a/@href').extract()
--extract href 
