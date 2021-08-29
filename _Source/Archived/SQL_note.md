---
title: SQL - Command
date: 2017-12-03 18:00:26
updated: 2017-12-03 18:00:26
tags:
    - archived
category: 
    - z.archived
---

## Command dump db kèm sequence

```bash
pg_dump -h localhost:5432 -U postgres -d database_name --exclude-table=exclude_id_seq > backup_`date +%Y_%m_%d`.sql
```

## Khi viết query có cả điều kiện AND và OR, cái nào chạy trước?

```sql
-- Example:
SELECT 1 = 1 OR 1 = 2 AND 2 = 1;
-- Result = TRUE or FALSE?
```

AND giống như phép nhân/chia còn OR giống như phép cộng/trừ

## IN và ANY khác gì nhau?

```
<!-- Database mẫu như sau: (schema: tschema) -->
| id  |  score | type  | 
1          1     A
2          NULL  C
4	       NULL  B
3	       0	 B
5	       3	 A
6	       NULL  A
```

```sql
--Example
SELECT
  id FROM tschema.demo
WHERE type IN ('A','B');
--vs
SELECT
  id FROM tschema.demo
WHERE type = ANY (ARRAY['A','B']);
```  

ANY có thể sử dụng kèm với các toán tử : >, >=, =<, < , còn IN thì không (cùng lắm là IN và NOT IN )
ANY có thể được sử dụng để viết function. (Sau ANY đó là 1 mảng ARRAY, có thể truyền param này vào function được, còn IN
theo mình biết là không, IN sử dụng các dấu "," để định nghĩa list, và việc này truyền vào như 1 param không được). Tản
mạn: mình có tìm hiểu trên stackoverflow thấy bảo IN được hay không được sử dụng với INDEX gì đấy

## UNION và UNION ALL khác gì nhau?

Mình có 2 bản ghi A và B cùng cấu trúc  
UNION ALL sẽ trả về tất cả các bản ghi A + B    
UNION không trả về tất cả, mà sau khi hợp tất cả A và B nó sẽ lọc ra các bản ghi bị trùng lặp (duplicate) và tự động xóa
các row thừa.

## CASE WHEN với COALESCE, NVL khác gì nhau?

Ngày trước mình thường rất hay dùng CASE WHEN để xử lý cho các trường hợp xử lý ngoại lệ khi giá trị trả về là NULL.
Nhưng điều này dẫn tới câu query của mình rất dài, + với nếu subquery nhiều lần => nhìn rất rối. Sau đó mình biết tới
hàm COALESCE (postgresql, bên oracle là NVL), mình thấy câu query tiện đi bao nhiêu.

```sql
-- Example:
SELECT
  score,
  CASE WHEN score IS NULL
    THEN 0
  ELSE score END,
  COALESCE(score, 0)
FROM tschema.demo;

/* 
--Result
score	score	coalesce
1    	1	      1
NULL	0	      0
NULL	0	      0
0	    0	      0
3	    3	      3
NULL	0	      0
*/
```

COALESCE, NVL chỉ có ý nghĩa trong việc check NULL. Ví dụ: COALESCE( expression 1, expression 2, expression 3, …,
expression n) => giá trị trả về sẽ là giá trị không NULL đầu tiên, lần lượt expression từ trái qua phải.      
CASE WHEN trong một số trường hợp, có thể thay đổi được logic xử lý.