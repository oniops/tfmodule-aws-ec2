# AWS EC2 Instance Terraform module

Terraform module which creates an EC2 instance on AWS.

This module supports the following resources:

- `aws_instance`
- `aws_network_interface_attachment` (for additional/secondary ENIs)
- `aws_eip_association` (for EIP attachment)

## Usage

### Single EC2 Instance

```hcl
module "ec2" {
  source        = "git::https://github.com/oniops/tfmodule-aws-ec2.git?ref=v1.2.0"
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
  source = "git::https://github.com/oniops/tfmodule-aws-ec2.git?ref=v1.2.0"

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

### EC2 Instance with Primary and Additional ENIs

```hcl
resource "aws_network_interface" "primary" {
  subnet_id       = "subnet-eddcdzz4"
  security_groups = ["sg-12345678"]
}

resource "aws_network_interface" "secondary" {
  subnet_id       = "subnet-eddcdzz4"
  security_groups = ["sg-12345678"]
}

module "ec2" {
  source        = "git::https://github.com/oniops/tfmodule-aws-ec2.git?ref=v1.2.0"
  name          = "multi-eni-instance"
  ami           = "ami-ebd02392"
  instance_type = "t3.medium"
  key_name      = "user1"

  primary_network_interface = aws_network_interface.primary.id

  additional_network_interfaces = {
    one = {
      network_interface_id = aws_network_interface.secondary.id
      device_index         = 1
    }
  }

  tags = {
    Environment = "Development"
  }
}
```

### EC2 Instance with EIP

```hcl
resource "aws_eip" "this" {
  domain = "vpc"
}

module "ec2" {
  source        = "git::https://github.com/oniops/tfmodule-aws-ec2.git?ref=v1.2.0"
  name          = "eip-instance"
  ami           = "ami-ebd02392"
  instance_type = "t3.micro"
  key_name      = "user1"
  subnet_id     = "subnet-eddcdzz4"
  vpc_security_group_ids = ["sg-12345678"]

