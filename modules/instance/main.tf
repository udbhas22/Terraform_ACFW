resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  private_ip    = var.private_ip

  root_block_device {
    volume_size = var.disk_size
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      network_interface_id = network_interface.value.id
      device_index         = network_interface.key
    }
  }

  tags = merge(
    {
      "Name" = var.name
    },
    var.tags
  )
}


