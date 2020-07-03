variable "DEFAULT_PORT" {
	description = "web server port used across configuration"
	type = number
	default = 8080
}

variable "DEFAULT_SSH_PORT" {
	description = "ssh port entry for ec2 instance"
	type = number
	default = 22
}

output "ec2_public_ip" {
	value = "tbc"
	description = "public IP address of instantiated EC2 instance"
}

output "default_ports" {
	value = [var.DEFAULT_PORT, var.DEFAULT_SSH_PORT]
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
		from_port = var.DEFAULT_PORT
		to_port = var.DEFAULT_PORT
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = var.DEFAULT_SSH_PORT
		to_port = var.DEFAULT_SSH_PORT
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "alb" {
	name = "terraform-base-alb"

	# Allow inbound http req
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	# Allow all outbound req
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
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
			nohup busybox httpd -f -p ${var.DEFAULT_PORT} &
			EOF

	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_autoscaling_group" "ec2-asg" {
	launch_configuration = aws_launch_configuration.ec2-asg-ubuntu-t2micro.name
	vpc_zone_identifier = data.aws_subnet_ids.default_subnets.ids

	target_group_arns = [aws_alb_target_group.asg-target.arn]
	health_check_type = "ELB"

	min_size = 2
	max_size = 10

	tag {
		key = "Name"
		value = "terraform-asg"
		propagate_at_launch = true
	}
}

resource "aws_lb" "ec2-alb" {
	name = "terraform-ec2-alb"
	load_balancer_type = "application"
	subnets = data.aws_subnet_ids.default_subnets.ids
	security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.ec2-alb.arn
	port = 80
	protocol = "HTTP"

	default_action {
		type = "fixed-response"

		fixed_response {
			content_type = "text/plain"
			message_body = "404: page not found"
			status_code = 404
		}
	}
}

resource "aws_alb_target_group" "asg-target" {
	name = "terraform-base-asg"
	port = var.DEFAULT_PORT
	protocol = "HTTP"
	vpc_id = data.aws_vpc.default_vpc.id

	health_check {
		path = "/"
		protocol = "HTTP"
		matcher = "200"
		interval = 15
		timeout = 3
		healthy_threshold = 2
		unhealthy_threshold = 2
	}	
}
