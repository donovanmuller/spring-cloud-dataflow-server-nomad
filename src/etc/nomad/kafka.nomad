job "kafka" {
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

	group "kafka" {

		restart {
			attempts = 10
			interval = "5m"
			delay = "25s"
			mode = "delay"
		}

		task "kafka" {
			driver = "docker"
			config {
				image = "spotify/kafka:latest"
				port_map {
					zookeeper = 2181
					kafka = 9092
				}
			}

			service {
				name = "zookeeper"
				port = "zookeeper"
				check {
					name = "alive"
					type = "tcp"
					interval = "10s"
					timeout = "2s"
				}
			}

			service {
				name = "kafka"
				port = "kafka"
				check {
					name = "alive"
					type = "tcp"
					interval = "10s"
					timeout = "2s"
				}
			}

			env {
				ADVERTISED_HOST = "${NOMAD_IP_kafka}"
				ADVERTISED_PORT = "${NOMAD_PORT_kafka}"
			}

			resources {
				cpu = 500 # 500 MHz
				memory = 256 # 256MB
				network {
					mbits = 10
					port "zookeeper" {
						static = 2181
					}
					port "kafka" {
						static = 9092
					}
				}
			}
		}
	}
}
