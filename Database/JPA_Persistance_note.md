---
title: JPA - Hibernate - Persistence Note
date: 2020-12-27 13:47:26
updated: 2020-12-27 13:47:26
tags:
    - jpa
    - hibernate
    - persistence
category: 
    - database
---

# Identifier: use sequence vs table generator

- Table generator: khai báo column ID là IDENTITY (SQL Server), hoặc AUTO INCREMENT (MYSQL), trong Hibernate khai
  báo `@GeneratedValue`
- Sequence: tạo 1 sequence riêng, độc lập, không phụ thuộc vào table nào.

- Table generator: bị ràng buộc bởi table khai báo, sequence thì không. Khi sử dụng sequence cho performance cao hơn (
  insert nhanh hơn, rõ rệt hơn khi concurrency insert). Nguyên nhân vì table generator tốn nhiều chi phí cho việc
  row-lock
- Sequence có thể reset, set max, và có thể share cho nhiều table xài chung.
- Sequence: là 1 non-transaction object (vì xảy ra bên ngoài transaction context)
- => nên sử dụng Sequence. (vì có benchmark cao hơn)

# FetchType LAZY

- For @OneToMany and @ManyToMany associations, Hibernate uses its own collection Proxy implementations (e.g.
  PersistentBag, PersistentList, PersistentSet, PersistentMap) which can execute the lazy loading SQL statement on
  demand
- N+1 Query problem: nếu có 1 Collection Entity, khi forEach chúng thì sẽ bị N+1 query. Điều này không chỉ Lazy mà Eager
  cũng bị. Để khắc phục vấn đề này, nên sử dụng `join`
  ![Fix n+1 query](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/Fix_N1_Query.JPG)

## LazyInitializationException

- Nguyên nhân gây ra lỗi này khi Persistence Context đã close (context của query Entity đã close), xong sau đó cố gắng
  fetch lazy dữ liệu từ ORM (ví dụ: OneToMany). Ví dụ case thực tế: tạo ra 1 method, và không có khai
  báo `@Transactional`, khi đó get Entity chính, và get ORM mặc định ở 2 transaction khác nhau. Khi thực hiện get ORM sẽ
  throw ra lỗi này. (ngược lại, nếu khai báo cùng 1 Transaction thì không bị lỗi). => vấn đề này gây khó khăn cho việc
  tích hợp code business, vì việc load lazy không được linh động, nó phải diễn ra ở cùng 1 Service, transaction. Khi đó
  code business có thể sẽ làm cho transaction bị `long time`
- Có 2 cách để giải quyết vấn đề này, tuy nhiên cả 2 cách đều `không được recommend`.
    - Open session in view anti-pattern
    - Temporary Session Lazy Loading Anti-Pattern: cấu hình này khá đơn giản, với Spring chỉ cần khai báo
      properties: `hibernate.enable_lazy_load_no_trans=true`. // không rõ cơ chế lắm, nhưng có vẻ như là cái này sẽ tốn
      nhiều connect tới db hơn, và tiềm năng nguy cơ N+1 cao hơn, nó luôn `new transaction` và transaction log luôn
      được `force flush`???

# Batching

- Hibernate chỉ sử dụng `PreparedStatement` cho việc tự động insert/update/delete DML
- Mặc định Hibernate không được cấu hình mode `jdbc batch`. Khi đó sẽ gặp case khi insert 1 list N entity. Nó sẽ sinh ra
  N query insert

```java
for (int i = 0; i < 3; i++) {
entityManager.persist(new Post(String.format("Post no. %d", i + 1)));
}
// và log hibernate nó sẽ như thế này
INSERT INTO post (title, id) VALUES (Post no. 1, 1)
INSERT INTO post (title, id) VALUES (Post no. 2, 2)
INSERT INTO post (title, id) VALUES (Post no. 3, 3)
```

Ta có thể cấu hình để tối ưu hơn đoạn `batch` này bằng: `hibernate.jdbc.batch_size=5`. (lưu ý: cấu hình này là global ).
Khi đó query hibernate sẽ khác

```
Query: ["INSERT INTO post (title, id) VALUES (?, ?)"],
Params: [('Post no. 1', 1), ('Post no. 2', 2), ('Post no. 3', 3)]
```

- Tuy nhiên `batch` mode này sẽ bị vô hiệu, nếu như Entity có khai báo `@Id` (tức là Persistence Context cần quản lý
  Entity).
- `batch mode` cũng bị vộ hiệu, nếu có khai báo ORM (`@OneToMany, @ManyToOne`). => Để fix vấn đề này cần cấu hình
  thêm `hibernate.order_inserts=true`. Khi đó query sinh ra=

```sql
INSERT INTO post (title, id)
VALUES (Post no. 0, 1), (Post no. 1, 3), (Post no. 2, 5)
INSERT INTO post_comment (post_id, review, id)
VALUES (1, Good, 2), (3, Good, 4), (5, Good, 6)
```

- Tương tự khi insert, có thể cấu hình `hibernate.order_updates=true` khi cần `update`
- Với Entity có sử dụng `@Version` (để tránh optimistic lock), thì sẽ có nguy cơ bị `StaleObjectStateException`. Có thể
  sẽ phải chỉnh sửa cấu hình `hibernate.jdbc.batch_versioned_data`

# Prevent Optimistic Lock

- Chia nhỏ table hay bị lock ra, thành nhiều table => giảm được tỉ lệ query tới column gây ra lock
- Sử dụng `@OptimisticLocking` trên Entity. (Lưu ý với OptimisticLockType.ALL và OptimisticLockType.DIRTY, cần phải đi
  kèm với `@DynamicUpdate`)

# Caching
todo

## Pessimistic Locking vs Optimistic Locking
- pessimistic will more consistency than optimistic
- Optimistic use `version` row to lock (detecting when update)
- Pessimistic: another query will to wait state when has once query "lock" resource