  eip_allocation_id = aws_eip.this.id
}
```

### Ignoring user_data changes

By default, changing `user_data_base64` on an existing instance makes Terraform stop the instance, update the user data, and start it again (or replace it when `user_data_replace_on_change = true`). For production instances whose user data only matters at first boot, set `ignore_user_data_changes = true` so later edits never touch the running instance.

```hcl
module "ec2" {
  source                   = "git::https://github.com/oniops/tfmodule-aws-ec2.git?ref=<version>"
  name                     = "prd-instance"
  ami                      = "ami-ebd02392"
  instance_type            = "t3.micro"
  subnet_id                = "subnet-eddcdzz4"
  user_data_base64         = base64encode(file("${path.module}/user-data.sh"))
  ignore_user_data_changes = true
}
```

Because `lifecycle.ignore_changes` cannot be driven by a variable, the instance is managed under `aws_instance.ignore_user_data` when this flag is on.

- **New instance**: just set the flag.
- **Existing instance (flag `false` → `true`)**: add a `moved` block in the calling module **in the same change**, otherwise Terraform plans a **destroy/create** of the instance.

  ```hcl
  moved {
    from = module.ec2.aws_instance.this[0]
    to   = module.ec2.aws_instance.ignore_user_data[0]
  }
  ```

  For `for_each` modules use `module.ec2["<key>"].aws_instance...`. Always confirm that `terraform plan` shows `has moved to` and **no** `must be replaced` / `destroy` before applying. Keeping the `moved` block after apply is harmless. Reverting (`true` → `false`) requires replacing it with the reverse `moved` block; leaving the original block in place makes `plan` fail with `Moved object still exists` (nothing is changed).

## Requirements

| Name      | Version           |
|-----------|-------------------|
| terraform | >= 1.5.7          |
| aws       | >= 6.10.0, < 7.0.0 |

## Providers

| Name | Version            |
|------|--------------------|
| aws  | >= 6.10.0, < 7.0.0 |

## Resources

| Name | Type |
|------|------|
| `aws_instance.this` | resource |
| `aws_instance.ignore_user_data` | resource (used instead of `aws_instance.this` when `ignore_user_data_changes = true`) |
| `aws_network_interface_attachment.this` | resource |
| `aws_eip_association.this` | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create | Controls whether resources should be created | `bool` | `true` | no |
| name | Name to be used on EC2 instance created | `string` | `""` | no |
| ami | ID of AMI to use for the instance | `string` | `""` | no |
| instance_type | The type of instance to start | `string` | `"t3.micro"` | no |
| cpu_options | Defines CPU options to apply to the instance at launch time. Supported keys: `core_count`, `threads_per_core`, `amd_sev_snp` (e.g. `{ core_count = 2, threads_per_core = 1 }`) | `any` | `{}` | no |
| cpu_credits | The credit option for CPU usage (`unlimited` or `standard`). Applied only to `t2.*`, `t3.*`, `t3a.*` instance types; ignored otherwise (including `t4g.*`) | `string` | `null` | no |
| hibernation | If true, the launched EC2 instance will support hibernation | `bool` | `null` | no |
| associate_public_ip_address | Whether to associate a public IP address with an instance in a VPC | `bool` | `null` | no |
| availability_zone | AZ to start the instance in | `string` | `null` | no |
| disable_api_termination | If true, enables EC2 Instance Termination Protection | `bool` | `null` | no |
| disable_api_stop | If true, enables EC2 Instance Stop Protection | `bool` | `null` | no |
| ebs_block_device | Additional EBS block devices to attach to the instance. `device_name` is required; supported keys: `delete_on_termination`, `encrypted`, `iops`, `kms_key_id`, `snapshot_id`, `volume_size`, `volume_type`, `throughput` | `list(map(string))` | `[]` | no |
| ebs_optimized | If true, the launched EC2 instance will be EBS-optimized | `bool` | `null` | no |
| enclave_options_enabled | Whether Nitro Enclaves will be enabled on the instance. Defaults to `false` | `bool` | `null` | no |
| ephemeral_block_device | Customize Ephemeral (also known as Instance Store) volumes on the instance | `list(map(string))` | `[]` | no |
| get_password_data | If true, wait for password data to become available and retrieve it | `bool` | `null` | no |
| host_id | ID of a dedicated host that the instance will be assigned to | `string` | `null` | no |
| iam_instance_profile | IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile | `string` | `null` | no |
| instance_initiated_shutdown_behavior | Shutdown behavior for the instance. Amazon defaults this to `stop` for EBS-backed instances and `terminate` for instance-store instances | `string` | `null` | no |
| ipv6_address_count | Number of IPv6 addresses to associate with the primary network interface | `number` | `null` | no |
| ipv6_addresses | Specify one or more IPv6 addresses from the range of the subnet to associate with the primary network interface | `list(string)` | `null` | no |
| key_name | Key name of the Key Pair to use for the instance | `string` | `null` | no |
| launch_template | Specifies a Launch Template to configure the instance. Supported keys: `id`, `name`, `version`. Parameters set on this module override the template | `map(string)` | `null` | no |
| metadata_options | Customize the metadata options of the instance. Supported keys: `http_endpoint` (default `enabled`), `http_tokens` (default `optional`), `http_put_response_hop_limit` (default `1`), `instance_metadata_tags`. The block is always rendered, so omitted keys fall back to these defaults; set `http_tokens = "required"` to enforce IMDSv2 | `map(string)` | `{}` | no |
| monitoring | If true, the launched EC2 instance will have detailed monitoring enabled | `bool` | `false` | no |
| placement_group | The Placement Group to start the instance in | `string` | `null` | no |
| private_ip | Private IP address to associate with the instance in a VPC | `string` | `null` | no |
| root_block_device | Customize details about the root block device of the instance. Supported keys: `delete_on_termination`, `encrypted`, `iops`, `kms_key_id`, `volume_size`, `volume_type`, `throughput`, `tags` | `list(any)` | `[]` | no |
| secondary_private_ips | A list of secondary private IPv4 addresses to assign to the instance's primary network interface (eth0) in a VPC | `list(string)` | `null` | no |
| source_dest_check | Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs. Applied at creation only (changes after launch are ignored; use `-replace` or the AWS CLI). Cannot be combined with `primary_network_interface`; set it on the ENI instead | `bool` | `null` | no |
| subnet_id | The VPC Subnet ID to launch in | `string` | `null` | no |
| primary_network_interface | ID of the primary network interface to attach at instance boot time. AWS provider 6.10.0+ replaces the deprecated `network_interface` block with `primary_network_interface`. When set, do not also set `subnet_id`, `vpc_security_group_ids`, `associate_public_ip_address`, `private_ip`, `secondary_private_ips`, `ipv6_*` or `source_dest_check`; configure them on the ENI. Must be a non-empty ENI ID or `null` | `string` | `null` | no |
| additional_network_interfaces | Additional network interfaces to attach via `aws_network_interface_attachment`. Map keys are used as stable resource identifiers for `for_each`. Each value supports `network_interface_id`, `device_index`, and optional `network_card_index`. Each `(device_index, network_card_index)` pair must be unique | `map(object({ network_interface_id = string, device_index = number, network_card_index = optional(number) }))` | `{}` | no |
| tags | A mapping of tags to assign to the instance. The `Name` tag is always set from `name` and overrides any `Name` given here | `map(string)` | `{}` | no |
| instance_tags | A mapping of tags to assign to the EC2 instance (merged with `tags`) | `map(string)` | `{}` | no |
| tenancy | The tenancy of the instance. Available values: `default`, `dedicated`, `host` | `string` | `null` | no |
| user_data_base64 | Base64-encoded user data. This is the only user data input of the module (there is no plain `user_data` variable); wrap plain text with `base64encode()` | `string` | `null` | no |
| user_data_replace_on_change | When true, changes to `user_data_base64` trigger a destroy and recreate | `bool` | `false` | no |
| ignore_user_data_changes | When true, changes to `user_data_base64` after launch are ignored. Cannot be combined with `user_data_replace_on_change = true` (plan fails with a precondition error). See [Ignoring user_data changes](#ignoring-user_data-changes) | `bool` | `false` | no |
| volume_tags | A mapping of tags to assign to the devices created by the instance at launch time. Merged after `{ Name = name }`. Applied only when `enable_volume_tags = true` | `map(string)` | `{}` | no |
| enable_volume_tags | Whether to enable volume tags (if enabled it conflicts with `root_block_device` tags) | `bool` | `true` | no |
| vpc_security_group_ids | A list of security group IDs to associate with | `list(string)` | `null` | no |
| timeouts | Define maximum timeout for creating, updating, and deleting EC2 instance resources | `map(string)` | `{}` | no |
| eip_allocation_id | Allocation ID of an existing EIP to associate with the instance via `aws_eip_association` | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the instance |
| arn | The ARN of the instance |
| capacity_reservation_specification | Capacity reservation specification of the instance |
| instance_state | The state of the instance. One of: `pending`, `running`, `shutting-down`, `terminated`, `stopping`, `stopped` |
| outpost_arn | The ARN of the Outpost the instance is assigned to |
| password_data | Base-64 encoded encrypted password data for the instance (only exported if `get_password_data` is true) |
| primary_network_interface_id | The ID of the instance's primary network interface |
| private_dns | The private DNS name assigned to the instance |
| public_dns | The public DNS name assigned to the instance (only if DNS hostnames are enabled for the VPC) |
| public_ip | The public IP address assigned to the instance, if applicable. Note: if using `aws_eip`, refer to the EIP's address directly |
| private_ip | The private IP address assigned to the instance |
| ipv6_addresses | The IPv6 address assigned to the instance, if applicable |
| tags_all | A map of tags assigned to the resource, including those inherited from the provider `default_tags` configuration block |
| network_interface_attachment_ids | Map of attachment IDs keyed by the `additional_network_interfaces` map key |

When `create = false`, string outputs return `""`, `ipv6_addresses` returns `[]`, and `tags_all` / `network_interface_attachment_ids` return `{}`.

## Notes

- The module uses `lifecycle.ignore_changes = [ami, source_dest_check]` on `aws_instance.this`, so AMI updates and `source_dest_check` changes after launch do not cause drift. `aws_instance.ignore_user_data` additionally ignores `user_data` and `user_data_base64`.
- With the default `ignore_user_data_changes = false`, the instance stays at `aws_instance.this[0]`, so upgrading the module causes no plan changes for existing instances.
- The deprecated `aws_instance.network_interface` inline block has been replaced with `primary_network_interface` (for the primary ENI) and `aws_network_interface_attachment` (for additional ENIs). This requires AWS provider version `>= 6.10.0`.
- `cpu_credits` only takes effect for T-family instance types (`t2.*`, `t3.*`, `t3a.*`).
- When `eip_allocation_id` is provided, the module creates an `aws_eip_association` to bind the existing EIP to the instance. The EIP itself should be created outside this module.
