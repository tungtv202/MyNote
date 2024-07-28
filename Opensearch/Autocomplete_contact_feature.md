
---
title: ElasticSearch - Contact Autocomplete Feature
date: 2022-04-05 22:00:26
updated: 2022-04-05 22:00:26
tags:
- elasticsearch
- search contact
- autocomplete
category:
- elasticsearch
---

# Contact Autocomplete Feature

## Context

- Build an autocomplete feature (search feature).
- Data index:

```json
[{
    "contactId": 1,
    "email": "tungtv202@gmail.com",
    "firstname": "Tung",
    "surname": "Tran Van"
}, ...]
```

- Search with any text query. Example "tungtv202". The results should be returned exactly as expected.

## 1. Create Index

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
    "mappings": {
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

### Why `email` Uses `ngram_filter_analyzer` Instead of `edge_ngram_filter_analyzer`?

- Using `edge_ngram_filter_analyzer` on `email` would result in tokens like these:

```bash
GET /_analyze
{
  "tokenizer": "uax_url_email",
  "filter": [{"type": "edge_ngram", "min_gram": 3, "max_gram": 30 }],
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

No token contains `tung`.

- Using `ngram_filter_analyzer` instead:

```bash
GET /_analyze
{
  "tokenizer": "uax_url_email",
  "filter": [{"type": "ngram", "min_gram": 3, "max_gram": 4 }],
  "text": "tranvantung@gmail.com"
}
```

Tokens result:

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

Includes the token `tung`.

### Why `firstname` and `surname` Use `edge_ngram_filter_analyzer`?

- When searching for contact names, users typically type progressively (e.g., T...Tu...Tun...Tung).

```bash
GET /_analyze
{
  "tokenizer": "standard",
  "filter": [{"type": "edge_ngram", "min_gram": 3, "max_gram": 30 }],
  "text": "Tran Van Tung"
}
```

Tokens result:

```
[
  "Tra",
  "Tran",
  "Van",
  "Tun",
  "Tung"
]
```

### Why Use `tokenizer`: `uax_url_email`?

- The `uax_url_email` tokenizer is designed to tokenize email addresses and URLs effectively.

Reference: [Elasticsearch UAX URL Email Tokenizer](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-uaxurlemail-tokenizer.html)

### Why Use `search_analyzer`?

- The `search_analyzer` is used during search queries for the `email` field. It can be set as the default search analyzer or assigned in the query:

```json
"email": {
    "type": "text",
    "analyzer": "ngram_filter_analyzer",
    "search_analyzer": "search_analyzer"
}
```

## 2. Search Query

- `GET /contact/_search`

```json
{
  "query": {
    "bool": {
      "should": [
        {
          "multi_match": {
            "query": "nobita",
            "fields": ["email"],
            "analyzer": "search_analyzer"
          }
        },
        {
          "multi_match": {
            "query": "nobita",
            "fields": ["firstname", "surname"]
          }
        }
      ],
      "minimum_should_match": 1
    }
  }
}
```

### More Complex Query

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
                  "fields": ["email"],
                  "analyzer": "search_analyzer"
                }
              },
              {
                "multi_match": {
                  "query": "nobita",
                  "fields": ["firstname", "surname"]
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
