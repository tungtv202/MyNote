---
title: Domain-Driven Design & Event-Driven Architecture
date: 2020-01-26 18:00:26
updated: 2020-01-26 18:00:26
tags:
    - ddd
    - domain driver design
category: 
    - other
---

# Domain-Driven Design and Event-Driven Architecture

- When placing orders during peak hours, customers care about getting the right products, in the right quantity, with a successful notification. The processing during peak hours is different from the processing of orders for operators later. This design ensures that the system runs fast and stable.
- For example: talking about orders, there will be an order and order items. The database will have 2 tables, order and order item, but there will be only one Order object. When talking about an order, it must include both order and order items. There cannot be an order without items, and it doesn't make sense to talk about order items without knowing the order they belong to.
- If you need to retrieve 2 fields of information, use 2 separate queries (already global in the system), then aggregate them with code, rather than writing a new query just to get 2 fields for one specific need.
- **Model** is not a **Table**.
  - **Table** is designed for quick storage and retrieval.
  - **Model** reflects the logical business properties of the system.

## Aggregate

- An aggregate is a group of data objects treated as a single unit within the system.
  - Example: order and order items should be treated as consistent components of the aggregate order, identified in the system by the order id.
- Ensures a consistent view throughout the system.
- When referring to an aggregate, it must be a complete, fully defined data object.
- There should be no separate business logic for each component of an aggregate.
- All logic from data access to service should revolve around aggregates.
- Choose the "just right" scope for aggregates.
- Too large an aggregate scope leads to poor performance.
- Too small an aggregate scope leads to fragmented and hard-to-manage logic.
- Ensure the components of an aggregate are always consistent.
- Use unified data access patterns:
  - Repository Pattern
  - ORM
- Structure API resources corresponding to aggregates.

## Don't Repeat Yourself:

- Don't confuse Aggregate with DTO (DTO is for working with a specific data block and writing code for Data Access for that data layer).
- Don't design APIs based on display needs.
- Don't build data access for each function.

### Architectural Model

![MoHinhKienTruc](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/ddd/MoHinhKienTruc.JPG)

### Infrastructure Layer

- Works with underlying components such as DB, Message Queue, File...
- Most of the system logic is business logic.
- Don't let infrastructure logic slow down business development.
- Must be highly reusable.
- Must be consistent throughout the system structure.
- **Patterns:**
  - Repository Pattern
  - Observer Pattern
  - ORM Pattern

### Reusability Level

![Layer](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/ddd/layer.JPG)

- Higher layers are used more frequently.
- Lower layers must be highly reusable.
- Avoid designing equal complexity across all layers.

### Ensuring Message Order

- Ensure data write order.
- Ensure event sending order.
- Ensure event receiving order.

### Solution to Ensure Write Order

- **Solution 1:** Lock by key range, use transaction mode lock serializable. Example: lock by order id.
- **Solution 2:** Use two resources:    
  R1: snapshot of the object     
  R2: event log   
  Lock the update command on R1 and append to R2.
- **Solution 3:** If storing events in a table, use a composite primary key of the event:          
  Aggregate Id – Version      
  Events with the same version will conflict when inserting.

### Solution to Ensure Sending Order

- Don't apply simultaneous DB write and event send because there's no transaction.
- Must log events before sending them.
- Group events by the id of the aggregate that emits the event. Store events with a composite key: aggregateId – version.
- Load events to be sent by aggregate id, and send sequentially by version.
- Stop sending immediately if an error event is encountered.
- Recover -> Load by aggregateId and continue sending in version order.
- Use two tables:
  - Event table to store events.
  - Undispatched Event table to temporarily store events awaiting dispatch, deleted after sending.

### Ensuring Message Reception Order

- Group messages by an identifier, such as aggregate id.
- Messages in a group should be received by one thread at a time.
- Use Kafka's Partition or Windows Service Bus's Session features to ensure message order when routing.

---

**References:**

- [DDD Event-Driven Architecture PDF](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/other_file/DDD_EventDrivenArchitecture.pdf)
- [YouTube Video](https://youtu.be/glZs4QFfwbc)
