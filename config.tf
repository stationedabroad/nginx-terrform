provider = "docker" {
	host = "tcp://docker:2345/"
}

resource "docker_image" "nginx" {
  name = "nginx:1.11-alpine"
}

resource "docker_container" "nginx-server" {
  name = "nginx-server"
  image = "${docker_image.nginx.latest}"
  ports {
    internal = 80
  }
  volumes {
    container_path  = "/usr/share/nginx/tmp"
    host_path = "/home/stationedabroad/Documents/terraform/nginx/server-2"
    read_only = true
  }
}
