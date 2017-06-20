package org.springframework.cloud.dataflow.server.nomad;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cloud.deployer.resource.docker.DockerResource;
import org.springframework.cloud.deployer.resource.maven.MavenResource;
import org.springframework.cloud.deployer.resource.support.DelegatingResourceLoader;
import org.springframework.cloud.deployer.spi.app.AppDeployer;
import org.springframework.cloud.deployer.spi.nomad.NomadDeployerProperties;
import org.springframework.cloud.deployer.spi.nomad.ResourceAwareNomadAppDeployer;
import org.springframework.context.ApplicationContext;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, classes = NomadDataFlowServer.class, properties = {
		"spring.cloud.deployer.nomad.deployerHost=localhost", "spring.cloud.deployer.nomad.resources.memory=128Mi" })
public class NomadDataFlowServerTest {

	@Autowired
	private AppDeployer appDeployer;

	@Autowired
	private ApplicationContext context;

	@Test
	public void contextLoads() {
		assertThat(appDeployer).isInstanceOf(ResourceAwareNomadAppDeployer.class);
	}

	@Test
	public void testDeployerProperties() {
		NomadDeployerProperties properties = context.getBean(NomadDeployerProperties.class);
		assertThat(properties.getNomadHost()).isEqualTo("localhost");
		assertThat(properties.getResources().getMemory()).isEqualTo("128Mi");
	}

	@Test
	public void testSupportedResource() {
		DelegatingResourceLoader resourceLoader = context.getBean(DelegatingResourceLoader.class);
		assertThat(resourceLoader
				.getResource("maven://org.springframework.cloud:spring-cloud-dataflow-server-core:1.2.1.RELEASE"))
						.isInstanceOf(MavenResource.class);
		assertThat(resourceLoader.getResource("docker://helloworld:latest")).isInstanceOf(DockerResource.class);
	}
}
