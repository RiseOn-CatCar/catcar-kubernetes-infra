variable "application_name" {
  description = "DNS-safe application name used in resource names."
  type        = string
  default     = "catcar"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "brazilsouth"
}

variable "resource_group_name" {
  description = "Resource group for CatCar Kubernetes and platform infrastructure."
  type        = string
  default     = "rg-catcar"
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
  description = "SKU tier for the AKS cluster: Free or Standard."
  type        = string
  default     = "Standard"
}

variable "aks_vm_size" {
  description = "VM size for the AKS system node pool."
  type        = string
  default     = "Standard_D2ads_v6"
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



variable "tags" {
  description = "Additional tags applied to managed Azure resources."
  type        = map(string)
  default     = {}
}

variable "vnet_name" {
  description = "Existing VNet name to adopt, if different from the derived name."
  type        = string
  default     = null
}

variable "aks_cluster_name" {
  description = "Existing AKS name to adopt, if different from the derived name."
  type        = string
  default     = null
}

variable "acr_name" {
  description = "Existing ACR name to adopt, if different from the derived name."
  type        = string
  default     = null
}

variable "log_analytics_workspace_name" {
  description = "Existing workspace name to adopt, if different from the derived name."
  type        = string
  default     = null
}

variable "api_private_ip" {
  description = "Existing or preflight-confirmed free AKS internal load balancer IPv4 address."
  type        = string
  default     = null
  validation {
    condition     = var.api_private_ip == null ? true : can(cidrhost("${var.api_private_ip}/32", 0))
    error_message = "api_private_ip must be an IPv4 address."
  }
}

variable "auth_function_subnet_prefix" {
  description = "Preflight-confirmed free /27 subnet for the internal ACA environment."
  type        = string
  default     = "10.20.8.0/27"
}

variable "auth_function_container_app_name" {
  description = "Existing auth Container App name to adopt, if different from the derived name."
  type        = string
  default     = null
}
