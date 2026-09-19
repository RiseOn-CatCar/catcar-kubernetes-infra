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
  default     = "brazilsouth"
}

variable "resource_group_name" {
  description = "Resource group for CatCar Kubernetes and platform infrastructure."
  type        = string
  default     = "catcar-prod"
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

variable "aks_sku_tier" {
  description = "SKU Tier for the AKS cluster ('Free' for dev/test/homolog or 'Standard' for SLA-backed production)."
  type        = string
  default     = "Free"
}

variable "aks_vm_size" {
  description = "VM size for the AKS system node pool."
  type        = string
  default     = "Standard_D2s_v6"
}

variable "aks_min_node_count" {
  description = "Minimum node count for the AKS system pool."
  type        = number
  default     = 1
}

variable "aks_max_node_count" {
  description = "Maximum node count for the AKS system pool."
  type        = number
  default     = 3
}

variable "private_endpoints_subnet_prefix" {
  description = "Subnet used by private endpoints for foundation services."
  type        = string
  default     = "10.20.4.0/24"
}

variable "availability_zones" {
  description = "Availability zones assigned to the AKS system pool when supported by the selected region."
  type        = list(string)
  default     = []
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

variable "customer_jwt_signing_key" {
  description = "Signing key used by the customer JWT issuer and APIM validation policy."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.customer_jwt_signing_key) >= 32
    error_message = "customer_jwt_signing_key must contain at least 32 characters."
  }
}

variable "admin_jwt_secret" {
  description = "Signing key used by the administrative staff JWT issuer and APIM validation policy."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_jwt_secret) >= 32
    error_message = "admin_jwt_secret must contain at least 32 characters."
  }
}

variable "api_backend_url" {
  description = "APIM-reachable internal load balancer URL for the CatCar API."
  type        = string
  default     = "http://catcar-api.catcar.internal"
}

variable "auth_function_backend_url" {
  description = "Private URL for the customer authentication function backend."
  type        = string
  default     = "https://auth-function.internal.catcar.local"
}

variable "tags" {
  description = "Additional tags applied to managed Azure resources."
  type        = map(string)
  default     = {}
}
