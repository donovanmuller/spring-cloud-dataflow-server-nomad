job "nexus" {
	# adjust the region and datacenters accordingly
	region = "vagrant"
	datacenters = ["dc1"]

	constraint {
		attribute = "${attr.kernel.name}"
		value = "linux"
	}

	group "nexus" {

		task "nexus" {
			driver = "docker"
			config {
				image = "sonatype/nexus:2.14.4"
				port_map {
					http = 8081
				}
			}

			service {
				name = "nexus"
				# adjust this value (nexus.hashistack.vagrant) to a resolvable host if applicable
				tags = ["urlprefix-nexus.hashistack.vagrant/"]
				port = "http"
				check {
					name = "Nexus HTTP Check"
					type = "http"
					interval = "10s"
					timeout = "2s"
					path = "/service/local/status"
					protocol = "http"
				}
			}

			env {
				CONTEXT_PATH = "/"
				MIN_HEAP = "256m"
				MAX_HEAP = "384m"
			}

			resources {
				cpu = 500
				memory = 512
				network {
					mbits = 10
					port "http" {
						static = 8081
					}
				}
			}
		}
	}
}
