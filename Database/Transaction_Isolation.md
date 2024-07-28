---
title: Transaction - Isolation & Durability
date: 2020-12-20 18:00:26
updated: 2020-12-20 18:00:26
tags:
    - transaction
    - isolation
    - durability
    - persistence
category: 
    - database
---

# Transaction - Isolation

## Concurrency Control

- **Two-Phase Locking (2PL):** Avoids conflicts by using:
  - **Shared Lock (Read Lock):** Allows multiple transactions to read but not modify a resource.
  - **Exclusive Lock (Write Lock):** Allows one transaction to modify a resource, preventing others from reading or modifying it.
  - **Deadlock:** A situation where two or more transactions are waiting for each other to release locks, causing all of them to be blocked.

- **Multi-Version Concurrency Control (MVCC):** Detects conflicts by using multiple versions of data.
  - **Oracle:** Uses the `undo segments` [documentation](https://docs.oracle.com/database/121/CNCPT/consist.htm#CNCPT221).
  - **SQL Server:** Defaults to 2PL for all isolation levels.
  - **PostgreSQL:** Stores both `current rows` and `previous versions` in the actual database. Each row has `xmin` and `xmax` columns to control row version. When a row is inserted, the transaction identifier is stored in the `xmin` column. When a row is deleted or updated, a new row is created with the transaction identifier in the `xmax` column.
  - **MySQL:** Uses rollback segments.

## Phenomena

### Dirty Write

- Occurs when two transactions simultaneously write to the same row, potentially leading to one transaction's changes being overwritten by the other.
  ![Dirty Write](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/dirty_write1.JPG)
- If one of the transactions needs to roll back, it can be unclear which changes to retain.

### Dirty Read

- Occurs when a transaction reads data that has been modified by another transaction that has not yet committed.
  ![Dirty Read](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/drity_read1.JPG)
- To avoid this, uncommitted changes should only be visible to the transaction that made them.
- **2PL:** Rows in an uncommitted state are locked by the writing transaction, blocking other transactions from reading them.
- **MVCC:** Uses undo logs to provide the previous version of the row to reading transactions.

### Non-Repeatable Read

![Non-Repeatable Read](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/Non_reapeatable_read1.JPG)

- **JPA/Hibernate:** Cache row data in the Persistence Context to avoid this issue.

### Phantom Read

![Phantom Read](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/PhantomRead1.JPG)

### Read Skew

![Read Skew](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/ReadSkew1.JPG)

### Write Skew

![Write Skew](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/WriteSkew1.JPG)

### Lost Update

![Lost Update](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/LostUpdate1.JPG)

- **Hibernate/JPA:** Use Row Version to implement Optimistic Locking, handling this issue at the application level.

## Isolation Levels

| Isolation Level     | Dirty Read | Non-Repeatable Read | Phantom Read |
|---------------------|------------|---------------------|--------------|
| Read Uncommitted    | Yes        | Yes                 | Yes          |
| Read Committed      | No         | Yes                 | Yes          |
| Repeatable Read     | No         | No                  | Yes          |
| Serializable        | No         | No                  | No           |

### Read Uncommitted

![Read Uncommitted](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/ReadUncommited_Table1.JPG)

- **Oracle:** Does not support Dirty Read.

### Read Committed

![Read Committed](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/ReadCommited_Table1.JPG)

- **Oracle:** Ensures that all statements have a `start_timestamp` to create a database snapshot at a point in time. When two transactions update the same record, the first transaction locks the record to prevent a dirty write.

### Repeatable Read

![Repeatable Read](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/ReapeabtaleRead_Table1.JPG)

### Serializable

![Serializable](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/Serializable_table1.JPG)

# Transaction - Durability

- **Oracle:** Uses redo logs. For performance reasons, redo records are stored in a buffer, and the Log Writer flushes from in-memory records to redo log files. There is a risk of data loss if the buffer isn't flushed before a crash. Oracle maintains at least two redo files, but only one is active at a time. When a transaction is committed, the database flushes the buffer to persist the data.
- **SQL Server:** Combines undo and redo logs in a single `transaction log` file. When a transaction is committed, the data is flushed to disk before returning to the client. Since SQL Server 2014, it supports `configurable durability`, allowing log flush delays to improve I/O performance [documentation](https://msdn.microsoft.com/en-us/library/dn449490.aspx).
- **PostgreSQL:** Uses Write-Ahead Log (WAL). Log entries are buffered in memory and flushed to disk when a transaction is committed [documentation](http://www.postgresql.org/docs/current/static/wal-intro.html).
- **MySQL:** Redo log entries are linked to single transactions.
