---
title: Java Design Pattern
date: 2021-08-04 00:05:26
tags:
    - java
    - pattern
    - design pattern
    - proxy
    - decorator
category: 
    - java
---

## Proxy vs Decorator pattern
### Similarities
- Structure - both patterns forms a wrapper over real object
- Syntax - in both patterns, a wrappers entity class is created that implements the same interface as that of the real entity class 

### Differences
1. Intention 
- Decorator Pattern - wraps entity and adds new functionality to it
- Proxy Pattern - wrap entity and r estricts direct access to that entity, for security or performance or remote access 

2. Usability
- Decorator pattern allows to consume both decorator and original entity whereas Proxy pattern allows to consume only proxy class and must completely restrict the direct access to original entity.

3. Instantiation Technique
- Decorator Pattern - can instantiate the original object or can accept the instance to decorate from consumer (via consutrctor)
- Proxy Pattern - can not accept original instance from consumer since original object is abstraction for a consumer via Proxy. Hence, proxy internally instantiates the original object.

4. The delegate’s lifecycle     
- Some `keyword context`: 
    - `Aggregation`: when the child class `CAN` exist independently of the parent class. Example: (Car vs Wheel, When there is no car object, the wheels can still exist (maybe for truck))
    - `Composition`: when the child class `CANNOT` exist independtly of the parent class. Example: A Library class has a set of Accounts. When remove A Library, the Accounts cannot stand on their own.
- Decorator: The delegate is not owned by the decorator and thus it is an `aggregate`.
- Proxy: The delegate does not exist without the proxy, it is a `composite` of the proxy.

