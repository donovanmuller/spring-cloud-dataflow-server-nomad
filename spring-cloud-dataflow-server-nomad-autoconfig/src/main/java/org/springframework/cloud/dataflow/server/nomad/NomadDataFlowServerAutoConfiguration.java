package org.springframework.cloud.dataflow.server.nomad;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.AutoConfigureOrder;
import org.springframework.cloud.deployer.resource.docker.DockerResourceLoader;
import org.springframework.cloud.deployer.resource.maven.MavenProperties;
import org.springframework.cloud.deployer.resource.maven.MavenResourceLoader;
import org.springframework.cloud.deployer.resource.support.DelegatingResourceLoader;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.core.Ordered;
import org.springframework.core.io.ResourceLoader;

/**
 * AutoConfiguration for the {@link NomadDataFlowServer}
 *
 * @author Donovan Muller
 */
@Configuration
@AutoConfigureOrder(Ordered.HIGHEST_PRECEDENCE)
public class NomadDataFlowServerAutoConfiguration {

	@Bean
	public DelegatingResourceLoader delegatingResourceLoader(MavenProperties mavenProperties) {
		MavenResourceLoader mavenLoader = new MavenResourceLoader(mavenProperties);
		DockerResourceLoader dockerLoader = new DockerResourceLoader();
		Map<String, ResourceLoader> loaders = new HashMap<>();
		loaders.put("maven", mavenLoader);
		loaders.put("docker", dockerLoader);
		return new DelegatingResourceLoader(loaders);
	}
}
