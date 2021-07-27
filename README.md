# tf-null-provider
This repo serves as an explanation and learning exercice for the null provider in Terraform

## Description of the Terraform null_provider

The null provider ([official documentation](https://registry.terraform.io/providers/hashicorp/null/latest/docs))is a rather-unusual provider that has constructs that intentionally do nothing. 

*Important note :*
 > Usage of the null provider can make a Terraform configuration harder to understand. While it can be useful in certain cases, it should be applied with care and other solutions preferred when available.

The null provider consists of :
* The **null_data_source** data source which implements the standard data source lifecycle but does not interact with any external APIs.
Historically, the null_data_source was typically used to construct intermediate values to re-use elsewhere in configuration. The same is now achieved using [locals](https://www.terraform.io/docs/language/values/locals.html). _We'll not cover the __deprecated null_data_source__ in this repo._

* The **null_resource** resource. Instances of null_resource are treated like normal resources, but they don't do anything.
_The main advantage of this resource is the __ability to update or recreate other resources in response of a null_resource change__ via the triggers attribute._
Triggers are a map of values, when changed, that will cause (the null resource to be replaced and) the set of associate provisioners to re-run

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
    
    # As a result of re-creating the null_resource the provisioners are re-run
    provisioner "local-exec" {
      command = "echo ami in one of two instances had changed. Server1 public_dns is: ${aws_instance.server1.public_dns}"
    }
}

```

This terraform file creates :
* 2 ubuntu aws instances
* A null_resource resource which :
  * Gather data of both instances and create a concatenated string of the ami ids via the join function within the triggers map to compare upon on next run
  * Run a simple echo command via the local-exec provisioner 

In this example after any change of ami id, due to the triggers map, the null_resource will be re-created and the provisioner will be re-run.
Here the provisioner only runs an echo command and write the first instance public_dns to stdout but more powerfull actions can be configured.


## Repositery pre-requirements

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

### Run


* terraform init


Sample output

```
terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/null...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v3.51.0...
- Installed hashicorp/aws v3.51.0 (signed by HashiCorp)
- Installing hashicorp/null v3.1.0...
- Installed hashicorp/null v3.1.0 (signed by HashiCorp)

# ...
```


* terraform apply


Sample output

```
terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.server1 will be created
  + resource "aws_instance" "server1" {
  
  # ...
  
  Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
  
  # ...
  
aws_instance.server2: Creation complete after 33s [id=i-01c3152d8c0b2398d]
aws_instance.server1: Still creating... [40s elapsed]
aws_instance.server1: Creation complete after 43s [id=i-05333b856efacbabb]
null_resource.null: Creating...
null_resource.null: Provisioning with 'local-exec'...
null_resource.null (local-exec): Executing: ["/bin/sh" "-c" "echo ami in one of two instances had changed. Server1 public_dns is: ec2-54-93-82-11.eu-central-1.compute.amazonaws.com"]
null_resource.null (local-exec): ami in one of two instances had changed. Server1 public_dns is: ec2-54-93-82-11.eu-central-1.compute.amazonaws.com
null_resource.null: Creation complete after 0s [id=5785853992195975830]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```


* Edit the main.tf file and change tags Name for server1 instance

```
 -         "name" = "server1"
 +         "name" = "web1"
```


* Run terraform apply again and note that the null resource is not re-created and the provisioner not re-run

Sample output :

```
terraform apply
aws_instance.server1: Refreshing state... [id=i-05333b856efacbabb]
aws_instance.server2: Refreshing state... [id=i-01c3152d8c0b2398d]
null_resource.null: Refreshing state... [id=5785853992195975830]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_instance.server1 will be updated in-place
  ~ resource "aws_instance" "server1" {
        id                                   = "i-05333b856efacbabb"
      ~ tags                                 = {
          ~ "name" = "server1" -> "web1"
        }
      ~ tags_all                             = {
          ~ "name" = "server1" -> "web1"
        }
        # (27 unchanged attributes hidden)
        # (5 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_instance.server1: Modifying... [id=i-05333b856efacbabb]
aws_instance.server1: Modifications complete after 8s [id=i-05333b856efacbabb]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```


* Edit the main.tf file again and update the server1 instance ami id (comment line 6 and uncomment line 7)

```
<     #ami           = "ami-05fa05752fc432eeb" # bionic64
<     ami           = "ami-091d856a5f5701931" # nginx64
---
>     ami           = "ami-05fa05752fc432eeb" # bionic64
>     #ami           = "ami-091d856a5f5701931" # nginx64
```


* Run terraform apply again. 

```
terraform apply

# ...

  # null_resource.null must be replaced
-/+ resource "null_resource" "null" {
      ~ id       = "5785853992195975830" -> (known after apply)
      ~ triggers = { # forces replacement
          ~ "instance_ami_ids" = "ami-05fa05752fc432eeb,ami-05fa05752fc432eeb" -> "ami-091d856a5f5701931,ami-05fa05752fc432eeb"
        }
    }

Plan: 2 to add, 0 to change, 2 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
  
 # ...
 
 
aws_instance.server1: Creation complete after 33s [id=i-01099feb130304663]
null_resource.null: Creating...
null_resource.null: Provisioning with 'local-exec'...
null_resource.null (local-exec): Executing: ["/bin/sh" "-c" "echo ami in one of two instances had changed. Server1 public_dns is: ec2-52-29-81-83.eu-central-1.compute.amazonaws.com"]
null_resource.null (local-exec): ami in one of two instances had changed. Server1 public_dns is: ec2-52-29-81-83.eu-central-1.compute.amazonaws.com
null_resource.null: Creation complete after 0s [id=8299250783441160820]

Apply complete! Resources: 2 added, 0 changed, 2 destroyed.
 
``` 


* Note how this time the null resource is re-created and as a result the provisioner is also re-run
