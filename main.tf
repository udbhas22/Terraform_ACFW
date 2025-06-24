provider "aws" {
  region = "us-east-1" # You can change this to your desired region
}

resource "aws_vpc" "main" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ACFW-2.0-VPC"

  }
}

resource "aws_subnet" "management" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "172.16.10.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "ACFW-2.0-MANAGEMENT-SUBNET"
    "Test Name" = "ACFW-2.0"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "ACFW-2.0-IGW"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "ACFW-2.0-PUBLIC-ROUTE-TABLE"
    "Test Name" = "ACFW-2.0"
  }
}

resource "aws_route_table_association" "management_subnet_association" {
  subnet_id      = aws_subnet.management.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "management_sg" {
  name        = "ACFW-2.0-MANAGEMENT-SG"
  description = "Allow SSH and RDP access to management subnet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ACFW-2.0-MANAGEMENT-SG"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
  }
}

# Jump Server
resource "aws_network_interface" "jump_server_eni" {
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.5"]

  tags = {
    Name        = "ACFW-2.0-JUMP-SERVER-ENI"
    "Test Name" = "ACFW-2.0"
  }
}

resource "aws_instance" "jump_server" {
  ami                         = var.ami_ubuntu
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.management.id
  private_ip                  = "172.16.10.5"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.management_sg.id]

  root_block_device {
    volume_size = 15
  }

  network_interface {
    network_interface_id = aws_network_interface.jump_server_eni.id
    device_index         = 0
  }

  tags = {
    Name        = "ACFW-2.0-JUMP-SERVER-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
  }
}

resource "aws_eip" "jump_server_eip" {
  instance = aws_instance.jump_server.id

  tags = {
    Name        = "ACFW-2.0-JUMP-SERVER-ELASTIC-IP"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
  }
}




# AXGATE Resources

