> ⚠️ **This project is no longer maintained.**

# Spring Cloud Data Flow Server Nomad [![Build Status](https://travis-ci.org/donovanmuller/spring-cloud-dataflow-server-nomad.svg?branch=master)](https://travis-ci.org/donovanmuller/spring-cloud-dataflow-server-nomad)

This project provides support for deploying Spring Cloud Dataflow's streaming and task/batch data pipelines to [Hashicorp Nomad](https://www.nomadproject.io). 
It includes an implementation of Spring Cloud Data Flow’s [Deployer SPI for Nomad](https://github.com/donovanmuller/spring-cloud-deployer-nomad).

Please refer to the [reference documentation](https://donovanmuller.github.io/spring-cloud-dataflow-server-nomad/docs/1.1.0.RELEASE/reference/htmlsingle) on how to get started.

## Building

Clone the repo and type

```bash
$ ./mvnw clean install
```

To build the docker image for the Data Flow Server

```bash
$ ./mvnw package docker:build -pl spring-cloud-dataflow-server-nomad
```
