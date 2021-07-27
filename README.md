# tf-null-provider-count
This repo serves as a learning exercice for the null provider in Terraform. 
To ilustrate its usage we'll leverage the count meta-argument and the count.index object attribute (If unfamiliar with count meta-argument, check the official doc [here](https://www.terraform.io/docs/language/meta-arguments/count.html))

## Description of the Terraform null_provider

Check this [other repo](https://github.com/viv-garot/tf-null-provider) for a short explanation and an introductory example of the null_provider


## Repositery pre-requirements

* [AWS Account](https://aws.amazon.com/) and basical knowledge of [Terraform with AWS](https://learn.hashicorp.com/collections/terraform/aws-get-started)
* [Git installed](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

## How to use this repo

- Clone
- Run

---

### Clone the repo

```
git clone https://github.com/viv-garot/tf-null-provider-count
```

### Change directory

```
cd tf-null-provider-count
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
 -         "Name" = "server1"
 +         "Name" = "web1"
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
          ~ "Name" = "server1" -> "web1"
        }
      ~ tags_all                             = {
          ~ "Name" = "server1" -> "web1"
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
