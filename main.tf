variable "aws_instance_number" {
  default     = 2
  type        = string
  description = "Number of instances to deploy on AWS"
}


provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "server" {
  ami           = "ami-05fa05752fc432eeb" # bionic64
  instance_type = "t2.micro"
  count         = var.aws_instance_number
  tags = {
    "Name" = "server${count.index}"
  }
}

resource "null_resource" "null" {
    count = var.aws_instance_number

  # As a result of re-createing the null_resource the associated provisioners are re-run
  provisioner "local-exec" {
    command = "echo ${element(aws_instance.server.*.tags.Name, count.index)}, ${element(aws_instance.server.*.public_dns, count.index)}, ${element(aws_instance.server.*.public_ip, count.index)} >> server_details.txt"
  }
}
