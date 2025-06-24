



variable "name" {
  description = "Name of the ENI."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet in which to create the ENI."
  type        = string
}

variable "private_ips" {
  description = "A list of private IP addresses to assign to the ENI."
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to assign to the ENI."
  type        = map(string)
  default     = {}
}


