variable "PORT" {
	description = "web server port used across configuration"
	type = number
}

provider "aws" {
	region = "eu-west-2"
}


resource "aws_security_group" "instance" {
	name = "terraform-base-ami-instance"

	ingress {
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_instance" "ec2-ubuntu-t2micro" {
	ami = "ami-00f6a0c18edb19300"
	instance_type = "t2.micro"
	vpc_security_group_ids = [aws_security_group.instance.id]
	key_name = "my-terraform"

	user_data = <<-EOF
			#!/bin/bash
			echo "Server, connected status ..." > index.html
			nohup busybox httpd -f -p 8080 &
			EOF

	tags = {
		Name = "terraform-main-example"
	}
}
