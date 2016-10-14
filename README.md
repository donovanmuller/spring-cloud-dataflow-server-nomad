# Spring Cloud Data Flow Server Nomad

This project provides support for deploying Spring Cloud Dataflow's streaming and task/batch data pipelines to [Hashicorp Nomad](). 
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
    --spring.cloud.deployer.nomad.nomadPort=4646 # this is the default so can be omitted   
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
  --dataflow.uri=scdf-server.hashistack.vagrant
...
```







