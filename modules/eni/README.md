
# Elastic Network Interface (ENI) Module

This module creates an Elastic Network Interface (ENI) and associates it with a subnet and a private IP address.

## Usage

```terraform
module "eni" {
  source  = "./modules/eni"

  name        = var.eni_name
  subnet_id   = var.eni_subnet_id
  private_ips = var.eni_private_ips
  tags        = var.eni_tags
}
```

## Variables

- `name`: Name of the ENI.
- `subnet_id`: The ID of the subnet in which to create the ENI.
- `private_ips`: A list of private IP addresses to assign to the ENI.
- `tags`: A map of tags to assign to the ENI.

## Outputs

- `eni_id`: The ID of the created ENI.
- `private_ips`: The private IP addresses assigned to the ENI.


