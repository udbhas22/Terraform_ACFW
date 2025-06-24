
# Terraform AWS Infrastructure

This repository contains Terraform configurations to deploy AWS infrastructure, including VPCs, subnets, EC2 instances, and Elastic Network Interfaces (ENIs), based on specified vendor requirements.

## Structure

- `main.tf`: Main Terraform configuration file.
- `variables.tf`: Input variables for the Terraform configuration.
- `outputs.tf`: Output values from the Terraform configuration.
- `versions.tf`: Specifies required Terraform and provider versions.
- `modules/`: Contains reusable Terraform modules.
  - `instance/`: Module for creating EC2 instances.
  - `eni/`: Module for creating Elastic Network Interfaces (ENIs).



