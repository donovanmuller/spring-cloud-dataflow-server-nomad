job "scdf" {
	# adjust the region and datacenters accordingly
	region = "vagrant"
	datacenters = ["dc1"]

	constraint {
		attribute = "${attr.kernel.name}"
		value = "linux"
	}

	group "scdf" {

		ephemeral_disk {
			migrate = true
			size    = "500"
			sticky  = true
		}

		task "scdf-server" {
			driver = "docker"
			config {
				image = "donovanmuller/spring-cloud-dataflow-server-nomad:1.1.0.RELEASE"
				# use persistent volume for local Maven repository, saves having to download app artifacts
				# after a new container start
				volumes = [
					"maven:/root/.m2",
				]
				port_map {
					http = 9393
				}
			}

			service {
				name = "scdf-server"
				# adjust this value (scdf-server.hashistack.vagrant) to a resolvable host if applicable
				tags = ["urlprefix-scdf-server.hashistack.vagrant/"]
				port = "http"
				check {
					name = "Data Flow Server HTTP Check"
					type = "http"
					interval = "10s"
					timeout = "2s"
					path = "/management/health"
					protocol = "http"
				}
			}

			env {
				JAVA_OPTS = "-Xmx256m" # see spring-cloud-dataflow-server-nomad/pom.xml:84
				spring.cloud.config.server.bootstrap = "false"
				health.config.enabled = "false"
				spring.datasource.url = "jdbc:mysql://mysql.service.consul:3306/scdf"
				spring.datasource.driverClassName = "org.mariadb.jdbc.Driver"
				spring.datasource.username = "scdf"
				spring.datasource.password = "scdf"
				spring.datasource.testOnBorrow = "true"
				spring.datasource.validationQuery = "SELECT 1"
				spring.redis.host = "redis.service.consul"
				spring.redis.port = "6379"
				maven.resolvePom = "false"
				maven.remote-repositories.spring.url = "http://repo.spring.io/libs-snapshot"
				spring.cloud.deployer.nomad.region = "vagrant" # the Nomad region where apps will be deployed
				spring.cloud.deployer.nomad.nomadHost = "nomad-client.service.consul"
				spring.cloud.deployer.nomad.deployerHost = "${NOMAD_IP_http}" # used for apps defined with Maven resource URIs
				spring.cloud.consul.host = "consul.service.consul" # so we can use Consul for app status checks
				spring.cloud.deployer.nomad.javaOpts = "-Xms64m,-Xmx256m" # default JVM options for all apps deployed via Maven
				spring.cloud.deployer.nomad.resources.memory = "768" # adjust appropriately to your environment
			}

			resources {
				cpu = 500
				memory = 384
				network {
					mbits = 10
					port "http" {
						static = 9393
					}
				}
			}
		}

		task "mysql" {
			driver = "docker"
			config {
				image = "mysql:5.6"
				port_map {
					db = 3306
				}
			}

			service {
				name = "mysql"
				port = "db"
				check {
					name = "Postgres TCP Check"
					type = "tcp"
					interval = "10s"
					timeout = "2s"
				}
			}

			env {
				MYSQL_RANDOM_ROOT_PASSWORD = "true"
				MYSQL_USER = "scdf"
				MYSQL_PASSWORD = "scdf"
				MYSQL_DATABASE = "scdf"
			}

			resources {
				cpu = 500
				memory = 128
				network {
					mbits = 10
					port "db" {
						static = 3306
					}
				}
			}
		}


		task "redis" {
			driver = "docker"
			config {
				image = "redis:3-alpine"
				port_map {
					redis = 6379
				}
			}

			service {
				name = "redis"
				port = "redis"
				check {
					name = "Postgres TCP Check"
					type = "tcp"
					interval = "10s"
					timeout = "2s"
				}
			}

			env {
				MYSQL_RANDOM_ROOT_PASSWORD = "true"
				MYSQL_USER = "scdf"
				MYSQL_PASSWORD = "scdf"
				MYSQL_DATABASE = "scdf"
			}

			resources {
				cpu = 256
				memory = 64
				network {
					mbits = 10
					port "redis" {
						static = 6379
					}
				}
			}
		}

		task "zookeeper" {
			driver = "docker"
			config {
				image = "digitalwonderland/zookeeper:latest"
				port_map {
					zookeeper = 2181
					follower = 2888
					leader = 3888
				}
			}

			service {
				name = "kafka-zk"
				port = "zookeeper"
				check {
					name = "alive"
					type = "tcp"
					interval = "10s"
					timeout = "2s"
				}
			}

			env {
				ZOOKEEPER_ID = "1"
				ZOOKEEPER_SERVER_1 = "kafka-zk.service.consul"
			}

			resources {
				cpu = 500
				memory = 128
				network {
					mbits = 10
					port "zookeeper" {
						static = 2181
					}
					port "follower" {
						static = 2888
					}
					port "leader" {
						static = 3888
					}
				}
			}
		}

		task "kafka" {
			driver = "docker"
			config {
				image = "wurstmeister/kafka:0.10.1.0"
				port_map {
					kafka = 9092
				}
			}

			service {
				name = "kafka-broker"
				port = "kafka"
				check {
					name = "alive"
					type = "tcp"
					interval = "10s"
					timeout = "2s"
				}
			}

			env {
				ENABLE_AUTO_EXTEND = "true"
				KAFKA_RESERVED_BROKER_MAX_ID = "999999999"
				KAFKA_AUTO_CREATE_TOPICS_ENABLE = "false"
				KAFKA_PORT = "9092"
				KAFKA_ADVERTISED_PORT = "9092"
				KAFKA_ADVERTISED_HOST_NAME = "${NOMAD_IP_kafka}"
				KAFKA_ZOOKEEPER_CONNECT = "kafka-zk.service.consul:2181"
			}

			resources {
				cpu = 500
				memory = 512
				network {
					mbits = 10
					port "kafka" {
						static = 9092
					}
				}
			}
		}
	}
}
