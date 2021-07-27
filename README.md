# tf-null-provider
This repo serves as an explanation and learning exercice for the null provider in Terraform

## Description

The null provider ([official documentation](https://registry.terraform.io/providers/hashicorp/null/latest/docs))is a rather-unusual provider that has constructs that intentionally do nothing. 

*Important note :*
 > Usage of the null provider can make a Terraform configuration harder to understand. While it can be useful in certain cases, it should be applied with care and other solutions preferred when available.

The null provider is divided in 2 parts :
* The **null_data_source** data source which implements the standard data source lifecycle but does not interact with any external APIs.
Historically, the null_data_source was typically used to construct intermediate values to re-use elsewhere in configuration. The same is now achieved using [locals](https://www.terraform.io/docs/language/values/locals.html). _We'll not cover the deprecated null_data_source in this repo._

* The **null_resource** resource. Instances of null_resource are treated like normal resources, but they don't do anything.
_The main advantage of this resource is the __ability to update or recreate other resources in response of null_resource change___

Taking the below main.tf file example :

```
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

    provisioner "local-exec" {
      command = "echo server1 public_dns: ${aws_instance.server1.public_dns}"
    }
}

```

We have :
* 2 identic bionic aws instances
* A null_resource resource which :
  * Gather data of both instances and create a concatenated string of the ami ids via the join function within the triggers map to compare upon on next run
  * Run a simple echo command via the local-exec provisioner 

In this case any change of ami id, due to the triggers map, null_resource will be re-created and the provisioner will be re-run.
Here the provisioners only runs an echo command and write the first instance public_dns to stdout but more powerfull actions can be configured.


## Pre-requirements

* [AWS Account](https://aws.amazon.com/) and basical knowledge of [Terraform with AWS](https://learn.hashicorp.com/collections/terraform/aws-get-started)
* [Git installed](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

## How to use this repo

- Clone
- Run

---

### Clone the repo

```
git clone https://github.com/viv-garot/tf-null-provider
```

### Change directory

```
cd tf-null-provider
```

### [.......]
