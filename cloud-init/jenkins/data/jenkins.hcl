job "jenkins-docker" {
  datacenters = ["dc1"]
  type = "service"

  group "jenkins-docker" {
    network {
      mode = "bridge"
      mode = "host"
      name = "jenkins"
#      device = "eth1"
    }

    task "jenkins-docker" {
      driver = "docker"
      config {
        image = "docker:dind"
        network_mode = "bridge"
        port_map {
          jenkins-docker = 2376
        }
        privilege = true
        args = ["--storage-driver", "overlay2"]
        env {
          DOCKER_TLS_CERTDIR = "/certs"
        }
        volume_mount {
          source      = "jenkins-docker-certs"
          destination = "/certs/client"
        }
        volume_mount {
          source      = "jenkins-data"
          destination = "/var/jenkins_home"
        }
      }
    }
  }
}
