job "scdf-deployer" {
	region = "vagrant"
	datacenters = ["dc1"]

	constraint {
		attribute = "${attr.kernel.name}"
		value = "linux"
	}

	update {
		stagger = "10s"
		max_parallel = 1
	}

	group "scdf-deployer" {
		restart {
			attempts = 10
			interval = "5m"
			delay = "25s"
			mode = "delay"
		}

		task "scdf-deployer" {
			driver = "docker"
			config {
				image = "donovanmuller/spring-cloud-dataflow-server-nomad:1.0.0.BUILD-SNAPSHOT"
				port_map {
					http = 9393
				}
			}

			service {
				name = "scdf-deployer-server-nomad"
				tags = ["urlprefix-scdf-server.hashistack.vagrant/"]
				port = "http"
				check {
					name = "SCDF Server HTTP Check"
					type = "http"
					interval = "10s"
					timeout = "2s"
					path = "/" # should be /management/health but waiting for release containing https://github.com/spring-cloud/spring-cloud-dataflow/issues/857
					protocol = "http"
				}
			}

			env {
				JAVA_OPTS = "-Xmx128m" # see spring-cloud-dataflow-server-nomad/pom.xml:84
				spring.cloud.deployer.nomad.nomadHost = "nomad-client"
				spring.cloud.deployer.nomad.resourcesMemory = "256"
			}

			resources {
				cpu = 500 # 500 MHz
				memory = 256 # 256MB
				network {
					mbits = 10
					port "http" {
						static = 9393
					}
				}
			}
		}
	}
}
