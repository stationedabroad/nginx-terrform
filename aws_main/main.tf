variable "PORT" {
	description = "web server port used across configuration"
	type = number
	default = 8080
}

variable "SSH_PORT" {
	description = "ssh port entry for ec2 instance"
	type = number
	default = 22
}

output "ec2_public_ip" {
	value = "tbc"
	description = "public IP address of instantiated EC2 instance"
}

output "default_ports" {
	value = [var.PORT, var.SSH_PORT]
	description = "default ports exposed"
}

data "aws_vpc" "default_vpc" {
	default = true
}

data "aws_subnet_ids" "default_subnets" {
	vpc_id = data.aws_vpc.default_vpc.id
}

provider "aws" {
	region = "eu-west-2"
}


resource "aws_security_group" "instance" {
	name = "terraform-base-ami-instance"

	ingress {
		from_port = var.PORT
		to_port = var.PORT
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = var.SSH_PORT
		to_port = var.SSH_PORT
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_launch_configuration" "ec2-asg-ubuntu-t2micro" {
	image_id = "ami-00f6a0c18edb19300"
	instance_type = "t2.micro"
	security_groups = [aws_security_group.instance.id]
	key_name = "my-terraform"

	user_data = <<-EOF
			#!/bin/bash
			echo "Server, connected status ..." > index.html
			nohup busybox httpd -f -p ${var.PORT} &
			EOF

	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_autoscaling_group" "ec2-asg" {
	launch_configuration = aws_launch_configuration.ec2-asg-ubuntu-t2micro.name
	vpc_zone_identifier = data.aws_subnet_ids.default_subnets.ids

	min_size = 2
	max_size = 10

	tag {
		key = "Name"
		value = "terraform-asg"
		propagate_at_launch = true
	}
}
