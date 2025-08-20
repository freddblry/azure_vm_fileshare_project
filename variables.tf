variable "project_name" {
  description = "Short name for resources (letters/numbers only)."
  type        = string
  default     = "azurevm"
}

variable "location" {
  description = "Azure region to deploy to."
  type        = string
  default     = "francecentral"
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM."
  type        = string
  default     = "devops"
}

variable "admin_password" {
  description = "Admin password for the VM (set via TF_VAR_admin_password in CI)."
  type        = string
  sensitive   = true
}

variable "fileshare_name" {
  description = "Name of the Azure File Share to mount at /Projects."
  type        = string
  default     = "projects"
}

variable "address_space" {
  description = "VNet address space."
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_prefix" {
  description = "Subnet CIDR prefix."
  type        = string
  default     = "10.20.1.0/24"
}
