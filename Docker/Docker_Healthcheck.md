---
title: Docker - Healthcheck & Graceful Shutdown
date: 2023-08-04 18:00:26
updated: 2023-08-04 18:00:26
tags:
    - docker
    - healthcheck
    - graceful shutdown
category: 
    - docker
---

# Healthcheck
## Why?
- monitor
- zero downtime deployment
- trigger something base on health status
## Healthcheck in Dockerfile
example
```Dockerfile
FROM nginx:1.17.7
RUN apt-get update && apt-get install -y curl

HEALTHCHECK --interval=2s --timeout=2s CMD curl -f http://james:8000/domains || exit 1
```
ref: https://docs.docker.com/engine/reference/builder/#healthcheck
```
The options that can appear before CMD are:
--interval=DURATION (default: 30s)
--timeout=DURATION (default: 30s)
--start-period=DURATION (default: 0s)
--retries=N (default: 3)
```
- The command’s exit status indicates the health status of the container. The possible values are:
```
0: success - the container is healthy and ready for use
1: unhealthy - the container is not working correctly
2: reserved - do not use this exit code
```

### Demo:
  [![height:500px](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/1DockerfileHealthcheckExample.png)](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/1DockerfileHealthcheckExample.mp4)

## Healthcheck in docker-compose

- Declare: ![h:600px bg right](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/2DockercomposeHealthcheck.png)
- More example:
```yaml
    healthcheck:
      test: wget --quiet --tries=1 --spider http://localhost:${PORT} || exit 1z
      interval: 30s
      timeout: 10s
      retries: 5
```
```yaml
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongo db:27017/speech-api --quiet
```
```yaml
    healthcheck:
      test: ["CMD", "redis-cli","ping"]
```

- `docker compose ps`:
  ![](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/2DockercomposePs.png)
- Get healthcheck log by inspect docker:
  ![](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/2CommandGetLogHealthCheck.png)

### Demo
- Demo:
  [![height:500px](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/2DockerComposeHealthCheck.png)](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/2DockerComposeHealthCheck.mp4)

# Graceful shutdown
## Why?
- Allows the service to complete any in-progress tasks
- Clean up any resources it is using
- Notify other services that it is going offline.
- Help prevent data loss
- Reduce downtime
- Avoid cascading failures that could affect other services

## Mechanism
- When you kill a PID on linux. Your application will receive a `signal`
- Base on each `signal`, Your application should handler it
- 3 Signal we should care:
  - SIGTERM: The SIGTERM signal requests a process to stop running. The process is given time to gracefully shut down.
  - SIGKILL: The SIGKILL signal forces the process to stop executing immediately. The program cannot ignore this signal.
  - SIGINT: The SIGINT signal is the same as pressing ctrl-c. On some systems, "delete" + "break" sends the same signal to the process. The process is given time to gracefully shut down.

- Total 64 signal types:
  ![h:300](https://www.saintlad.com/wp-content/uploads/2022/11/image4-13.png)
- For more info: https://www.linux.org/threads/kill-commands-and-signals.8881/

- Docker And The PID `1`: it will receive termination signals
- `docker stop` command sends `SIGTERM` signal to the `PID 1`. The `PID 1` is given 30 seconds to shut down, if it does not shut down in 30 seconds, then docker sends a `SIGKILL` signal which stops the process immediately. By default, stop waits 10 seconds for the container to exit before sending `SIGKILL`.

- Snapshoot from checking pid on `apache/james:memory-latest` container:
  ![](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/3GracefulPid1Check.png)
  => java app run on PID = `1` => correct way
- Notice when creating a Dockerfile
  ![](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/3Ref_DockerPid1_NodeVsNPM.png)
## James
Handler graceful in James:
  ![](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/3JamesHanderGraceful.png)
- Log from James when stopping James container: => James try to "dispose" something before it finally stopped

```
03:45:29.722 [INFO ] o.a.j.m.s.JMXServer - JMX server stopped
2023-06-28T03:45:29.722681185Z 03:45:29.722 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose Manage Sieve Service
2023-06-28T03:45:29.722689712Z 03:45:29.722 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose Manage Sieve Service done
2023-06-28T03:45:29.725654700Z 03:45:29.725 [INFO ] o.a.j.w.WebAdminServer - Web admin server stopped
2023-06-28T03:45:29.731379540Z 03:45:29.731 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose SMTP Service
2023-06-28T03:45:31.744946195Z 03:45:31.744 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose SMTP Service done
2023-06-28T03:45:31.744969930Z 03:45:31.744 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose SMTP Service
2023-06-28T03:45:33.748734899Z 03:45:33.748 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose SMTP Service done
2023-06-28T03:45:33.748754646Z 03:45:33.748 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose SMTP Service
2023-06-28T03:45:35.752316430Z 03:45:35.752 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose SMTP Service done
2023-06-28T03:45:35.752336378Z 03:45:35.752 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose POP3 Service
2023-06-28T03:45:35.752339383Z 03:45:35.752 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose POP3 Service done
2023-06-28T03:45:35.752344243Z 03:45:35.752 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose IMAP Service
2023-06-28T03:45:37.755951232Z 03:45:37.755 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose IMAP Service done
2023-06-28T03:45:37.755973675Z 03:45:37.755 [INFO ] o.a.j.p.l.n.AbstractConfigurableAsyncServer - Dispose IMAP Service
```
- Question?
  - What happens if the application needs more time to complete the task than the grace period of Docker? 
- add `addShutdownHook` to `MemoryJamesServerMain` for watch => app shutdown after `10seconds`
  ![](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/4JamesMemoryShutDownHook.png)
- Docker compose support configure `stop_grace_period` and `stop_signal`
  ![](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/3IncreaseGracefulShutDowntime_Ref.png)
- Result after changing `stop_grace_period` (default -> 1 minute)
  ![](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/3IncreaseGracefulShutDowntime.png)
- Demo:
  [![height:500px](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/3GracefulShutDown60s.png)](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/3GracefulShutDown60s.mp4)

## K8s 
- `terminationGracePeriodSeconds`: 30s
  ![](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/5k8sTermialGraceShutdown.png)
- K8s log when stop tmail pod
  ![](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/5k8sGracefulShutdownLog.png)
- Healthcheck
  `livenessProbe`
  ![](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/image/5k8sLivenessProbeConfig.png)
- Demo:
  [![height:500px](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/4k8s.png)](https://s3.ap-east-1.amazonaws.com/aws-s3.tungexplorer.me/docker_healthcheck_graceful_slide/4k8s.mp4)