---
title: Stories - Query SQL on S3
date: 2020-04-20 18:00:26
updated: 2020-04-20 18:00:26
tags:
    - s3
    - query sql
category: 
    - stories
---

# Diary of Finding a "SQL Query" Solution on Object Storage

I am building a feature that allows users to backup/restore their data. The data they need to backup is from RDBMS SQL. The solution is to query SQL by userId, then export the results to a data file (such as .csv) and upload it to S3. There will be a database logging the location of the object file on S3, or the path will be created according to some formula. When restoration is needed, the data will be downloaded to execute the business logic.

## Challenges and Solution Search

The only thing that excites me about this problem is finding a tool that can "understand" the data I store on S3.

Initially, I thought of AWS Athena because I had read somewhere that Athena allows direct SQL queries on S3. I expected there to be a cool mechanism between Athena and S3, and my application would call Athena's APIs without handling File IO. This would allow me to avoid downloading the CSV file from S3 and parsing it to get a list of objects; instead, I wanted to stream the data via API.

## Evaluating AWS Athena

Unfortunately, after researching AWS Athena, I found it unsuitable for my case. Athena is great for analyzing large data files but not for my purpose.

Some limitations of Athena include:
- Athena allows a maximum of 100 databases per account.
- Athena limits the number of concurrent queries (up to 5 queries).

With my initial intention, this failed because it is impossible to create a separate database for each CSV file.

## Exploring More Solutions

I found many keywords related to Apache Drill, but it is not serverless, so it was eliminated.

During my research, I discovered that an engine is needed to query object storage like PrestoDB, AVRO, Parquet... This is a significant issue that big companies like Facebook, Google, and AWS are all using some core to address. Perhaps in the future, if I have the chance, I will revisit and explore it further.

## Final Solution - S3 Select

Finally, I found S3 Select, which is quite suitable for my needs. However, S3 Select cannot query data at a specified offset.

For example, my CSV file has 1000 rows, and I want to retrieve 500 rows per API request. S3 Select does not support specifying the offset for the query.

To solve this problem, I can customize it by adding a NumberSequence column when creating the CSV file. When querying, I will add a condition like `WHERE 501 < NumberSequence < 1000`.

## Limitations of S3 Select

S3 Select has limitations on the input and output size. If I meticulously calculate the number of columns and the maximum size of each column, I might determine the maximum size for each row.

However, this is not absolutely certain, so I will handle the logic in the code, with each query retrieving N rows quickly.
