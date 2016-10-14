package org.springframework.cloud.dataflow.server.nomad;

import org.springframework.boot.SpringApplication;
import org.springframework.cloud.dataflow.server.EnableDataFlowServer;

/**
 * @author Donovan Muller
 */
@EnableDataFlowServer
public class NomadDataFlowServer {

    public static void main(String[] args) {
        SpringApplication.run(NomadDataFlowServer.class, args);
    }
}
