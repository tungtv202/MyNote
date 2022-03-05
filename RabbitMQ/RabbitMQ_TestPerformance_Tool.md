---
title: Rabbitmq - Test performance tool
date: 2022-03-05 13:05:00
updated: 2022-03-05 13:05:00
tags:
    - test tool
    - performance test
    - rabbitmq
category: 
    - rabbitmq
---

## Tool test performance RabbitMQ

[https://github.com/rabbitmq/rabbitmq-perf-test](https://github.com/rabbitmq/rabbitmq-perf-test)


TLDR:
- https://rabbitmq.github.io/rabbitmq-perf-test/stable/htmlsingle
- https://github.com/rabbitmq/rabbitmq-perf-test/tree/main/html#supported-scenario-parameters

Have 2 ways to run the test tool:

### Using `PerfTest`

The spec of the scenario will be set by arguments of the command. The result is a log file or metric.

Command run the example: 
```
bin/runjava com.rabbitmq.perf.PerfTest -x 2 -y 4 -h amqp://tung:tung@localhost:5672 --queue-pattern 'perf-test-%d'  --queue-pattern-from 1 --queue-pattern-to 10
```

### Using `PerfTestMulti`

The spec will be input in single `.js` file. The result is another `.js` file and can be visualized by graph WebUI

Command run the example: 
```
bin/runjava com.rabbitmq.perf.PerfTestMulti publish-consume-spec.js publish-consume-result.js
```

=> (2) more friendly


- `publish-consume-spec.js` - format example: https://raw.githubusercontent.com/rabbitmq/rabbitmq-perf-test/main/html/examples/publish-consume-spec.js
or https://raw.githubusercontent.com/rabbitmq/rabbitmq-perf-test/main/html/examples/various-spec.js  . More parameters: https://github.com/rabbitmq/rabbitmq-perf-test/tree/main/html#supported-scenario-parameters

- `publish-consume-result.js` - result file. The tool will append JSON results here. 
- Copy `publish-consume-result.js` to `/html/examples/publish-consume-result.js`. Start webserver to view graph by the command `bin/runjava com.rabbitmq.perf.WebServer` then goto: http://localhost:8080/examples/sample.html


### Other
- If rabbitmq has authen: Declare uri: `'uri': 'amqp://username:pass@localhost:5672'`

## Bonus

- Run rabbitmq 

```
docker run -it --rm --name rabbitmq -p 5672:5672 -p 15672:15672 -e RABBITMQ_DEFAULT_USER=tung -e RABBITMQ_DEFAULT_PASS=tung rabbitmq:management
```

- Tool download

```
https://github.com/rabbitmq/rabbitmq-perf-test/releases/download/v2.16.0/rabbitmq-perf-test-2.16.0-bin.tar.gz
```

- Test result on my pc env
- CPU: AMD 5600G - 6 core 12 threads
- RabbitMQ: Docker 3.9.13 (latest)
- Tool test: rabbitmq-perf-test 2.16.0 (latest)
- Scenario spec
```
[{'name': 'consume', 'type': 'simple',

'uri': 'amqp://tung:tung@localhost:5672',
'params':
    [{'time-limit': 300, 'producer-count': 2, 'consumer-count': 4}]}]
```
- Result:

From tool:
![image](https://user-images.githubusercontent.com/81145350/156550087-ea493a5d-1f99-4d37-819e-81292205d39f.png)
From Rabbitmq Webadmin
![image](https://user-images.githubusercontent.com/81145350/156550210-1ff39dd3-e6f4-4f31-b487-1de52ff45733.png)

