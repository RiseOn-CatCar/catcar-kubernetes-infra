output "resource_group_name" {
  description = "Resource group containing CatCar Kubernetes infrastructure."
  value       = azurerm_resource_group.this.name
}

output "vnet_name" {
  description = "VNet name consumed by the database infrastructure state."
  value       = azurerm_virtual_network.this.name
}

output "vnet_id" {
  description = "CatCar virtual network resource ID."
  value       = azurerm_virtual_network.this.id
}

output "aks_cluster_id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "aks_cluster_name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "acr_id" {
  description = "Azure Container Registry resource ID."
  value       = azurerm_container_registry.this.id
}

output "acr_name" {
  description = "Azure Container Registry name."
  value       = azurerm_container_registry.this.name
}

output "acr_login_server" {
  description = "Azure Container Registry login server."
  value       = azurerm_container_registry.this.login_server
}

output "api_management_id" {
  description = "API Management resource ID."
  value       = azurerm_api_management.this.id
}

output "application_insights_id" {
  description = "Application Insights resource ID for alert rules."
  value       = azurerm_application_insights.this.id
}

output "application_insights_connection_string" {
  description = "Application Insights connection string for workload configuration."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID for diagnostics and alerts."
  value       = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name."
  value       = azurerm_log_analytics_workspace.this.name
}

output "application_insights_name" {
  description = "Application Insights resource name."
  value       = azurerm_application_insights.this.name
}

output "api_management_gateway_url" {
  value = azurerm_api_management.this.gateway_url
}

output "private_endpoints_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "api_private_ip" {
  value = local.api_private_ip
}

output "communication_sender_address" {
  value = "DoNotReply@${azurerm_email_communication_service_domain.this.from_sender_domain}"
}

output "communication_connection_string" {
  value     = azurerm_communication_service.this.primary_connection_string
  sensitive = true
}

output "auth_function_environment_id" {
  value = azurerm_container_app_environment.auth.id
}

output "auth_function_environment_name" {
  value = azurerm_container_app_environment.auth.name
}

output "auth_function_default_domain" {
  value = azurerm_container_app_environment.auth.default_domain
}

output "auth_function_environment_static_ip" {
  value = azurerm_container_app_environment.auth.static_ip_address
}

output "auth_function_subnet_id" {
  value = azurerm_subnet.auth.id
}

output "auth_function_container_app_name" {
  value = local.auth_function_container_app_name
}

output "auth_function_backend_url" {
  value = local.auth_function_backend_url
}
