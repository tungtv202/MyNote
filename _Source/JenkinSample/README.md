## Building the image

```bash
$ docker build -t jenkins-master .
```

## Running the container

```bash
$ docker run -d -p 8080:8080 -p 50000:50000 --env-file=./env.file --name jenkins jenkins-master
```

You have to modify env.file.

## Running slaves
You need to start Jenkins slaves.

```bash
$ docker build -f DockerfileSlave -t jenkins-slave-runner .
$ docker run -d -v /var/run/docker.sock:/var/run/docker.sock --rm --name jenkins-slave jenkins-slave-runner -url <master-url> <secret> <host>
```

Where:

 - __master-url__: is the URL of your jenkins
 - __ secret__: is the agent secret
 - __host__: is the agent name

For running the gatling-imap job, you need to add explicitly "--network=host" to the above command.
