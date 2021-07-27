provider "aws" {
    region     = "eu-central-1"
}

resource "aws_instance" "server1" {
    ami           = "ami-05fa05752fc432eeb" # bionic64
    #ami           = "ami-091d856a5f5701931" # nginx64
    instance_type = "t2.micro"
    tags = {
        "name" = "server1"
    }
}

resource "aws_instance" "server2" {
    ami           = "ami-05fa05752fc432eeb"
    instance_type = "t2.micro"
    tags = {
        "name" = "server2"
    }
}

resource "null_resource" "null" {
    triggers = {
    # Changes to any ami instance requires re-provisioning of this null_resource
        instance_ami_ids = "${join(",", [aws_instance.server1.ami, aws_instance.server2.ami])}"
    }

    # As a result of re-createing the null_resource the provisioners are re-run
    provisioner "local-exec" {
      command = "echo ami in one of two instances had changed. Server1 public_dns is: ${aws_instance.server1.public_dns}"
    }
}
