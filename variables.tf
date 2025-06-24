



variable "ami_ubuntu" {
  description = "AMI ID for Ubuntu instances."
  type        = string
  default     = "ami-053b0d53c279acc90" # Example Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
}

variable "ami_windows" {
  description = "AMI ID for Windows instances."
  type        = string
  default     = "ami-0a0a0a0a0a0a0a0a0" # Placeholder: Replace with a valid Windows AMI ID
}


