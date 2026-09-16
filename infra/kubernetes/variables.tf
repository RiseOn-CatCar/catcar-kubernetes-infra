variable "application_name" {
  description = "DNS-safe application name used in resource names."
  type        = string
  default     = "catcar"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Resource group managed by this infrastructure repository."
  type        = string
  default     = "rg-catcar-prod"
}

variable "vnet_address_space" {
  description = "Address space for the CatCar virtual network."
  type        = string
  default     = "10.20.0.0/16"
}

variable "aks_subnet_prefix" {
  description = "Subnet used by AKS node pools."
  type        = string
  default     = "10.20.1.0/24"
}

variable "apim_subnet_prefix" {
  description = "Dedicated subnet used by API Management."
  type        = string
  default     = "10.20.2.0/24"
}

variable "aks_vm_size" {
  description = "VM size for the AKS system node pool."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "aks_min_node_count" {
  description = "Minimum node count for the AKS system pool."
  type        = number
  default     = 2
}

variable "aks_max_node_count" {
  description = "Maximum node count for the AKS system pool."
  type        = number
  default     = 6
}

variable "availability_zones" {
  description = "Availability zones assigned to the AKS system pool."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "zone_redundancy_enabled" {
  description = "Whether Premium ACR is zone redundant."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log Analytics and Application Insights retention period."
  type        = number
  default     = 30
}

variable "apim_publisher_name" {
  description = "Display name for the APIM publisher."
  type        = string
}

variable "apim_publisher_email" {
  description = "Contact email for the APIM publisher."
  type        = string
}

variable "apim_sku_name" {
  description = "APIM SKU; Internal VNet injection requires a supported SKU."
  type        = string
  default     = "Developer_1"
}

variable "tags" {
  description = "Additional tags applied to managed Azure resources."
  type        = map(string)
  default     = {}
}
