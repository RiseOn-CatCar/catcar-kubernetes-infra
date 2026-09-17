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

variable "resource_group_name" {
  description = "Resource group containing the monitored CatCar resources."
  type        = string
}

variable "location" {
  description = "Azure region of the action group."
  type        = string
}

variable "aks_cluster_id" {
  description = "AKS cluster resource ID."
  type        = string
}

variable "application_insights_id" {
  description = "Application Insights component resource ID."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID."
  type        = string
}

variable "health_probe_url" {
  description = "Public HTTPS endpoint for the CatCar readiness probe."
  type        = string
}

variable "alert_email" {
  description = "Email address receiving monitor alerts."
  type        = string
}

resource "azurerm_monitor_action_group" "catcar" {
  name                = "ag-catcar-operations"
  resource_group_name = var.resource_group_name
  short_name          = "catcarops"

  email_receiver {
    name                    = "operations"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "os_processing_failures" {
  name                = "catcar-os-processing-failures"
  resource_group_name = var.resource_group_name
  location            = var.location
  scopes              = [var.log_analytics_workspace_id]
  description         = "Triggers when processing a work order records an error."
  severity            = 1
  enabled             = true

  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"

  criteria {
    query                   = "AppTraces | where Message has 'WorkOrder' and SeverityLevel >= 3 | summarize FailureCount = count()"
    time_aggregation_method = "Total"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods              = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.catcar.id]
  }
}

resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "catcar-aks-high-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Triggers when AKS CPU usage exceeds 80 percent."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.catcar.id
  }
}

resource "azurerm_monitor_metric_alert" "high_memory" {
  name                = "catcar-aks-high-memory"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = "Triggers when AKS memory usage exceeds 85 percent."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.catcar.id
  }
}

resource "azurerm_monitor_metric_alert" "high_latency" {
  name                = "catcar-request-latency-over-two-seconds"
  resource_group_name = var.resource_group_name
  scopes              = [var.application_insights_id]
  description         = "Triggers when the average request duration exceeds two seconds."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "requests/duration"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 2000
  }

  action {
    action_group_id = azurerm_monitor_action_group.catcar.id
  }
}

resource "azurerm_application_insights_standard_web_test" "uptime" {
  name                    = "catcar-readiness-uptime"
  resource_group_name     = var.resource_group_name
  location                = var.location
  application_insights_id = var.application_insights_id
  geo_locations           = ["us-ca-sjc-azr", "us-va-ash-azr"]
  frequency               = 300
  timeout                 = 30
  enabled                 = true
  retry_enabled           = true

  request {
    url                              = var.health_probe_url
    http_verb                        = "GET"
    parse_dependent_requests_enabled = false
    follow_redirects_enabled         = false
  }

  validation_rules {
    expected_status_code = 200
  }
}

resource "azurerm_monitor_metric_alert" "uptime" {
  name                = "catcar-uptime-probe-failure"
  resource_group_name = var.resource_group_name
  scopes              = [var.application_insights_id]
  description         = "Triggers when the external readiness probe fails."
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "availabilityResults/availabilityPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99
  }

  action {
    action_group_id = azurerm_monitor_action_group.catcar.id
  }
}
