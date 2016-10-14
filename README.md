# Spring Cloud Data Flow Server Nomad

This project provides support for deploying Spring Cloud Dataflow's streaming and task/batch data pipelines to [Hashicorp Nomad](https://www.nomadproject.io). 
It includes an implementation of Spring Cloud Data Flow’s [Deployer SPI for Nomad](https://github.com/donovanmuller/spring-cloud-deployer-nomad).

This implementation borrows heavily from the [spring-cloud-dataflow-server-kubernetes](https://github.com/spring-cloud/spring-cloud-dataflow-server-kubernetes)
project.

For more information please refer to the Spring Cloud Data Flow [reference documentation](http://docs.spring.io/spring-cloud-dataflow-server-kubernetes/docs/current/reference/htmlsingle/).

## Building

Clone the repo and type

```bash
$ ./mvnw clean install
```

To build the docker image for the Data Flow Server

```bash
$ ./mvnw package docker:build -pl :spring-cloud-dataflow-server-nomad
```

## Development Nomad instance

Below are a few examples of Nomad environments that you can test this deployer server with.

### Hashistack Vagrant

For local testing of the deployer server you can stand up an instance of Nomad with the
[Hashistack Vagrant](https://github.com/donovanmuller/hashistack-vagrant) project.

#### Hashistack Quickstart

Follow the below steps to start up a local Hashistack for local testing/development:

```bash
$ git clone https://github.com/donovanmuller/hashistack-vagrant.git
$ cd hashistack-vagrant
$ vagrant plugin install landrush # requires the 'landrush' plugin
$ vagrant up
$ vagrant ssh
...
vagrant@hashistack:~$ tmuxp load full-hashistack.yml
...
```

the `nomad-client` endpoint will be available at `172.16.0.2` on port `4646`.

For more details please visit the [hashistack-vagrant](https://github.com/donovanmuller/hashistack-vagrant) project.

#### Kafka

To start up an instance of Kafka as the stream binder for development/testing purposes, you can use the [`kafka.nomad`](src/etc/nomad/kafka.nomad)
job definition. The easiest way to do this is to copy `kafka.nomad` to the directory where the
Hashistack `Vagrantfile` is located (as this is shared by default with the VM at `/vagrant`):

```bash
$ cp src/etc/nomad/kafka.nomad <hashistack-vagrant location>/
```

and then, in a SSH session (`vagrant ssh`) on the Hashistack VM, run the job with:

```bash
$ pwd
<hashistack-vagrant location> # should be he directory of the hashistack-vagrant cloned project
$ vagrant ssh
...
vagrant@hashistack:~$ nomad run /vagrant/kafka.nomad
==> Monitoring evaluation "87fcaf98"
    Evaluation triggered by job "kafka"
    Allocation "4dc0a5d4" created: node "d20afbac", group "kafka"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "87fcaf98" finished with status "complete"
vagrant@hashistack:~$ nomad status
ID       Type     Priority  Status
kafka    service  50        running
```

once the `spotify/kafka` image has been pulled, you should have a Kafka instance running on `kafka:9092` and 
a Zookeeper instance on `zookeeper:2181`. The `kafka` and `zookeeper` names are resolved via the [Consul DNS interface](https://github.com/donovanmuller/hashistack-vagrant#service-discovery).

#### Running Spring Cloud Data Flow Server

##### Standalone

To run the deployer server as a standalone instance outside Nomad, build the deployer server (see above)
and use the following command:

```bash
$ pwd
.../spring-cloud-dataflow-server-nomad/spring-cloud-dataflow-server-nomad/target
$ java -jar spring-cloud-dataflow-server-nomad-1.0.0.BUILD-SNAPSHOT.jar \
    --spring.cloud.deployer.nomad.nomadHost=172.16.0.2 \
    --spring.cloud.deployer.nomad.nomadPort=4646 \ # this is the default so can be omitted   
    --spring.cloud.deployer.nomad.resourcesMemory=256  
```

The Spring Cloud Data Flow Shell and UI ([`/dashboard`](http://localhost:9393/dashboard)) will be available at: [http://localhost:9393](http://localhost:9393)

##### Nomad job

You can also run the deployer server as a Nomad job.
The [job definition](https://www.nomadproject.io/docs/jobspec/index.html) is located at [`src/etc/nomad/scdf-deployer.nomad`](src/etc/nomad/scdf-deployer.nomad)
and uses the [Docker task driver](https://www.nomadproject.io/docs/drivers/docker.html)
to run the [`donovanmuller/spring-cloud-dataflow-server-nomad:1.0.0.BUILD-SNAPSHOT`](https://hub.docker.com/r/donovanmuller/spring-cloud-dataflow-server-nomad/))
Docker image.

As we did for `kafka.nomad`, copy `scdf-server.nomad` to the directory where the Hashistack `Vagrantfile` is located:

```bash
$ cp src/etc/nomad/scdf-deployer.nomad <hashistack-vagrant location>/
```

and then, in a SSH session (`vagrant ssh`) on the Hashistack VM, run the job with:

```bash
$ pwd
<hashistack-vagrant location> # should be he directory of the hashistack-vagrant cloned project
$ vagrant ssh
...
vagrant@hashistack:~$ nomad run /vagrant/scdf-deployer.nomad
==> Monitoring evaluation "994535f4"
    Evaluation triggered by job "scdf-deployer"
    Allocation "c191cbb5" created: node "d20afbac", group "scdf-deployer"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "994535f4" finished with status "complete"
vagrant@hashistack:~$ nomad status
ID             Type     Priority  Status
kafka          service  50        running
scdf-deployer  service  50        running
```

once the server is `running` (`nomad status scdf-deployer`), the server and UI ([`/dashboard`](http://scdf-server.hashistack.vagrant/dashboard))
will be available at: http://scdf-server.hashistack.vagrant

Using the Spring Cloud Data Flow Shell, you can target the server with:

```bash
$ wget http://repo.spring.io/release/org/springframework/cloud/spring-cloud-dataflow-shell/1.0.1.RELEASE/spring-cloud-dataflow-shell-1.0.1.RELEASE.jar
...
$ java -jar spring-cloud-dataflow-shell-1.0.1.RELEASE.jar \
  --dataflow.uri=http://scdf-server.hashistack.vagrant
...
```

#### Resources

The `hashistack-vagrant` VM is configured by default with `2048 MB` of memory and `2` CPUs.
If you run into issues with job allocations failing because of resource starvation, you can tweak the
memory and CPU configuration in the `Vagrantfile`.

##### A conundrum

> In context of using the [Docker task driver](https://www.nomadproject.io/docs/drivers/docker.html)
and using the starter apps Docker images (e.g. [kafka-docker apps](http://bit.ly/1-0-4-GA-stream-applications-kafka-docker)).

A Nomad job definition must include [resource](https://www.nomadproject.io/docs/jobspec/index.html#resources)
specifications. The Nomad deployer uses a default of `512 MB` (see [here](https://github.com/donovanmuller/spring-cloud-deployer-nomad/blob/master/src/main/java/org/springframework/cloud/deployer/spi/nomad/NomadDeployerProperties.java#L101))
and while that may seem excessive (and it is), if you want to deploy
quite a few streams/tasks you might want to tweak the VM memory settings to accommodate the amount of apps, to say `8192 MB`. 
However, with that comes a tricky problem...

When you increase the VM memory and configure a lower `spring.cloud.deployer.nomad.resourcesMemory` setting
for the deployed apps, say `256 MB`, you will notice that your apps (at least the starter apps) will struggle to start
due to hitting memory limits on the JVM.

At first blush this doesn't make sense because `256 MB` should be more than enough for a starter app to startup in, especially
starter apps like the [`log-sink`](https://github.com/spring-cloud/spring-cloud-stream-app-starters/tree/master/log/spring-cloud-starter-stream-sink-log).
The problem is this: the Docker container has a memory resource limit of `256 MB` (which is what `spring.cloud.deployer.nomad.resourcesMemory` relates too) but the Java JVM
without `-Xms` or `-Xmx` settings defaults to choosing default heap sizes (see http://stackoverflow.com/a/40025912/2408961) based on the machines memory.
You would assume that the JVM would take the Docker containers memory (`256 MB`) and calculate the defaults but
it does not, it takes the *host machine's* (hashistack VM's) memory value (`2048 MB`) instead.
With a high value like `2048 MB`, the default heap sizes could be 1/64 - 1/2 of that, so something like `32` / `1024`
depending on the JVM. These heap sizes then push the boundary of the actual Docker container memory limits
and your app ends up halting during startup and never actually becomes healthy, resulting in
a kill/start loop as Nomad tries to restart your app in vain.

Unfortunately, the starter apps do not [*currently*](https://github.com/spring-cloud/spring-cloud-stream-app-maven-plugin/issues/10)
support passing `JAVA_OPTS` which would allow the deployer to set `-Xms`/`-Xmx`. Therefore, you need to think carfefully if you're planning to deploy
a few streams or tasks because the higher you push the VM memory, the higher you need to push the
`spring.cloud.deployer.nomad.resourcesMemory` value to counteract the above issue.

As an example, the [HTTP Source](https://github.com/spring-cloud/spring-cloud-stream-app-starters/tree/master/http/spring-cloud-starter-stream-source-http)
starter app deployed into the hashistack VM with `2048 MB` of system memory
and a `spring.cloud.deployer.nomad.resourcesMemory` value of `256` for the app, shows the following metrics ([/metrics](http://docs.spring.io/spring-boot/docs/current/reference/html/production-ready-metrics.html#production-ready-metrics)):

```
{
    mem: 282087,
    mem.free: 121287,
    processors: 2,
    instance.uptime: 2425860,
    uptime: 2442986,
    systemload.average: 1.56,
    heap.committed: 209408,
    heap.init: 32768,
    heap.used: 88120,
    heap: 457216,
    nonheap.committed: 73816,
    nonheap.init: 2496,
    nonheap.used: 72680,
    nonheap: 0,
    ...
```

Note that the total memory (`mem`) is registered as `282087 KB` or around `275 MB` which is correct for the
container limited memory resources. However, the `heap` value (`-Xmx`) is `457216 KB` or around `446 MB`.
I.e total VM memory (`2048`) / 4 = `512`, our calculated `-Xmx`. Similarly, the `heap.init` value of
`32768 KB` or `32 MB` which is total VM memory (`2048`) / 64 = `32`, our calculated `-Xms`. Luckily our JVM is not
using more than `256 MB` of heap or we would see it hitting up against the container memory limit.

So the higher the VM system memory, the higher the calculated `-Xms`/`-Xmx` becomes and in turn, the higher you have to 
push the container memory resource with `spring.cloud.deployer.nomad.resourcesMemory`.
Luckily, there is an issue open for allowing `JAVA_OPTS` to be set in the starter app Docker images ([spring-cloud-stream-app-maven-plugin#10](https://github.com/spring-cloud/spring-cloud-stream-app-maven-plugin/issues/10)).
So when that issue is resolved, this shouldn't be such an issue.
 
> See this article for more information: http://matthewkwilliams.com/index.php/2016/03/17/docker-cgroups-memory-constraints-and-java-cautionary-tale/

##### A default compromise

The standalone command (above) and the `scdf-deployer.nomad` job definition suggest a value of `spring.cloud.deployer.nomad.resourcesMemory=256`, which is a compromise between not hogging
to much memory resources from a Nomad perspective but also not to small for the app to run out of heap space.





