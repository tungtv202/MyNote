---
title: Netty In Action
date: 2022-12-08 23:26:26
updated: 2022-12-08 23:26:26
tags:
    - java
    - netty
category: 
    - java
---

All Netty servers require the following:
    - At least one ChannelHandler —This component implements the server’s process-
    ing of data received from the client—its business logic.
    - Bootstrapping—This is the startup code that configures the server. At a minimum,
it binds the server to the port on which it will listen for connection requests
    