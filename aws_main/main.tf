provider "aws" {
	region = "eu-west-2"
}

resource "aws_instance" "ec2-ubuntu-t2micro" {
	ami = "ami-00f6a0c18edb19300"
	instance_type = "t2.micro"

	tags = {
		Name = "terraform-main-example"
	}
}
