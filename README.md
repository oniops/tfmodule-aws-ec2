# AWS EC2 Instance Terraform module

Terraform module which creates an EC2 instance on AWS.

## Usage

### Single EC2 Instance

```hcl
module "ec2" {
  source        = "git::https://github.com/oniops/tfmodule-aws-ec2.git?ref=v1.0.1"
  create        = true
  name          = "single-instance"
  ami           = "ami-ebd02392"
  instance_type = "t2.micro"
  key_name      = "user1"
  monitoring    = true
  vpc_security_group_ids = ["sg-12345678"]
  subnet_id     = "subnet-eddcdzz4"

  tags = {
    Environment = "Development"
    Team        = "DevOps"
  }
}
```

### Multiple EC2 Instance

```hcl
module "ec2" {
  source = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-ec2.git?ref=v1.0.0"

  for_each = toset(["one", "two", "three"])
  name          = "instance-${each.key}"
  ami           = "ami-ebd02392"
  instance_type = "t2.micro"
  key_name      = "user1"
  monitoring    = true
  vpc_security_group_ids = ["sg-12345678"]
  subnet_id     = "subnet-eddcdzz4"

  tags = {
    Environment = "Development"
    Team        = "DevOps"
  }
}
```

 
## Inputs


## Outputs
