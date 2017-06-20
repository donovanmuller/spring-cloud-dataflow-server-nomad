package org.springframework.cloud.dataflow.server.nomad;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.dataflow.server.EnableDataFlowServer;

/**
 * @author Donovan Muller
 */
@SpringBootApplication
@EnableDataFlowServer
public class NomadDataFlowServer {

    public static void main(String[] args) {
        SpringApplication.run(NomadDataFlowServer.class, args);
    }
}
