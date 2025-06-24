
# EC2 Instance Module

This module creates an EC2 instance with specified configurations, including associating it with a private IP and attaching an ENI.

## Usage

```terraform
module "ec2_instance" {
  source  = "./modules/instance"

  name          = var.instance_name
  ami           = var.instance_ami
  instance_type = var.instance_type
  subnet_id     = var.instance_subnet_id
  private_ip    = var.instance_private_ip
  tags          = var.instance_tags
}
```

## Variables

- `name`: Name of the EC2 instance.
- `ami`: AMI ID for the EC2 instance.
- `instance_type`: Instance type for the EC2 instance.
- `subnet_id`: Subnet ID where the instance will be launched.
- `private_ip`: Private IP address for the instance.
- `tags`: A map of tags to assign to the instance.

## Outputs

- `instance_id`: The ID of the created EC2 instance.
- `private_ip`: The private IP address of the EC2 instance.


