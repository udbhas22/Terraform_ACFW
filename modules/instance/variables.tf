



variable "name" {
  description = "Name of the EC2 instance."
  type        = string
}

variable "ami" {
  description = "AMI ID for the EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "Instance type for the EC2 instance."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched."
  type        = string
}

variable "private_ip" {
  description = "Private IP address for the instance."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the instance."
  type        = map(string)
  default     = {}
}




variable "disk_size" {
  description = "Size of the root disk in GB."
  type        = number
}

variable "network_interfaces" {
  description = "A map of network interfaces to attach to the instance. Key is device_index, value is ENI ID."
  type        = map(string)
  default     = {}
}


