---
title: Apache James - Note
date: 2022-03-05 13:05:01
updated: 2022-03-05 13:05:01
tags:
    - apache james
category: 
    - apache james
---

# Apache James - Note

todo

1. sudo su => vào quyền root
2. cd /root/upn/james/james-gatling
  sbt => chạy simulation cho imap và jmap
  imap:
  source imap_env.sh
  gatling:testOnly org.apache.james.gatling.simulation.imap.PlatformValidationSimulation
  jmap-draft:
  gatling:testOnly org.apache.james.gatling.simulation.jmap.draft.PlatformValidationSimulation
  jmap-rfc:
  gatling:testOnly org.apache.james.gatling.simulation.jmap.rfc8621.PushPlatformValidationSimulation

  * remember to warmup James 10-20m
  Normal run (release perf test): 2 pods, 10k user imap/jmap-draft, 6k users jmap rfc