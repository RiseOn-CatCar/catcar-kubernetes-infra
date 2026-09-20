terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

locals {
  name_prefix = "${var.application_name}-${var.environment}"
  sub_suffix  = substr(data.azurerm_client_config.current.subscription_id, 0, 8)
  acr_name    = lower(replace("catcarprod${local.sub_suffix}", "/[^0-9a-z]/", ""))
  tags = merge(var.tags, {
    application = var.application_name
    environment = var.environment
    managed_by  = "terraform"
  })

  default_api_backend_url           = "https://${azurerm_public_ip.api.fqdn}"
  default_auth_function_backend_url = "https://func-catcar-prod-${local.sub_suffix}.azurewebsites.net"
  effective_api_backend_url           = var.api_backend_url != "" ? var.api_backend_url : local.default_api_backend_url
  effective_auth_function_backend_url = var.auth_function_backend_url != "" ? var.auth_function_backend_url : local.default_auth_function_backend_url
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_address_space]
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_prefix]
}

resource "azurerm_subnet" "functions" {
  name                 = "snet-functions"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.functions_subnet_prefix]

  delegation {
    name = "functions-delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_public_ip" "api" {
  name                = "pip-${local.name_prefix}-api"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.api_dns_label != "" ? var.api_dns_label : "catcar-api-prod-${local.sub_suffix}"
  tags                = local.tags
}

resource "azurerm_container_registry" "this" {
  name                          = local.acr_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  sku                           = "Basic"
  admin_enabled                 = false
  public_network_access_enabled = true
  tags                          = local.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${local.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  daily_quota_gb      = 0.1
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${local.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

resource "azurerm_application_insights_workbook" "catcar_dashboard" {
  name                = "b83d5a71-6c2e-4b91-8e03-9d7a2f1b4c5e"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  display_name        = "CatCar Operations Dashboard"
  data_json           = replace(file("${path.module}/workbooks/catcar-dashboard.json"), "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.insights/components/appi-catcar-prod", azurerm_application_insights.this.id)
  tags                = local.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${local.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = local.name_prefix
  sku_tier            = var.aks_sku_tier

  default_node_pool {
    name                 = "system"
    vm_size              = var.aks_vm_size
    vnet_subnet_id       = azurerm_subnet.aks.id
    auto_scaling_enabled = true
    min_count            = var.aks_min_node_count
    max_count            = var.aks_max_node_count
    type                 = "VirtualMachineScaleSets"
    zones                = var.availability_zones
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_data_plane = "cilium"
    network_policy     = "cilium"
    load_balancer_sku  = "standard"
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.this.id
    msi_auth_for_monitoring_enabled = true
  }

  azure_policy_enabled              = false
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  local_account_disabled            = true
  tags                              = local.tags

  azure_active_directory_role_based_access_control {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = true
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.this.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_api_management" "this" {
  name                = "apim-${local.name_prefix}-${local.sub_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_named_value" "customer_jwt_signing_key" {
  name                = "catcar-jwt-signing-key"
  display_name        = "catcar-jwt-signing-key"
  resource_group_name = azurerm_resource_group.this.name
  api_management_name = azurerm_api_management.this.name
  value               = var.customer_jwt_signing_key
  secret              = true
}

resource "azurerm_api_management_named_value" "admin_jwt_secret" {
  name                = "catcar-admin-jwt-secret"
  display_name        = "catcar-admin-jwt-secret"
  resource_group_name = azurerm_resource_group.this.name
  api_management_name = azurerm_api_management.this.name
  value               = var.admin_jwt_secret
  secret              = true
}

resource "azurerm_api_management_named_value" "gateway_backend_key" {
  name                = "gateway-backend-key"
  display_name        = "gateway-backend-key"
  resource_group_name = azurerm_resource_group.this.name
  api_management_name = azurerm_api_management.this.name
  value               = var.gateway_backend_key
  secret              = true
}

resource "azurerm_api_management_api" "catcar" {
  name                = "catcar-api"
  resource_group_name = azurerm_resource_group.this.name
  api_management_name = azurerm_api_management.this.name
  revision            = "1"
  display_name        = "CatCar API"
  path                = "api"
  service_url         = local.effective_api_backend_url
  protocols           = ["https"]
}

resource "azurerm_api_management_backend" "catcar" {
  name                = "catcar-api-aks"
  resource_group_name = azurerm_resource_group.this.name
  api_management_name = azurerm_api_management.this.name
  protocol            = "http"
  url                 = local.effective_api_backend_url
}

resource "azurerm_api_management_backend" "auth_function" {
  name                = "catcar-auth-function"
  resource_group_name = azurerm_resource_group.this.name
  api_management_name = azurerm_api_management.this.name
  protocol            = "http"
  url                 = local.effective_auth_function_backend_url
}

resource "azurerm_api_management_logger" "app_insights" {
  name                = "app-insights-logger"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  resource_id         = azurerm_application_insights.this.id

  application_insights {
    instrumentation_key = azurerm_application_insights.this.instrumentation_key
  }
}

resource "azurerm_api_management_api_diagnostic" "catcar" {
  identifier               = "applicationinsights"
  resource_group_name      = azurerm_resource_group.this.name
  api_management_name      = azurerm_api_management.this.name
  api_name                 = azurerm_api_management_api.catcar.name
  api_management_logger_id = azurerm_api_management_logger.app_insights.id
  sampling_percentage      = 50.0
  always_log_errors        = true
}

locals {
  api_operations = {
    customer_auth_post    = { method = "POST", url_template = "auth/customer", display_name = "Customer authentication" }
    customer_auth_options = { method = "OPTIONS", url_template = "auth/customer", display_name = "Customer authentication CORS preflight" }
    login_post            = { method = "POST", url_template = "v1/identity-access/auth/login", display_name = "Identity login" }
    progress_get          = { method = "GET", url_template = "v1/service-operations/work-orders/{id}/progress", display_name = "Work order progress" }
  }
}

resource "azurerm_api_management_api_operation" "catcar" {
  for_each            = local.api_operations
  operation_id        = each.key
  api_name            = azurerm_api_management_api.catcar.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = each.value.display_name
  method              = each.value.method
  url_template        = each.value.url_template
  dynamic "template_parameter" {
    for_each = each.key == "progress_get" ? [1] : []
    content {
      name     = "id"
      required = true
      type     = "string"
    }
  }
  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "catcar_get_catch_all" {
  operation_id        = "get-catch-all"
  api_name            = azurerm_api_management_api.catcar.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "GET catch all"
  method              = "GET"
  url_template        = "{*path}"

  template_parameter {
    name     = "path"
    type     = "string"
    required = false
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "catcar_post_catch_all" {
  operation_id        = "post-catch-all"
  api_name            = azurerm_api_management_api.catcar.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "POST catch all"
  method              = "POST"
  url_template        = "{*path}"

  template_parameter {
    name     = "path"
    type     = "string"
    required = false
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "catcar_put_catch_all" {
  operation_id        = "put-catch-all"
  api_name            = azurerm_api_management_api.catcar.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "PUT catch all"
  method              = "PUT"
  url_template        = "{*path}"

  template_parameter {
    name     = "path"
    type     = "string"
    required = false
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "catcar_patch_catch_all" {
  operation_id        = "patch-catch-all"
  api_name            = azurerm_api_management_api.catcar.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "PATCH catch all"
  method              = "PATCH"
  url_template        = "{*path}"

  template_parameter {
    name     = "path"
    type     = "string"
    required = false
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "catcar_delete_catch_all" {
  operation_id        = "delete-catch-all"
  api_name            = azurerm_api_management_api.catcar.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "DELETE catch all"
  method              = "DELETE"
  url_template        = "{*path}"

  template_parameter {
    name     = "path"
    type     = "string"
    required = false
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "catcar_options_catch_all" {
  operation_id        = "options-catch-all"
  api_name            = azurerm_api_management_api.catcar.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  display_name        = "OPTIONS catch all"
  method              = "OPTIONS"
  url_template        = "{*path}"

  template_parameter {
    name     = "path"
    type     = "string"
    required = false
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_policy" "catcar" {
  api_name            = azurerm_api_management_api.catcar.name
  resource_group_name = azurerm_resource_group.this.name
  api_management_name = azurerm_api_management.this.name
  xml_content         = file("${path.module}/apim-policy.xml")
  depends_on          = [azurerm_api_management_named_value.customer_jwt_signing_key, azurerm_api_management_named_value.admin_jwt_secret, azurerm_api_management_named_value.gateway_backend_key, azurerm_api_management_backend.catcar, azurerm_api_management_backend.auth_function]
}

resource "azurerm_consumption_budget_subscription" "student_credit" {
  name            = "catcar-student-budget"
  subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  amount          = var.student_credit_budget_brl
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-09-01T00:00:00Z"
    end_date   = "2028-08-31T00:00:00Z"
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 50
    threshold_type = "Actual"
    contact_emails = [var.apim_publisher_email]
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 75
    threshold_type = "Actual"
    contact_emails = [var.apim_publisher_email]
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 90
    threshold_type = "Actual"
    contact_emails = [var.apim_publisher_email]
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 100
    threshold_type = "Actual"
    contact_emails = [var.apim_publisher_email]
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 90
    threshold_type = "Forecasted"
    contact_emails = [var.apim_publisher_email]
  }
}
