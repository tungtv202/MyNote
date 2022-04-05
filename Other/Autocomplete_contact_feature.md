---
title: ElasticSearch - Contact autocomplete feature
date: 2022-04-05 22:00:26
updated: 2022-04-05 22:00:26
tags:
    - elasticsearch
    - search contact
    - autocomplete
category: 
    - elasticsearch
---

# Contact autocomplete feature

## Context
- Build a autocomplete feature (search feature).
- Data index: 
```json
[{
    "contactId" : 1,
    "email" : "tungtv202@gmail.com",
    "firstname" : "Tung",
    "surname" : "Tran Van"
}, ....]
```
- Search with any text query. Example "tungtv202". The results should be returned exactly expected.


## 1. Create index
- `PUT /contact`    
```json           
{
    "settings": {
        "number_of_shards": 5,
        "number_of_replicas": 1,
        "index.write.wait_for_active_shards": 1,
        "index": {
            "max_ngram_diff": 30
        },
        "analysis": {
            "analyzer": {
                "search_analyzer": {
                    "tokenizer": "uax_url_email"
                },
                "ngram_filter_analyzer": {
                    "tokenizer": "uax_url_email",
                    "filter": [
                        "ngram_filter"
                    ]
                },
                "edge_ngram_filter_analyzer": {
                    "tokenizer": "standard",
                    "filter": [
                        "edge_ngram_filter",
                        "lowercase"
                    ]
                }
            },
            "filter": {
                "ngram_filter": {
                    "type": "ngram",
                    "min_gram": 3,
                    "max_gram": 30
                },
                "edge_ngram_filter": {
                    "type": "edge_ngram",
                    "min_gram": 3,
                    "max_gram": 30
                }
            }
        }
    },
    "mapping": {
        "properties": {
            "contactId": {
                "type": "keyword"
            },
            "email": {
                "type": "text",
                "analyzer": "ngram_filter_analyzer"
            },
            "firstname": {
                "type": "text",
                "analyzer": "edge_ngram_filter_analyzer"
            },
            "surname": {
                "type": "text",
                "analyzer": "edge_ngram_filter_analyzer"
            }
        }
    }
}
```

1. Why `email` has NOT index analyzers is `edge_ngram_filter_analyzer`?
    - "tranvantung@gmail.com" will NOT in contain of results when we searching "tung"
```bash
GET /_analyze
{
  "tokenizer": "uax_url_email",
  "filter" : [{"type": "edge_ngram", "min_gram": 3, "max_gram": 30 }],
  "text": "tranvantung@gmail.com"
}
```
Tokens result:
```
[
  "tra",
  "tran",
  "tranv",
  "tranva",
  "tranvan",
  "tranvant",
  "tranvantu",
  "tranvantun",
  "tranvantung",
  "tranvantung@",
  "tranvantung@g",
  "tranvantung@gm",
  "tranvantung@gma",
  "tranvantung@gmai",
  "tranvantung@gmail",
  "tranvantung@gmail.",
  "tranvantung@gmail.c",
  "tranvantung@gmail.co",
  "tranvantung@gmail.com"
]
```
We can see, no any token has value `tung`.
Now, let try with `ngram`

```bash
GET /_analyze
{
  "tokenizer": "uax_url_email",
  "filter" : [{"type": "ngram", "min_gram": 3, "max_gram": 4 }],
  "text": "tranvantung@gmail.com"
}

```
tokens result:
```
[
  "tra",
  "tran",
  "ran",
  "ranv",
  "anv",
  "anva",
  "nva",
  "nvan",
  "van",
  "vant",
  "ant",
  "antu",
  "ntu",
  "ntun",
  "tun",
  "tung",
  "ung",
  "ung@",
  "ng@",
  "ng@g",
  "g@g",
  "g@gm",
  "@gm",
  "@gma",
  "gma",
  "gmai",
  "mai",
  "mail",
  "ail",
  "ail.",
  "il.",
  "il.c",
  "l.c",
  "l.co",
  ".co",
  ".com",
  "com"
]
```
Has token "tung".

2.  Why `firstname/surname` has index analyzers is `edge_ngram_filter_analyzer`?
- When you search contact by contactName, you will not search "ung" for "Tung" contact?
you will type: T...Tu...Tun...Tung

```bash
GET /_analyze
{
  "tokenizer": "standard",
  "filter" : [{"type": "edge_ngram", "min_gram": 3, "max_gram": 30 }],
  "text": "Tran Van Tung"
}
```
tokens result:

```
[
  "Tra",
  "Tran",
  "Van",
  "Tun",
  "Tung"
]
```

3. Why `"tokenizer": "uax_url_email"`?

- https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-uaxurlemail-tokenizer.html

4. Why we need `search_analyzer`?
- It will be used when searching, for field "email".
- We can setting search analyzer for email by default
```
            "email": {
                "type": "text",
                "analyzer": "ngram_filter_analyzer",
                "search_analyzer": "search_analyzer"
            },
```
or we can assign it in query when searching


## 2. Search query
- `GET /contact/_search`
```json
{
  "query": {
    "bool": {
      "should": [
        {
          "multi_match": {
            "query": "nobita",
            "fields": [
              "email"
            ],
            "analyzer": "search_analyzer"
          }
        },
        {
          "multi_match": {
            "query": "nobita",
            "fields": [
              "firstname",
              "surname"
            ]
          }
        }
      ],
      "minimum_should_match": 1
    }
  }
}
```

// Bonus more complex query
```json
{
  "from": 0,
  "size": 10,
  "query": {
    "bool": {
      "must": [
        {
          "bool": {
            "should": [
              {
                "multi_match": {
                  "query": "nobita",
                  "fields": [
                    "email"
                  ],
                  "analyzer": "search_analyzer"
                }
              },
              {
                "multi_match": {
                  "query": "nobita",
                  "fields": [
                    "firstname",
                    "surname"
                  ]
                }
              }
            ],
            "minimum_should_match": 1
          }
        },
        {
          "bool": {
            "must": [
              {
                "term": {
                  "domain": "linagora.com"
                }
              }
            ]
          }
        }
      ]
    }
  }
}
```

