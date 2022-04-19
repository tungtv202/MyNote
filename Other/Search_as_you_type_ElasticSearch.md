---
title: ElasticSearch - Search as you type
date: 2022-04-04 18:00:26
updated: 2022-04-04 18:00:26
tags:
    - elasticsearch
    - search as you type
    - autocomplete
category: 
    - elasticsearch
---

# Search as you type & Other related

## Concept
Example: 
```bash
PUT movies
{
   "mappings": {
       "properties": {
           "title": {
               "type": "search_as_you_type"
           },
           "genre": {
               "type": "search_as_you_type"
           }
       }
   }
}
```

`search_as_you_type = field + field._2gram + field._3gram + field._index_prefix`

Input: 

```
Star Wars: Episode VII - The Force Awakens
```

| Field                     |                                                                                                                 | Example Output                                                                          |
|---------------------------|:----------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| movie_title               | The “root” field is analyzed as configured in the mapping                                                       | ["star","wars","episode","vii","the","force","awakens"]                                 |
| movie_title._2gram        | Splits sentence up by two words                                                                                 | ["Star Wars","Wars Episode","Episode VII","VII The","The Force","Force Awakens"]        |
| movie_title._3gram        | Splits the sentence up by three words                                                                           | ["Star Wars","Star Wars Episode","Wars Episode","Wars Episode VII","Episode VII", ... ] |
| movie_title._index_prefix | This uses an edge n-gram token filter to split up each word into substrings, starting from the edge of the word | ["S","St","Sta","Star"]                                                                 |


## Example
- Run elastic search
```
docker run --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.10.2
```
(No need auth)


```bash 

// CREATE NEW INDEX `movies`
POST _bulk
{ "create" : { "_index" : "movies", "_id" : "135569" } }
{ "id": "135569", "title" : "Star Trek Beyond", "year":2016 , "genre":["Action", "Adventure", "Sci-Fi"] }
{ "create" : { "_index" : "movies", "_id" : "122886" } }
{ "id": "122886", "title" : "Star Wars: Episode VII - The Force Awakens", "year":2015 , "genre":["Action", "Adventure", "Fantasy", "Sci-Fi", "IMAX"] }
{ "create" : { "_index" : "movies", "_id" : "109487" } }
{ "id": "109487", "title" : "Interstellar", "year":2014 , "genre":["Sci-Fi", "IMAX"] }
{ "create" : { "_index" : "movies", "_id" : "58559" } }
{ "id": "58559", "title" : "Dark Knight, The", "year":2008 , "genre":["Action", "Crime", "Drama", "IMAX"] }
{ "create" : { "_index" : "movies", "_id" : "1924" } }
{ "id": "1924", "title" : "Plan 9 from Outer Space", "year":1959 , "genre":["Horror", "Sci-Fi"] }


// CREATE NEW INDEX `autocomplete`
PUT autocomplete
{
   "mappings": {
       "properties": {
           "title": {
               "type": "search_as_you_type"
           },
           "genre": {
               "type": "search_as_you_type"
           }
       }
   }
}

// REINDEX DATA FROM movies -> autocomplete
POST _reindex
{
  "source": {
    "index": "movies"
  },
  "dest": {
    "index": "autocomplete"
  }
}

// CHECK MAPING
GET /autocomplete/_mapping

// SEARCH
GET /autocomplete/_search
{
  "size": 5,
  "query": {
    "multi_match": {
      "query": "Sta",
      "type": "bool_prefix",
      "fields": [
        "title",
        "title._2gram",
        "title._3gram"
      ]
    }
  }
}
```


## Other related
- ngram = is a sequnce of n characters
- Analyzers are composed of a single Tokenizer and zero or more TokenFilters. The tokenizer may be preceded by one or more CharFilters.
- An analyzer consists of three things:
    - Character filter
    - Tokeniser
    - Token filter

![TOKENIZER_charfilter_tokenFilter](https://tungexplorer.s3.ap-southeast-1.amazonaws.com//other/elasticsearch/TOKENIZER_charfilter_tokenFilter.png)

- Sometimes the two approaches: `ngram tokenizer vs ngram token filter` are equivalent. ( Depending on the circumstances one approach may be better than the other)
Example: 
    - ngram token filter

    ```json 
    {
        "analysis": {
            "filter": {
                "ngram_filter": {
                    "type": "nGram",
                    "min_gram": 4,
                    "max_gram": 4
                }
            },
            "analyzer": {
                "ngram_filter_analyzer": {
                    "type": "custom",
                    "tokenizer": "standard",
                    "filter": [
                        "lowercase",
                        "ngram_filter"
                    ]
                }
            }
        }
    }
    ```

    - ngram tokenizer

    ```json
    {
        "analysis": {
            "tokenizer": {
                "ngram_tokenizer": {
                    "type": "nGram",
                    "min_gram": 4,
                    "max_gram": 4,
                    "token_chars": [
                        "letter",
                        "digit"
                    ]
                }
            },
            "analyzer": {
                "ngram_tokenizer_analyzer": {
                    "type": "custom",
                    "tokenizer": "ngram_tokenizer",
                    "filter": [
                        "lowercase"
                    ]
                }
            }
        }
    }
    ```

- Test an `analyzer`: https://www.elastic.co/guide/en/elasticsearch/reference/current/test-analyzer.html

- `ngram`
```bash
GET _analyze
{
  "tokenizer" : "standard",
  "filter" : [{"type": "ngram", "min_gram": 3, "max_gram": 3 }],
  "text" : "search"
}
```
result: 
```
[“sea”, “ear”, “arc”, “rch”]
```
- `edge_ngram`

```bash
GET _analyze
{
 "tokenizer" : "standard",
 "filter" : [{"type": "edge_ngram", "min_gram": 1, "max_gram": 10 }],
 "text" : "search"
}
```
result: 
```
["s", "se", "sea", "sear", "searc", "search"]
```

### index_analyzer vs search_analyzer
Why do we need two analyzers?
This comes from ES mechanism work. Let's imagine through the following example:
- We have a document with content "XXXXXXXX" (1).  
- When "index time", (1) has been indexed (`index_analyzer`) to tokens: [A, B, C, D].
- When we search text "XXXX" (2), this string will be analyzing (`search_analyzer`) to tokens: [A, B, E] 
- In order to detect results, ES will compare tokens of documents from "index time" with tokens of "query text" from "search time". Example A=A, B=B

Why do we use single analyers for both index and search?. Let example:
- We have document "elasticsearch".
- Document has been indexed by edge_ngram (min_gram=3, max_gram=20)  (Analyzer A1). => Tokens: ["ela", "elas","elast","elasti","elastic","elastics","elasticse","elasticsea","elasticsear","eleasticsearc" and "elasticsearch"]
- We search with text query "elapsed". With Analyzer A1, tokens will be: ["ela", "elap", "elaps", "elapse", "elapsed"]  
- We can see "ela"="ela". So, when we search "elapsed", the result will contain "elasticsearch". Is it our expected? NO
- If we tokenizing "elapsed" by another Analyzer. Example: Analyzer A2 (tokenizer=standard, filter=standar). Then tokens will be ["elapsed" ]  => Then the result will NOT contain "elasticsearch"

Ref: https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-index-search-time.html#different-analyzers









