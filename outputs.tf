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
