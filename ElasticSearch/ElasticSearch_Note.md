---
title: Elastic Search - Some Note
date: 2018-11-20 18:00:26
tags:
    - elastic search
category: 
    - elastic_search
---

# Ghi chép về Elastic Search 
## 1. Elastic Search là gì 
Là một công cụ hỗ trợ việc tìm kiếm. Giúp cho việc tìm kiếm document (văn bản text) nhanh hơn.  
Tư tưởng:  Công cụ ElasticSearch sẽ được cài đặt trên 1 cụm các server (cluster). Developer sẽ phải đưa các data (document) lên trên ElasticSearch. Sau đó sẽ viết query để tìm kiếm data trên ES.

## 2. Các đặc điểm  
- ES có thể được cài đặt trên nhiều server, để tạo thành 1 cluster, mục đích để primary-replicate data, nhằm tăng performance truy vấn và tăng khả năng chịu lỗi của dữ liệu. Đây là keyword giúp cho ES có thể xây dựng thành 1 hệ thống phân tán, có khả năng mở rộng. Bằng cách thêm các node mới.   
- ES sau khi được cài đặt, nó hoạt động như 1 webserver. Nó có hỗ trợ thao tác thông qua RestFul. Chính vì thế việc này giúp cho developer dễ dàng thao tác CRUD với ES, mà không bị lệ thuộc vào nền tảng, ngôn ngữ lập trình.   
- Để search được data trên ES, cần phải biết cách viết query, giống như cách viết câu truy vấn tới database SQL. Câu truy vấn trên ES được gọi là: Search Lite và Search với Query DSL  

## 3. Restful Example 
### 3.1 Get dữ liệu 
```bash
GET company/employee/1
```
kết quả trả về ( json): 
```json
{
   "_index": "company",
   "_type": "employee",
   "_id": "1",
   "_version": 1,
   "found": true,
   "_source": {
      "name": "Smith",
      "age": 25,
      "phone_number": "09xxx"
   }
}
```

### 3.2 Insert dữ liệu
```bash
GET company/employee/2
{
    "name" : "John",
    "age" : 35,
	"phone_number": "08xxx"
}
```

Sử dụng các method khác như PUT, DELETE để update, xóa dữ liệu  

### 3.3 Search
Để search trên ES, có 2 cách, cách thứ nhất dùng Search Lite.   
Cũng tương tự như method CRUD:
```bash
GET /company/employee/_search?q=name:Smith AND age:25
```
Kết quả trả về là json: 
```json
{
   "took": 2,
   "timed_out": false,
   "_shards": {
      "total": 5,
      "successful": 5,
      "failed": 0
   },
   "hits": {
      "total": 1,
      "max_score": 0.4339554,
      "hits": [
         {
            "_index": "company",
            "_type": "employee",
            "_id": "1",
            "_score": 0.4339554,
            "_source": {
               "name": "Smith",
               "age": 20,
               "phone_number": "08xxx"
               ]
            }
         }
      ]
   }
}
```
Để search phức tạp hơn, Search Lite gặp những hạn chế, cần phải sử dụng Query DSL.  
Query DSL, là một ngôn ngữ đặc  tặc việc search, sử dụng cú pháp của JSON.  

Ví dụ để tìm kiếm employee có tên là "Smith" thì request Restful gửi lên:   
```bash
GET /company/employee/_search
{
    "query" : {
        "match" : {
        "last_name" : "Smith"
        }
    }
}
```

## 4. Finding Exact Values  
Để tìm kiếm trên ES được chính xác theo keyword, thì cần phải dùng các filter trong ES. 

## 5. Full-Text Search  
Để tìm kiếm fulltext search, thì sử dụng Match Query.   
Nhưng trước hết cần phải đánh index. 

## Tổng kết 
Tại sao cần phải sử dụng ES?    
Các hệ cơ sở quản trị dữ liệu quan hệ như: mysql, sqlserver, postgresql...được thiết kế để giải quyết vấn đề ràng buộc mỗi quan hệ giữa các entity này do đó việc biểu diễn các relationship là khá đơn giản. Tuy nhiên nhược điểm của những DB này là việc hỗ trợ nghèo nàn cho tính năng full-text search, toán tử join tốn nhiều chi phí khi dữ liệu trong DB và độ phức tạp của các relationship tăng lên, hoặc khi phải join giữa các table nằm trên các server vật lý khác nhau.