resource "aws_subnet" "axe_private_subnet_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.101.0/24"

  tags = {
    Name        = "ACFW-2.0-AXE-PRIVATE-SUBNET-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

resource "aws_subnet" "axe_private_subnet_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.201.0/24"

  tags = {
    Name        = "ACFW-2.0-AXE-PRIVATE-SUBNET-02"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_window_subnet_01_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-AXE-WINDOW-SUBNET-01-VM-01"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.axe_private_subnet_01.id
  private_ip    = "172.16.101.11"
  disk_size     = 100
  network_interfaces = {
    0 = module.axe_window_subnet_01_vm_01_eni_private.eni_id
    1 = module.axe_window_subnet_01_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_window_subnet_01_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-AXE-WINDOW-SUBNET-01-VM-01-ENI"
  subnet_id   = aws_subnet.axe_private_subnet_01.id
  private_ips = ["172.16.101.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_window_subnet_01_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-AXE-WINDOW-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}




module "axe_window_subnet_01_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-AXE-WINDOW-SUBNET-01-VM-02"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.axe_private_subnet_01.id
  private_ip    = "172.16.101.12"
  disk_size     = 100
  network_interfaces = {
    0 = module.axe_window_subnet_01_vm_02_eni_private.eni_id
    1 = module.axe_window_subnet_01_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_window_subnet_01_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-AXE-WINDOW-SUBNET-01-VM-02-ENI"
  subnet_id   = aws_subnet.axe_private_subnet_01.id
  private_ips = ["172.16.101.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_window_subnet_01_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-AXE-WINDOW-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_ubuntu_subnet_01_vm_03" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-AXE-UBUNTU-SUBNET-01-VM-03"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.axe_private_subnet_01.id
  private_ip    = "172.16.101.13"
  disk_size     = 75
  network_interfaces = {
    0 = module.axe_ubuntu_subnet_01_vm_03_eni_private.eni_id
    1 = module.axe_ubuntu_subnet_01_vm_03_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_ubuntu_subnet_01_vm_03_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-AXE-UBUNTU-SUBNET-01-VM-03-ENI"
  subnet_id   = aws_subnet.axe_private_subnet_01.id
  private_ips = ["172.16.101.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_ubuntu_subnet_01_vm_03_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-AXE-UBUNTU-MANAGEMNET-SUBNET-VM-03-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_ubuntu_subnet_02_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-AXE-UBUNTU-SUBNET-02-VM-01"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.axe_private_subnet_02.id
  private_ip    = "172.16.201.11"
  disk_size     = 75
  network_interfaces = {
    0 = module.axe_ubuntu_subnet_02_vm_01_eni_private.eni_id
    1 = module.axe_ubuntu_subnet_02_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_ubuntu_subnet_02_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-AXE-UBUNTU-SUBNET-02-VM-01-ENI"
  subnet_id   = aws_subnet.axe_private_subnet_02.id
  private_ips = ["172.16.201.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_ubuntu_subnet_02_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-AXE-UBUNTU-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.14"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_ubuntu_subnet_02_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-AXE-UBUNTU-SUBNET-02-VM-02"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.axe_private_subnet_02.id
  private_ip    = "172.16.201.12"
  disk_size     = 75
  network_interfaces = {
    0 = module.axe_ubuntu_subnet_02_vm_02_eni_private.eni_id
    1 = module.axe_ubuntu_subnet_02_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_ubuntu_subnet_02_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-AXE-UBUNTU-SUBNET-02-VM-02-ENI"
  subnet_id   = aws_subnet.axe_private_subnet_02.id
  private_ips = ["172.16.201.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}

module "axe_ubuntu_subnet_02_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-AXE-UBUNTU-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.15"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "AXE"
  }
}




# CHECKPOINT Resources

resource "aws_subnet" "chkp_private_subnet_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.102.0/24"

  tags = {
    Name        = "ACFW-2.0-CHKP-PRIVATE-SUBNET-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

resource "aws_subnet" "chkp_private_subnet_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.202.0/24"

  tags = {
    Name        = "ACFW-2.0-CHKP-PRIVATE-SUBNET-02"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_window_subnet_01_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-CHKP-WINDOW-SUBNET-01-VM-01"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.chkp_private_subnet_01.id
  private_ip    = "172.16.102.11"
  disk_size     = 100
  network_interfaces = {
    0 = module.chkp_window_subnet_01_vm_01_eni_private.eni_id
    1 = module.chkp_window_subnet_01_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_window_subnet_01_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CHKP-WINDOW-SUBNET-01-VM-01-ENI"
  subnet_id   = aws_subnet.chkp_private_subnet_01.id
  private_ips = ["172.16.102.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_window_subnet_01_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CHKP-WINDOW-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.21"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_window_subnet_01_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-CHKP-WINDOW-SUBNET-01-VM-02"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.chkp_private_subnet_01.id
  private_ip    = "172.16.102.12"
  disk_size     = 100
  network_interfaces = {
    0 = module.chkp_window_subnet_01_vm_02_eni_private.eni_id
    1 = module.chkp_window_subnet_01_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_window_subnet_01_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CHKP-WINDOW-SUBNET-01-VM-02-ENI"
  subnet_id   = aws_subnet.chkp_private_subnet_01.id
  private_ips = ["172.16.102.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_window_subnet_01_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CHKP-WINDOW-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.22"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_ubuntu_subnet_01_vm_03" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-CHKP-UBUNTU-SUBNET-01-VM-03"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.chkp_private_subnet_01.id
  private_ip    = "172.16.102.13"
  disk_size     = 75
  network_interfaces = {
    0 = module.chkp_ubuntu_subnet_01_vm_03_eni_private.eni_id
    1 = module.chkp_ubuntu_subnet_01_vm_03_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_ubuntu_subnet_01_vm_03_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CHKP-UBUNTU-SUBNET-01-VM-03-ENI"
  subnet_id   = aws_subnet.chkp_private_subnet_01.id
  private_ips = ["172.16.102.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_ubuntu_subnet_01_vm_03_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CHKP-UBUNTU-MANAGEMNET-SUBNET-VM-03-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.23"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_ubuntu_subnet_02_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-CHKP-UBUNTU-SUBNET-02-VM-01"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.chkp_private_subnet_02.id
  private_ip    = "172.16.202.11"
  disk_size     = 75
  network_interfaces = {
    0 = module.chkp_ubuntu_subnet_02_vm_01_eni_private.eni_id
    1 = module.chkp_ubuntu_subnet_02_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_ubuntu_subnet_02_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CHKP-UBUNTU-SUBNET-02-VM-01-ENI"
  subnet_id   = aws_subnet.chkp_private_subnet_02.id
  private_ips = ["172.16.202.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_ubuntu_subnet_02_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CHKP-UBUNTU-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.24"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_ubuntu_subnet_02_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-CHKP-UBUNTU-SUBNET-02-VM-02"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.chkp_private_subnet_02.id
  private_ip    = "172.16.202.12"
  disk_size     = 75
  network_interfaces = {
    0 = module.chkp_ubuntu_subnet_02_vm_02_eni_private.eni_id
    1 = module.chkp_ubuntu_subnet_02_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_ubuntu_subnet_02_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CHKP-UBUNTU-SUBNET-02-VM-02-ENI"
  subnet_id   = aws_subnet.chkp_private_subnet_02.id
  private_ips = ["172.16.202.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}

module "chkp_ubuntu_subnet_02_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CHKP-UBUNTU-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.25"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CHKP"
  }
}




# FORCEPOINT Resources

resource "aws_subnet" "fpnt_private_subnet_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.103.0/24"

  tags = {
    Name        = "ACFW-2.0-FPNT-PRIVATE-SUBNET-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

resource "aws_subnet" "fpnt_private_subnet_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.203.0/24"

  tags = {
    Name        = "ACFW-2.0-FPNT-PRIVATE-SUBNET-02"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_window_subnet_01_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-FPNT-WINDOW-SUBNET-01-VM-01"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.fpnt_private_subnet_01.id
  private_ip    = "172.16.103.11"
  disk_size     = 100
  network_interfaces = {
    0 = module.fpnt_window_subnet_01_vm_01_eni_private.eni_id
    1 = module.fpnt_window_subnet_01_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_window_subnet_01_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FPNT-WINDOW-SUBNET-01-VM-01-ENI"
  subnet_id   = aws_subnet.fpnt_private_subnet_01.id
  private_ips = ["172.16.103.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_window_subnet_01_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FPNT-WINDOW-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.31"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_window_subnet_01_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-FPNT-WINDOW-SUBNET-01-VM-02"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.fpnt_private_subnet_01.id
  private_ip    = "172.16.103.12"
  disk_size     = 100
  network_interfaces = {
    0 = module.fpnt_window_subnet_01_vm_02_eni_private.eni_id
    1 = module.fpnt_window_subnet_01_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_window_subnet_01_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FPNT-WINDOW-SUBNET-01-VM-02-ENI"
  subnet_id   = aws_subnet.fpnt_private_subnet_01.id
  private_ips = ["172.16.103.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_window_subnet_01_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FPNT-WINDOW-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.32"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_ubuntu_subnet_01_vm_03" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-FPNT-UBUNTU-SUBNET-01-VM-03"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.fpnt_private_subnet_01.id
  private_ip    = "172.16.103.13"
  disk_size     = 75
  network_interfaces = {
    0 = module.fpnt_ubuntu_subnet_01_vm_03_eni_private.eni_id
    1 = module.fpnt_ubuntu_subnet_01_vm_03_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_ubuntu_subnet_01_vm_03_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FPNT-UBUNTU-SUBNET-01-VM-03-ENI"
  subnet_id   = aws_subnet.fpnt_private_subnet_01.id
  private_ips = ["172.16.103.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_ubuntu_subnet_01_vm_03_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FPNT-UBUNTU-MANAGEMNET-SUBNET-VM-03-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.33"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_ubuntu_subnet_02_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-FPNT-UBUNTU-SUBNET-02-VM-01"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.fpnt_private_subnet_02.id
  private_ip    = "172.16.203.11"
  disk_size     = 75
  network_interfaces = {
    0 = module.fpnt_ubuntu_subnet_02_vm_01_eni_private.eni_id
    1 = module.fpnt_ubuntu_subnet_02_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_ubuntu_subnet_02_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FPNT-UBUNTU-SUBNET-02-VM-01-ENI"
  subnet_id   = aws_subnet.fpnt_private_subnet_02.id
  private_ips = ["172.16.203.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_ubuntu_subnet_02_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FPNT-UBUNTU-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.34"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_ubuntu_subnet_02_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-FPNT-UBUNTU-SUBNET-02-VM-02"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.fpnt_private_subnet_02.id
  private_ip    = "172.16.203.12"
  disk_size     = 75
  network_interfaces = {
    0 = module.fpnt_ubuntu_subnet_02_vm_02_eni_private.eni_id
    1 = module.fpnt_ubuntu_subnet_02_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_ubuntu_subnet_02_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FPNT-UBUNTU-SUBNET-02-VM-02-ENI"
  subnet_id   = aws_subnet.fpnt_private_subnet_02.id
  private_ips = ["172.16.203.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}

module "fpnt_ubuntu_subnet_02_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FPNT-UBUNTU-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.35"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FPNT"
  }
}




# FORTINET Resources

resource "aws_subnet" "ftnt_private_subnet_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.104.0/24"

  tags = {
    Name        = "ACFW-2.0-FTNT-PRIVATE-SUBNET-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

resource "aws_subnet" "ftnt_private_subnet_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.204.0/24"

  tags = {
    Name        = "ACFW-2.0-FTNT-PRIVATE-SUBNET-02"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_window_subnet_01_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-FTNT-WINDOW-SUBNET-01-VM-01"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.ftnt_private_subnet_01.id
  private_ip    = "172.16.104.11"
  disk_size     = 100
  network_interfaces = {
    0 = module.ftnt_window_subnet_01_vm_01_eni_private.eni_id
    1 = module.ftnt_window_subnet_01_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_window_subnet_01_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FTNT-WINDOW-SUBNET-01-VM-01-ENI"
  subnet_id   = aws_subnet.ftnt_private_subnet_01.id
  private_ips = ["172.16.104.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_window_subnet_01_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FTNT-WINDOW-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.41"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_window_subnet_01_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-FTNT-WINDOW-SUBNET-01-VM-02"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.ftnt_private_subnet_01.id
  private_ip    = "172.16.104.12"
  disk_size     = 100
  network_interfaces = {
    0 = module.ftnt_window_subnet_01_vm_02_eni_private.eni_id
    1 = module.ftnt_window_subnet_01_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_window_subnet_01_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FTNT-WINDOW-SUBNET-01-VM-02-ENI"
  subnet_id   = aws_subnet.ftnt_private_subnet_01.id
  private_ips = ["172.16.104.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_window_subnet_01_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FTNT-WINDOW-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.42"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_ubuntu_subnet_01_vm_03" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-FTNT-UBUNTU-SUBNET-01-VM-03"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.ftnt_private_subnet_01.id
  private_ip    = "172.16.104.13"
  disk_size     = 75
  network_interfaces = {
    0 = module.ftnt_ubuntu_subnet_01_vm_03_eni_private.eni_id
    1 = module.ftnt_ubuntu_subnet_01_vm_03_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_ubuntu_subnet_01_vm_03_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FTNT-UBUNTU-SUBNET-01-VM-03-ENI"
  subnet_id   = aws_subnet.ftnt_private_subnet_01.id
  private_ips = ["172.16.104.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_ubuntu_subnet_01_vm_03_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FTNT-UBUNTU-MANAGEMNET-SUBNET-VM-03-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.43"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_ubuntu_subnet_02_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-FTNT-UBUNTU-SUBNET-02-VM-01"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.ftnt_private_subnet_02.id
  private_ip    = "172.16.204.11"
  disk_size     = 75
  network_interfaces = {
    0 = module.ftnt_ubuntu_subnet_02_vm_01_eni_private.eni_id
    1 = module.ftnt_ubuntu_subnet_02_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_ubuntu_subnet_02_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FTNT-UBUNTU-SUBNET-02-VM-01-ENI"
  subnet_id   = aws_subnet.ftnt_private_subnet_02.id
  private_ips = ["172.16.204.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_ubuntu_subnet_02_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FTNT-UBUNTU-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.44"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_ubuntu_subnet_02_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-FTNT-UBUNTU-SUBNET-02-VM-02"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.ftnt_private_subnet_02.id
  private_ip    = "172.16.204.12"
  disk_size     = 75
  network_interfaces = {
    0 = module.ftnt_ubuntu_subnet_02_vm_02_eni_private.eni_id
    1 = module.ftnt_ubuntu_subnet_02_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_ubuntu_subnet_02_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FTNT-UBUNTU-SUBNET-02-VM-02-ENI"
  subnet_id   = aws_subnet.ftnt_private_subnet_02.id
  private_ips = ["172.16.204.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}

module "ftnt_ubuntu_subnet_02_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-FTNT-UBUNTU-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.45"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "FTNT"
  }
}




# JUNIPER Resources

resource "aws_subnet" "jnpr_private_subnet_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.105.0/24"

  tags = {
    Name        = "ACFW-2.0-JNPR-PRIVATE-SUBNET-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

resource "aws_subnet" "jnpr_private_subnet_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.205.0/24"

  tags = {
    Name        = "ACFW-2.0-JNPR-PRIVATE-SUBNET-02"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_window_subnet_01_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-JNPR-WINDOW-SUBNET-01-VM-01"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.jnpr_private_subnet_01.id
  private_ip    = "172.16.105.11"
  disk_size     = 100
  network_interfaces = {
    0 = module.jnpr_window_subnet_01_vm_01_eni_private.eni_id
    1 = module.jnpr_window_subnet_01_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_window_subnet_01_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-JNPR-WINDOW-SUBNET-01-VM-01-ENI"
  subnet_id   = aws_subnet.jnpr_private_subnet_01.id
  private_ips = ["172.16.105.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_window_subnet_01_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-JNPR-WINDOW-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.51"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_window_subnet_01_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-JNPR-WINDOW-SUBNET-01-VM-02"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.jnpr_private_subnet_01.id
  private_ip    = "172.16.105.12"
  disk_size     = 100
  network_interfaces = {
    0 = module.jnpr_window_subnet_01_vm_02_eni_private.eni_id
    1 = module.jnpr_window_subnet_01_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_window_subnet_01_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-JNPR-WINDOW-SUBNET-01-VM-02-ENI"
  subnet_id   = aws_subnet.jnpr_private_subnet_01.id
  private_ips = ["172.16.105.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_window_subnet_01_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-JNPR-WINDOW-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.52"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_ubuntu_subnet_01_vm_03" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-JNPR-UBUNTU-SUBNET-01-VM-03"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.jnpr_private_subnet_01.id
  private_ip    = "172.16.105.13"
  disk_size     = 75
  network_interfaces = {
    0 = module.jnpr_ubuntu_subnet_01_vm_03_eni_private.eni_id
    1 = module.jnpr_ubuntu_subnet_01_vm_03_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_ubuntu_subnet_01_vm_03_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-JNPR-UBUNTU-SUBNET-01-VM-03-ENI"
  subnet_id   = aws_subnet.jnpr_private_subnet_01.id
  private_ips = ["172.16.105.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_ubuntu_subnet_01_vm_03_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-JNPR-UBUNTU-MANAGEMNET-SUBNET-VM-03-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.53"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_ubuntu_subnet_02_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-JNPR-UBUNTU-SUBNET-02-VM-01"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.jnpr_private_subnet_02.id
  private_ip    = "172.16.205.11"
  disk_size     = 75
  network_interfaces = {
    0 = module.jnpr_ubuntu_subnet_02_vm_01_eni_private.eni_id
    1 = module.jnpr_ubuntu_subnet_02_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_ubuntu_subnet_02_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-JNPR-UBUNTU-SUBNET-02-VM-01-ENI"
  subnet_id   = aws_subnet.jnpr_private_subnet_02.id
  private_ips = ["172.16.205.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_ubuntu_subnet_02_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-JNPR-UBUNTU-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.54"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_ubuntu_subnet_02_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-JNPR-UBUNTU-SUBNET-02-VM-02"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.jnpr_private_subnet_02.id
  private_ip    = "172.16.205.12"
  disk_size     = 75
  network_interfaces = {
    0 = module.jnpr_ubuntu_subnet_02_vm_02_eni_private.eni_id
    1 = module.jnpr_ubuntu_subnet_02_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_ubuntu_subnet_02_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-JNPR-UBUNTU-SUBNET-02-VM-02-ENI"
  subnet_id   = aws_subnet.jnpr_private_subnet_02.id
  private_ips = ["172.16.205.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}

module "jnpr_ubuntu_subnet_02_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-JNPR-UBUNTU-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.55"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "JNPR"
  }
}




# PALOALTO Resources

resource "aws_subnet" "panw_private_subnet_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.106.0/24"

  tags = {
    Name        = "ACFW-2.0-PANW-PRIVATE-SUBNET-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

resource "aws_subnet" "panw_private_subnet_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.206.0/24"

  tags = {
    Name        = "ACFW-2.0-PANW-PRIVATE-SUBNET-02"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_window_subnet_01_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-PANW-WINDOW-SUBNET-01-VM-01"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.panw_private_subnet_01.id
  private_ip    = "172.16.106.11"
  disk_size     = 100
  network_interfaces = {
    0 = module.panw_window_subnet_01_vm_01_eni_private.eni_id
    1 = module.panw_window_subnet_01_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_window_subnet_01_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-PANW-WINDOW-SUBNET-01-VM-01-ENI"
  subnet_id   = aws_subnet.panw_private_subnet_01.id
  private_ips = ["172.16.106.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_window_subnet_01_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-PANW-WINDOW-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.61"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_window_subnet_01_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-PANW-WINDOW-SUBNET-01-VM-02"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.panw_private_subnet_01.id
  private_ip    = "172.16.106.12"
  disk_size     = 100
  network_interfaces = {
    0 = module.panw_window_subnet_01_vm_02_eni_private.eni_id
    1 = module.panw_window_subnet_01_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_window_subnet_01_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-PANW-WINDOW-SUBNET-01-VM-02-ENI"
  subnet_id   = aws_subnet.panw_private_subnet_01.id
  private_ips = ["172.16.106.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_window_subnet_01_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-PANW-WINDOW-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.62"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_ubuntu_subnet_01_vm_03" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-PANW-UBUNTU-SUBNET-01-VM-03"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.panw_private_subnet_01.id
  private_ip    = "172.16.106.13"
  disk_size     = 75
  network_interfaces = {
    0 = module.panw_ubuntu_subnet_01_vm_03_eni_private.eni_id
    1 = module.panw_ubuntu_subnet_01_vm_03_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_ubuntu_subnet_01_vm_03_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-PANW-UBUNTU-SUBNET-01-VM-03-ENI"
  subnet_id   = aws_subnet.panw_private_subnet_01.id
  private_ips = ["172.16.106.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_ubuntu_subnet_01_vm_03_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-PANW-UBUNTU-MANAGEMNET-SUBNET-VM-03-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.63"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_ubuntu_subnet_02_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-PANW-UBUNTU-SUBNET-02-VM-01"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.panw_private_subnet_02.id
  private_ip    = "172.16.206.11"
  disk_size     = 75
  network_interfaces = {
    0 = module.panw_ubuntu_subnet_02_vm_01_eni_private.eni_id
    1 = module.panw_ubuntu_subnet_02_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_ubuntu_subnet_02_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-PANW-UBUNTU-SUBNET-02-VM-01-ENI"
  subnet_id   = aws_subnet.panw_private_subnet_02.id
  private_ips = ["172.16.206.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_ubuntu_subnet_02_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-PANW-UBUNTU-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.64"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_ubuntu_subnet_02_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-PANW-UBUNTU-SUBNET-02-VM-02"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.panw_private_subnet_02.id
  private_ip    = "172.16.206.12"
  disk_size     = 75
  network_interfaces = {
    0 = module.panw_ubuntu_subnet_02_vm_02_eni_private.eni_id
    1 = module.panw_ubuntu_subnet_02_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_ubuntu_subnet_02_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-PANW-UBUNTU-SUBNET-02-VM-02-ENI"
  subnet_id   = aws_subnet.panw_private_subnet_02.id
  private_ips = ["172.16.206.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}

module "panw_ubuntu_subnet_02_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-PANW-UBUNTU-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.65"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "PANW"
  }
}




# SONICWALL Resources

resource "aws_subnet" "swal_private_subnet_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.107.0/24"

  tags = {
    Name        = "ACFW-2.0-SWAL-PRIVATE-SUBNET-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

resource "aws_subnet" "swal_private_subnet_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.207.0/24"

  tags = {
    Name        = "ACFW-2.0-SWAL-PRIVATE-SUBNET-02"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_window_subnet_01_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-SWAL-WINDOW-SUBNET-01-VM-01"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.swal_private_subnet_01.id
  private_ip    = "172.16.107.11"
  disk_size     = 100
  network_interfaces = {
    0 = module.swal_window_subnet_01_vm_01_eni_private.eni_id
    1 = module.swal_window_subnet_01_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_window_subnet_01_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SWAL-WINDOW-SUBNET-01-VM-01-ENI"
  subnet_id   = aws_subnet.swal_private_subnet_01.id
  private_ips = ["172.16.107.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_window_subnet_01_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SWAL-WINDOW-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.71"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_window_subnet_01_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-SWAL-WINDOW-SUBNET-01-VM-02"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.swal_private_subnet_01.id
  private_ip    = "172.16.107.12"
  disk_size     = 100
  network_interfaces = {
    0 = module.swal_window_subnet_01_vm_02_eni_private.eni_id
    1 = module.swal_window_subnet_01_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_window_subnet_01_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SWAL-WINDOW-SUBNET-01-VM-02-ENI"
  subnet_id   = aws_subnet.swal_private_subnet_01.id
  private_ips = ["172.16.107.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_window_subnet_01_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SWAL-WINDOW-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.72"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_ubuntu_subnet_01_vm_03" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-SWAL-UBUNTU-SUBNET-01-VM-03"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.swal_private_subnet_01.id
  private_ip    = "172.16.107.13"
  disk_size     = 75
  network_interfaces = {
    0 = module.swal_ubuntu_subnet_01_vm_03_eni_private.eni_id
    1 = module.swal_ubuntu_subnet_01_vm_03_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_ubuntu_subnet_01_vm_03_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SWAL-UBUNTU-SUBNET-01-VM-03-ENI"
  subnet_id   = aws_subnet.swal_private_subnet_01.id
  private_ips = ["172.16.107.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_ubuntu_subnet_01_vm_03_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SWAL-UBUNTU-MANAGEMNET-SUBNET-VM-03-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.73"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_ubuntu_subnet_02_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-SWAL-UBUNTU-SUBNET-02-VM-01"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.swal_private_subnet_02.id
  private_ip    = "172.16.207.11"
  disk_size     = 75
  network_interfaces = {
    0 = module.swal_ubuntu_subnet_02_vm_01_eni_private.eni_id
    1 = module.swal_ubuntu_subnet_02_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_ubuntu_subnet_02_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SWAL-UBUNTU-SUBNET-02-VM-01-ENI"
  subnet_id   = aws_subnet.swal_private_subnet_02.id
  private_ips = ["172.16.207.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_ubuntu_subnet_02_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SWAL-UBUNTU-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.74"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_ubuntu_subnet_02_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-SWAL-UBUNTU-SUBNET-02-VM-02"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.swal_private_subnet_02.id
  private_ip    = "172.16.207.12"
  disk_size     = 75
  network_interfaces = {
    0 = module.swal_ubuntu_subnet_02_vm_02_eni_private.eni_id
    1 = module.swal_ubuntu_subnet_02_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_ubuntu_subnet_02_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SWAL-UBUNTU-SUBNET-02-VM-02-ENI"
  subnet_id   = aws_subnet.swal_private_subnet_02.id
  private_ips = ["172.16.207.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}

module "swal_ubuntu_subnet_02_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SWAL-UBUNTU-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.75"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SWAL"
  }
}




# SOPHOS Resources

resource "aws_subnet" "sphs_private_subnet_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.108.0/24"

  tags = {
    Name        = "ACFW-2.0-SPHS-PRIVATE-SUBNET-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

resource "aws_subnet" "sphs_private_subnet_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.208.0/24"

  tags = {
    Name        = "ACFW-2.0-SPHS-PRIVATE-SUBNET-02"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_window_subnet_01_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-SPHS-WINDOW-SUBNET-01-VM-01"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.sphs_private_subnet_01.id
  private_ip    = "172.16.108.11"
  disk_size     = 100
  network_interfaces = {
    0 = module.sphs_window_subnet_01_vm_01_eni_private.eni_id
    1 = module.sphs_window_subnet_01_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_window_subnet_01_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SPHS-WINDOW-SUBNET-01-VM-01-ENI"
  subnet_id   = aws_subnet.sphs_private_subnet_01.id
  private_ips = ["172.16.108.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_window_subnet_01_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SPHS-WINDOW-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.81"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_window_subnet_01_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-SPHS-WINDOW-SUBNET-01-VM-02"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.sphs_private_subnet_01.id
  private_ip    = "172.16.108.12"
  disk_size     = 100
  network_interfaces = {
    0 = module.sphs_window_subnet_01_vm_02_eni_private.eni_id
    1 = module.sphs_window_subnet_01_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_window_subnet_01_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SPHS-WINDOW-SUBNET-01-VM-02-ENI"
  subnet_id   = aws_subnet.sphs_private_subnet_01.id
  private_ips = ["172.16.108.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_window_subnet_01_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SPHS-WINDOW-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.82"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_ubuntu_subnet_01_vm_03" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-SPHS-UBUNTU-SUBNET-01-VM-03"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.sphs_private_subnet_01.id
  private_ip    = "172.16.108.13"
  disk_size     = 75
  network_interfaces = {
    0 = module.sphs_ubuntu_subnet_01_vm_03_eni_private.eni_id
    1 = module.sphs_ubuntu_subnet_01_vm_03_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_ubuntu_subnet_01_vm_03_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SPHS-UBUNTU-SUBNET-01-VM-03-ENI"
  subnet_id   = aws_subnet.sphs_private_subnet_01.id
  private_ips = ["172.16.108.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_ubuntu_subnet_01_vm_03_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SPHS-UBUNTU-MANAGEMNET-SUBNET-VM-03-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.83"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_ubuntu_subnet_02_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-SPHS-UBUNTU-SUBNET-02-VM-01"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.sphs_private_subnet_02.id
  private_ip    = "172.16.208.11"
  disk_size     = 75
  network_interfaces = {
    0 = module.sphs_ubuntu_subnet_02_vm_01_eni_private.eni_id
    1 = module.sphs_ubuntu_subnet_02_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_ubuntu_subnet_02_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SPHS-UBUNTU-SUBNET-02-VM-01-ENI"
  subnet_id   = aws_subnet.sphs_private_subnet_02.id
  private_ips = ["172.16.208.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_ubuntu_subnet_02_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SPHS-UBUNTU-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.84"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_ubuntu_subnet_02_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-SPHS-UBUNTU-SUBNET-02-VM-02"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.sphs_private_subnet_02.id
  private_ip    = "172.16.208.12"
  disk_size     = 75
  network_interfaces = {
    0 = module.sphs_ubuntu_subnet_02_vm_02_eni_private.eni_id
    1 = module.sphs_ubuntu_subnet_02_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_ubuntu_subnet_02_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SPHS-UBUNTU-SUBNET-02-VM-02-ENI"
  subnet_id   = aws_subnet.sphs_private_subnet_02.id
  private_ips = ["172.16.208.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}

module "sphs_ubuntu_subnet_02_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-SPHS-UBUNTU-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.85"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "SPHS"
  }
}




# VERSA NETWORKS Resources

resource "aws_subnet" "vrsn_private_subnet_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.109.0/24"

  tags = {
    Name        = "ACFW-2.0-VRSN-PRIVATE-SUBNET-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

resource "aws_subnet" "vrsn_private_subnet_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.209.0/24"

  tags = {
    Name        = "ACFW-2.0-VRSN-PRIVATE-SUBNET-02"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_window_subnet_01_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-VRSN-WINDOW-SUBNET-01-VM-01"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.vrsn_private_subnet_01.id
  private_ip    = "172.16.109.11"
  disk_size     = 100
  network_interfaces = {
    0 = module.vrsn_window_subnet_01_vm_01_eni_private.eni_id
    1 = module.vrsn_window_subnet_01_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_window_subnet_01_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-VRSN-WINDOW-SUBNET-01-VM-01-ENI"
  subnet_id   = aws_subnet.vrsn_private_subnet_01.id
  private_ips = ["172.16.109.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_window_subnet_01_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-VRSN-WINDOW-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.91"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_window_subnet_01_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-VRSN-WINDOW-SUBNET-01-VM-02"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.vrsn_private_subnet_01.id
  private_ip    = "172.16.109.12"
  disk_size     = 100
  network_interfaces = {
    0 = module.vrsn_window_subnet_01_vm_02_eni_private.eni_id
    1 = module.vrsn_window_subnet_01_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_window_subnet_01_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-VRSN-WINDOW-SUBNET-01-VM-02-ENI"
  subnet_id   = aws_subnet.vrsn_private_subnet_01.id
  private_ips = ["172.16.109.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_window_subnet_01_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-VRSN-WINDOW-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.92"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_ubuntu_subnet_01_vm_03" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-VRSN-UBUNTU-SUBNET-01-VM-03"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.vrsn_private_subnet_01.id
  private_ip    = "172.16.109.13"
  disk_size     = 75
  network_interfaces = {
    0 = module.vrsn_ubuntu_subnet_01_vm_03_eni_private.eni_id
    1 = module.vrsn_ubuntu_subnet_01_vm_03_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_ubuntu_subnet_01_vm_03_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-VRSN-UBUNTU-SUBNET-01-VM-03-ENI"
  subnet_id   = aws_subnet.vrsn_private_subnet_01.id
  private_ips = ["172.16.109.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_ubuntu_subnet_01_vm_03_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-VRSN-UBUNTU-MANAGEMNET-SUBNET-VM-03-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.93"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_ubuntu_subnet_02_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-VRSN-UBUNTU-SUBNET-02-VM-01"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.vrsn_private_subnet_02.id
  private_ip    = "172.16.209.11"
  disk_size     = 75
  network_interfaces = {
    0 = module.vrsn_ubuntu_subnet_02_vm_01_eni_private.eni_id
    1 = module.vrsn_ubuntu_subnet_02_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_ubuntu_subnet_02_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-VRSN-UBUNTU-SUBNET-02-VM-01-ENI"
  subnet_id   = aws_subnet.vrsn_private_subnet_02.id
  private_ips = ["172.16.209.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_ubuntu_subnet_02_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-VRSN-UBUNTU-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.94"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_ubuntu_subnet_02_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-VRSN-UBUNTU-SUBNET-02-VM-02"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.vrsn_private_subnet_02.id
  private_ip    = "172.16.209.12"
  disk_size     = 75
  network_interfaces = {
    0 = module.vrsn_ubuntu_subnet_02_vm_02_eni_private.eni_id
    1 = module.vrsn_ubuntu_subnet_02_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_ubuntu_subnet_02_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-VRSN-UBUNTU-SUBNET-02-VM-02-ENI"
  subnet_id   = aws_subnet.vrsn_private_subnet_02.id
  private_ips = ["172.16.209.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}

module "vrsn_ubuntu_subnet_02_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-VRSN-UBUNTU-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.95"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "VRSN"
  }
}




# WATCHGUARD Resources

resource "aws_subnet" "wbtn_private_subnet_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.110.0/24"

  tags = {
    Name        = "ACFW-2.0-WGTN-PRIVATE-SUBNET-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

resource "aws_subnet" "wbtn_private_subnet_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.210.0/24"

  tags = {
    Name        = "ACFW-2.0-WGTN-PRIVATE-SUBNET-02"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_window_subnet_01_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-WGTN-WINDOW-SUBNET-01-VM-01"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.wbtn_private_subnet_01.id
  private_ip    = "172.16.110.11"
  disk_size     = 100
  network_interfaces = {
    0 = module.wbtn_window_subnet_01_vm_01_eni_private.eni_id
    1 = module.wbtn_window_subnet_01_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_window_subnet_01_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-WGTN-WINDOW-SUBNET-01-VM-01-ENI"
  subnet_id   = aws_subnet.wbtn_private_subnet_01.id
  private_ips = ["172.16.110.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_window_subnet_01_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-WGTN-WINDOW-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.101"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_window_subnet_01_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-WGTN-WINDOW-SUBNET-01-VM-02"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.wbtn_private_subnet_01.id
  private_ip    = "172.16.110.12"
  disk_size     = 100
  network_interfaces = {
    0 = module.wbtn_window_subnet_01_vm_02_eni_private.eni_id
    1 = module.wbtn_window_subnet_01_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_window_subnet_01_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-WGTN-WINDOW-SUBNET-01-VM-02-ENI"
  subnet_id   = aws_subnet.wbtn_private_subnet_01.id
  private_ips = ["172.16.110.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_window_subnet_01_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-WGTN-WINDOW-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.102"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_ubuntu_subnet_01_vm_03" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-WGTN-UBUNTU-SUBNET-01-VM-03"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.wbtn_private_subnet_01.id
  private_ip    = "172.16.110.13"
  disk_size     = 75
  network_interfaces = {
    0 = module.wbtn_ubuntu_subnet_01_vm_03_eni_private.eni_id
    1 = module.wbtn_ubuntu_subnet_01_vm_03_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_ubuntu_subnet_01_vm_03_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-WGTN-UBUNTU-SUBNET-01-VM-03-ENI"
  subnet_id   = aws_subnet.wbtn_private_subnet_01.id
  private_ips = ["172.16.110.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_ubuntu_subnet_01_vm_03_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-WGTN-UBUNTU-MANAGEMNET-SUBNET-VM-03-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.103"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_ubuntu_subnet_02_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-WGTN-UBUNTU-SUBNET-02-VM-01"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.wbtn_private_subnet_02.id
  private_ip    = "172.16.210.11"
  disk_size     = 75
  network_interfaces = {
    0 = module.wbtn_ubuntu_subnet_02_vm_01_eni_private.eni_id
    1 = module.wbtn_ubuntu_subnet_02_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_ubuntu_subnet_02_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-WGTN-UBUNTU-SUBNET-02-VM-01-ENI"
  subnet_id   = aws_subnet.wbtn_private_subnet_02.id
  private_ips = ["172.16.210.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_ubuntu_subnet_02_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-WGTN-UBUNTU-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.104"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_ubuntu_subnet_02_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-WGTN-UBUNTU-SUBNET-02-VM-02"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.wbtn_private_subnet_02.id
  private_ip    = "172.16.210.12"
  disk_size     = 75
  network_interfaces = {
    0 = module.wbtn_ubuntu_subnet_02_vm_02_eni_private.eni_id
    1 = module.wbtn_ubuntu_subnet_02_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_ubuntu_subnet_02_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-WGTN-UBUNTU-SUBNET-02-VM-02-ENI"
  subnet_id   = aws_subnet.wbtn_private_subnet_02.id
  private_ips = ["172.16.210.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}

module "wbtn_ubuntu_subnet_02_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-WGTN-UBUNTU-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.105"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "WGTN"
  }
}




# BARRACUDA Resources

resource "aws_subnet" "cuda_private_subnet_01" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.111.0/24"

  tags = {
    Name        = "ACFW-2.0-CUDA-PRIVATE-SUBNET-01"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

resource "aws_subnet" "cuda_private_subnet_02" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.16.211.0/24"

  tags = {
    Name        = "ACFW-2.0-CUDA-PRIVATE-SUBNET-02"
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_window_subnet_01_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-CUDA-WINDOW-SUBNET-01-VM-01"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.cuda_private_subnet_01.id
  private_ip    = "172.16.111.11"
  disk_size     = 100
  network_interfaces = {
    0 = module.cuda_window_subnet_01_vm_01_eni_private.eni_id
    1 = module.cuda_window_subnet_01_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_window_subnet_01_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CUDA-WINDOW-SUBNET-01-VM-01-ENI"
  subnet_id   = aws_subnet.cuda_private_subnet_01.id
  private_ips = ["172.16.111.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_window_subnet_01_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CUDA-WINDOW-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.111"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_window_subnet_01_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-CUDA-WINDOW-SUBNET-01-VM-02"
  ami           = var.ami_windows
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.cuda_private_subnet_01.id
  private_ip    = "172.16.111.12"
  disk_size     = 100
  network_interfaces = {
    0 = module.cuda_window_subnet_01_vm_02_eni_private.eni_id
    1 = module.cuda_window_subnet_01_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_window_subnet_01_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CUDA-WINDOW-SUBNET-01-VM-02-ENI"
  subnet_id   = aws_subnet.cuda_private_subnet_01.id
  private_ips = ["172.16.111.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_window_subnet_01_vm_02_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CUDA-WINDOW-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.112"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_ubuntu_subnet_01_vm_03" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-CUDA-UBUNTU-SUBNET-01-VM-03"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.cuda_private_subnet_01.id
  private_ip    = "172.16.111.13"
  disk_size     = 75
  network_interfaces = {
    0 = module.cuda_ubuntu_subnet_01_vm_03_eni_private.eni_id
    1 = module.cuda_ubuntu_subnet_01_vm_03_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_ubuntu_subnet_01_vm_03_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CUDA-UBUNTU-SUBNET-01-VM-03-ENI"
  subnet_id   = aws_subnet.cuda_private_subnet_01.id
  private_ips = ["172.16.111.13"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_ubuntu_subnet_01_vm_03_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CUDA-UBUNTU-MANAGEMNET-SUBNET-VM-03-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.113"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_ubuntu_subnet_02_vm_01" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-CUDA-UBUNTU-SUBNET-02-VM-01"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.cuda_private_subnet_02.id
  private_ip    = "172.16.211.11"
  disk_size     = 75
  network_interfaces = {
    0 = module.cuda_ubuntu_subnet_02_vm_01_eni_private.eni_id
    1 = module.cuda_ubuntu_subnet_02_vm_01_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_ubuntu_subnet_02_vm_01_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CUDA-UBUNTU-SUBNET-02-VM-01-ENI"
  subnet_id   = aws_subnet.cuda_private_subnet_02.id
  private_ips = ["172.16.211.11"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_ubuntu_subnet_02_vm_01_eni_management" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CUDA-UBUNTU-MANAGEMNET-SUBNET-VM-01-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.114"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_ubuntu_subnet_02_vm_02" {
  source        = "./modules/instance"
  name          = "ACFW-2.0-CUDA-UBUNTU-SUBNET-02-VM-02"
  ami           = var.ami_ubuntu
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.cuda_private_subnet_02.id
  private_ip    = "172.16.211.12"
  disk_size     = 75
  network_interfaces = {
    0 = module.cuda_ubuntu_subnet_02_vm_02_eni_private.eni_id
    1 = module.cuda_ubuntu_subnet_02_vm_02_eni_management.eni_id
  }
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_ubuntu_subnet_02_vm_02_eni_private" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CUDA-UBUNTU-SUBNET-02-VM-02-ENI"
  subnet_id   = aws_subnet.cuda_private_subnet_02.id
  private_ips = ["172.16.211.12"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}

module "cuda_ubuntu_management_subnet_vm_02_eni" {
  source      = "./modules/eni"
  name        = "ACFW-2.0-CUDA-UBUNTU-MANAGEMNET-SUBNET-VM-02-ENI"
  subnet_id   = aws_subnet.management.id
  private_ips = ["172.16.10.115"]
  tags = {
    "Test Name" = "ACFW-2.0"
    "Test Type" = "Private"
    Vendor      = "CUDA"
  }
}


