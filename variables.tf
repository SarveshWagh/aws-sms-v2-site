# AWS variables
variable "ami" {
  type        = string
  description = "AMI ID for the CE instance"
}

variable "instance-type" {
  type        = string
  description = "Size of the CE instance"
}

variable "key-pair" {
  type        = string
  description = "SSH key to login into the CE instance"
}

variable "vol-size" {
  type        = number
  description = "Volume size of the CE instance"
}

variable "vol-type" {
  type        = string
  description = "Volume type of the CE instance"
}

variable "no_of_nics" {
  type        = number
  description = "Total no of NICs on each CE node"
}

variable "eip_config" {
  type = object({
    create_eip = bool
    existing_allocation_ids = list(string)
  })
  description = "Conditions for EIP, whether we have to create new one or use existing ones."
  default = {
    create_eip = true
    existing_allocation_ids = []
  }
  validation {
    condition = (
      var.eip_config.create_eip == true && length(var.eip_config.existing_allocation_ids) == 0 || var.eip_config.create_eip == false && length(var.eip_config.existing_allocation_ids) != 0
    ) 
    error_message = "Validation failed : If 'create_eip' is true, 'existing_allocation_ids' should be empty. || If 'create_eip' is false, 'existing_allocation_ids' should not be empty and its length should match 'num_nodes'."
  }
}

# Security Group Configuration as an object
variable "security_group_config" {
  description = <<EOT
Configuration for Security Groups:
- create_slo_sg: Boolean to indicate whether to create a new SLO security group.
- create_sli_sg: Boolean to indicate whether to create a new SLI security group (only if num_nics == 2).
- existing_slo_sg_id: Existing security group ID for SLO (required if create_slo_sg is false).
- existing_sli_sg_id: Existing security group ID for SLI (required if create_sli_sg is false).
EOT
  type = object({
    create_slo_sg     = bool
    create_sli_sg     = bool
    existing_slo_sg_id = string
    existing_sli_sg_id = string
  })

  # Combined validation for both SLO and SLI security groups
# Combined validation for both SLO and SLI security groups
validation {
  condition = (
    # SLO security group validation
    (var.security_group_config.create_slo_sg && length(var.security_group_config.existing_slo_sg_id) == 0) || 
    (var.security_group_config.create_slo_sg == false && length(var.security_group_config.existing_slo_sg_id) > 0)
  ) && (
    # SLI security group validation 
      (var.security_group_config.create_sli_sg && length(var.security_group_config.existing_sli_sg_id) == 0) ||
      (var.security_group_config.create_sli_sg == false && length(var.security_group_config.existing_sli_sg_id) > 0)   
  )
    error_message = <<EOT
Invalid security group configuration. Please ensure that:
  - If create_slo_sg is false, existing_slo_sg_id must be provided.
  - If create_slo_sg is true, existing_slo_sg_id must be empty.
  - If create_sli_sg is false, existing_sli_sg_id must be provided.
  - If create_sli_sg is true, existing_sli_sg_id must be empty.
EOT
 }
}

variable "subnet-ids-for-slo-nics" {
  type        = list(string)
  description = "List of Subnet IDs for the SLO NICs"
}

variable "subnet-ids-for-sli-nics" {
  type        = list(string)
  description = "List of Subnet IDs for the SLI NICs"
}

variable "sg-name" {
  type        = string
  description = "Name of the security group"
}

variable "vpc-id" {
  type        = string
  description = "ID of the VPC"
}

# XC variables
variable "smsv2-site-name" {
  type        = string
  description = "Name of the secure mesh v2 site object"
}

variable "num_of_ce_nodes" {
  type        = string
  description = "num of CE nodes that will be created"
}

variable "api_p12_file" {
  type        = string
  description = "REQUIRED:  This is the path to the Volterra API Key.  See https://volterra.io/docs/how-to/user-mgmt/credentials"
}

variable "api_url" {
  type        = string
  description = "REQUIRED:  This is your Volterra API url"
}

# variable "virtual-site-name" {
#   type        = string
#   description = "Name of the virtual site"
# }