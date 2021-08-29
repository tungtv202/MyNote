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

- Two phase locking (avoid conflict)
    - Shared lock (read lock)
    - Exclusive lock (write lock)

=> Deadlock

- Multi-Version Concurrency control (detect conflict)
    - Oracle: uses the `undo segments`(https://docs.oracle.com/database/121/CNCPT/consist.htm#CNCPT221)
    - Sql Server: mặc định dùng 2PL cho tất cả isolation level
    - Postgres SQL:  lưu cả `current rows` và `previous version` trong cùng 1 `actual database`. Mỗi row table có 2
      column xmin,xmax dùng để kiểm soát row version. Khi row được inserted, transaction identifier được lưu vào xmin
      column. Khi xóa hoặc update, thì sẽ tạo row mới với transaction identifier được lưu vào cột xmax.
    - MySQL: rollback segment

## Phenomena

### Dirty write

- Dirty write xảy ra khi có 2 transaction cùng được phép ghi vào 1 row cùng lúc. => Dẫn tới việc dữ liệu có thể bị ghi
  đè bởi commit thứ 2.
  ![DrityWrite](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/dirty_write1.JPG)
- Có thể dẫn tới vấn đề khi 1 trong 2 commit muốn roll back lại, thì sẽ lựa chọn commit nào để rollback?

### Dirty read

- Xảy ra khi 1 transaction đọc dữ liệu đã bị thay đổi bởi 1 transaction khác. Nhưng transaction đó lại chưa commited.
  ![DrityRead](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/drity_read1.JPG)
- -> để tránh điều này xảy ra, thì khi data thay đổi chưa được commited, thì chỉ có transaction đó mới read được data
  thay đổi. Còn các transaction khác thì không thấy data thay đổi.
- Nếu db sử dụng cơ chế Two Phase Locking, những row đang ở trạng thái uncommitted sẽ bị lock bởi transaction đang ghi
  vào, (các transaction khác muốn đọc vào sẽ bị chặn)
- Nếu db sử dụng cơ chế MVCC (Multi Version Concurrency Control), db sẽ sử dụng undo log (cái đang lưu trữ giá trị của
  row trước lúc committed) để trả lại cho transaction cần đọc.

#### Non-Repeatable read

![Non_reapeatableRead](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/Non_reapeatable_read1.JPG)

- Với JPA/Hibernate để tránh điều này, thì data của row được cache ở Persistence Context

#### Phantom read

![PhantomRead](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/PhantomRead1.JPG)

### Read skew

![ReadSkew1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/ReadSkew1.JPG)

### Write skew

![WriteSkew1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/WriteSkew1.JPG)

### Lost update

![LostUpdate1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/LostUpdate1.JPG)

- Với Hibernate/JPA thì sẽ tránh bằng việc sử dụng Row Version, để Optimistic Lock. (Cách này là cách application sẽ
  handler)

## Isolation level

|  Isolation level    |   Dirty read    |   Non-repeatable read    |   Phantom read    | 
|---	|---	|---	|---	|
| Read Uncommitted    |   Yes    |   Yes    |   Yes    |
| Read Committed    |   No    |   Yes    |   Yes    |
| Repeatable Read    | No|  No |   Yes    |
| Serializable    |   No    |   No    |   No    |

### Read Uncommitted

![ReadUncommitted_Table1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/ReadUncommited_Table1.JPG)

- Oracle không hỗ trợ Dirty read

### Read Committed

![ReadCommitted_Table1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/ReadCommited_Table1.JPG)

- Oracle: tất cả statement phải có start_timestamp  (để create database snapshot point-in-time). Khi có 2 transaction
  cùng update 1 record, thì transaction 1 sẽ lock record để tránh dirty write.

### Repeatable Read

![RepeatableRead_table1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/ReapeabtaleRead_Table1.JPG)

### Serializable

![Serializable_Table1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/persistence/sqldb/Serializable_table1.JPG)

# Transaction - Durability

- Oracle: redo log. Vì lý do performance, redo record được lưu trong buffer, và Log Writer sẽ flush từ in-memory record
  về redo log file. (Vậy là vẫn có rủi ro nếu bị crash khi không flush kịp?). Oracle có tối thiểu 2 redo files, nhưng
  chỉ có 1 active. Khi transaction được commit, database sẽ flush từ buffer để persisted.
- SQL Server: compile cả undo log và redo log trong 1 file là `transaction log`. Khi transaction được committed nó sẽ
  flush xuống disk trước, xong mới return về cho client (chắc chắn phết). Từ SQL Server 2014, có hỗ
  trợ `configurable durability`(https://msdn.microsoft.com/en-us/library/dn449490.aspx), log flush sẽ được delayed, mục
  đích cho tăng performance IO
- PostgreSQL: WAL (Write-Ahead Log), log entries được buffer trong in-memory và flush xuống disk mỗi khi transaction
  được committed (http://www.postgresql.org/docs/current/static/wal-intro.html)
- My SQL: redo log entries được liên kết với single transaction
