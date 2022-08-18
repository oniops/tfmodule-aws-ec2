# AWS EC2 Instance Terraform module

Terraform module which creates an EC2 instance on AWS.

## Usage

### Single EC2 Instance

```hcl
module "ec2_instance" {
  source  = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-ec2.git"

  name = "single-instance"

  ami                    = "ami-ebd02392"
  instance_type          = "t2.micro"
  key_name               = "user1"
  monitoring             = true
  vpc_security_group_ids = ["sg-12345678"]
  subnet_id              = "subnet-eddcdzz4"

  tags = {
    Environment = "Development"
    Team        = "DevOps"
  }
}
```

### Multiple EC2 Instance

```hcl
module "ec2_instance" {
  source  = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-ec2.git"

  for_each = toset(["one", "two", "three"])

  name = "instance-${each.key}"

  ami                    = "ami-ebd02392"
  instance_type          = "t2.micro"
  key_name               = "user1"
  monitoring             = true
  vpc_security_group_ids = ["sg-12345678"]
  subnet_id              = "subnet-eddcdzz4"

  tags = {
    Environment = "Development"
    Team          = "DevOps"
  }
}
```

 
## Inputs


## Outputs
