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
  default     = "eastus"
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

variable "functions_subnet_prefix" {
  description = "Dedicated subnet delegated to Microsoft.App/environments for Azure Functions."
  type        = string
  default     = "10.20.3.0/27"
}

variable "aks_sku_tier" {
  description = "SKU Tier for the AKS cluster ('Free' for student/academic deployment)."
  type        = string
  default     = "Free"
}

variable "aks_vm_size" {
  description = "VM size for the AKS system node pool."
  type        = string
  default     = "Standard_B2s"
}

variable "aks_min_node_count" {
  description = "Minimum node count for the AKS system pool."
  type        = number
  default     = 1
}

variable "aks_max_node_count" {
  description = "Maximum node count for the AKS system pool."
  type        = number
  default     = 2
}

variable "availability_zones" {
  description = "Availability zones assigned to the AKS system pool when supported by the selected region."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Log Analytics and Application Insights retention period."
  type        = number
  default     = 30
}

variable "apim_publisher_name" {
  description = "Display name for the APIM publisher."
  type        = string
  default     = "CatCar Operations"
}

variable "apim_publisher_email" {
  description = "Contact email for the APIM publisher."
  type        = string
  default     = "operations@catcar.com"
}

variable "apim_sku_name" {
  description = "APIM SKU for serverless Consumption architecture."
  type        = string
  default     = "Consumption_0"
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

variable "gateway_backend_key" {
  description = "Shared secret key injected by APIM and required by origin workloads in Production."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.gateway_backend_key) >= 32
    error_message = "gateway_backend_key must contain at least 32 characters."
  }
}

variable "api_backend_url" {
  description = "APIM backend URL for the CatCar API. If empty, defaults to the public IP FQDN."
  type        = string
  default     = ""
}

variable "auth_function_backend_url" {
  description = "APIM backend URL for the customer auth Function. If empty, defaults to deterministic Function FQDN."
  type        = string
  default     = ""
}

variable "api_dns_label" {
  description = "DNS label prefix for the AKS LoadBalancer public IP."
  type        = string
  default     = ""
}

variable "student_credit_budget_brl" {
  description = "Total student credit budget amount in billing currency."
  type        = number
  default     = 500
}

variable "tags" {
  description = "Additional tags applied to managed Azure resources."
  type        = map(string)
  default     = {}
}
