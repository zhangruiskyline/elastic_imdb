curl -XPUT 'localhost:9200/music?pretty' -d'{ 
    "mappings":
    { 
        "song" :
        { 
            "properties" :
             { 
                "suggest" :
                { 
                    "type" : "completion"
                }, 
                "title" :
                { 
                    "type": "keyword" 
                } 
            } 
        } 
    }
 } '

