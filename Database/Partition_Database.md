---
title: Partition Database
date: 2021-07-31 18:00:26
updated: 2021-07-31 18:00:26
tags:
    - sql
    - partition
    - sharding
category: 
    - database
---

# Partition Database

## Table inheritance vs partitioning

- Partitioning < inheritance

## Horizontal & Vertical partitioning

Example:

- Table: Student
- Column: ID, Name, Code, ClassCode, Email, PhoneNumber

So:

- Horizon: partition1(Name: A->N), partition2(Name: M->Z)
- Vertical: partition1(ID, Name, ClassCode), partition2(Code, Email, PhoneNumber)

## Horizontal partitioning

- By Range: via date, numeric, alphabet
- By List: ENUM value
- By Hash (best loadbalancer)

### Note

- Can not declare PrimaryKey or Unique on Partition table (But CAN with child table). Reason is ensure to isolate
  among child partition table.
- Can not delecare two child table has conflict range.(partition key conflict)
- What happened if CRUD on column not in RANGE?
    - Error if not `TABLE DEFAULT PARTITION`

## Partition pruning

- Can understand it is a "coordinator", that will detect exactly child partition via `key column partition`
- If `pruning` has been disabled, so the partition don't have sense. Because it will scan all child partition

## Multi-level partition

## Sharding

- The specific variant of Horizon Partition, but each partition will host on different (separate) database nodes.
