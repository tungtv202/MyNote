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

# Identifier: Use Sequence vs Table Generator

- **Table Generator:** Declare the ID column as IDENTITY (SQL Server) or AUTO INCREMENT (MySQL), and in Hibernate, declare `@GeneratedValue`.
- **Sequence:** Create a separate, independent sequence not tied to any table.

- **Table Generator:** Bound by the declared table, whereas a sequence is not. Using a sequence results in better performance (faster inserts, especially noticeable during concurrent inserts) because the table generator incurs more row-lock costs.
- **Sequence:** Can be reset, set to a maximum value, and shared across multiple tables.
- **Sequence:** A non-transactional object (operates outside the transaction context).
- **Recommendation:** Use Sequence for higher performance.

# FetchType LAZY

- For `@OneToMany` and `@ManyToMany` associations, Hibernate uses its own collection proxy implementations (e.g., `PersistentBag`, `PersistentList`, `PersistentSet`, `PersistentMap`) which can execute the lazy loading SQL statement on demand.
- **N+1 Query Problem:** If you have a collection entity, when iterating over them with a `forEach` loop, N+1 queries can occur. This affects both lazy and eager loading. To mitigate this issue, use `join`.
  ![Fix N+1 Query](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/Fix_N1_Query.JPG)

## LazyInitializationException

- This exception occurs when the Persistence Context is closed (the context of the query entity is closed), and you attempt to fetch lazy-loaded data from the ORM (e.g., `OneToMany`). For instance, creating a method without `@Transactional`, fetching the main entity and its ORM in two separate transactions can throw this exception. (Conversely, if declared within the same transaction, it won't throw an exception). This issue complicates business code integration because lazy loading must occur within the same service and transaction, potentially leading to long-running transactions.
- Two ways to resolve this issue, though both are not recommended:
  - Open Session in View Anti-Pattern
  - Temporary Session Lazy Loading Anti-Pattern: Configure with Spring by setting the property `hibernate.enable_lazy_load_no_trans=true`. This might increase DB connections and potential N+1 issues as it always starts new transactions and forces transaction logs to flush.

# Batching

- Hibernate uses `PreparedStatement` for automatic insert/update/delete DML operations.
- By default, Hibernate is not configured for JDBC batch mode, leading to N queries for inserting a list of N entities:

```java
for (int i = 0; i < 3; i++) {
    entityManager.persist(new Post(String.format("Post no. %d", i + 1)));
}
// Hibernate log output
INSERT INTO post (title, id) VALUES (Post no. 1, 1)
INSERT INTO post (title, id) VALUES (Post no. 2, 2)
INSERT INTO post (title, id) VALUES (Post no. 3, 3)
```

To optimize batching, configure `hibernate.jdbc.batch_size=5` (note: this is a global configuration). The Hibernate query log will then show:

```sql
Query: ["INSERT INTO post (title, id) VALUES (?, ?)"],
Params: [('Post no. 1', 1), ('Post no. 2', 2), ('Post no. 3', 3)]
```

- Batch mode is disabled if the entity declares `@Id` (Persistence Context needs to manage the entity).
- Batch mode is also disabled if ORM relationships (`@OneToMany`, `@ManyToOne`) are declared. To fix this, configure `hibernate.order_inserts=true`. The resulting query will be:

```sql
INSERT INTO post (title, id)
VALUES (Post no. 0, 1), (Post no. 1, 3), (Post no. 2, 5)
INSERT INTO post_comment (post_id, review, id)
VALUES (1, Good, 2), (3, Good, 4), (5, Good, 6)
```

- Similarly, configure `hibernate.order_updates=true` for updates.
- With entities using `@Version` (to avoid optimistic locking), there is a risk of `StaleObjectStateException`. Adjust the configuration with `hibernate.jdbc.batch_versioned_data`.

# Prevent Optimistic Lock

- Split frequently locked tables into multiple tables to reduce the query rate on the locking column.
- Use `@OptimisticLocking` on the entity. (Note: With `OptimisticLockType.ALL` and `OptimisticLockType.DIRTY`, `@DynamicUpdate` must be used as well).

# Caching

_TODO_

## Pessimistic Locking vs Optimistic Locking

- Pessimistic locking offers more consistency than optimistic locking.
- Optimistic locking uses the `version` row to detect conflicts during updates.
- Pessimistic locking requires other queries to wait when a resource is locked by another query.
