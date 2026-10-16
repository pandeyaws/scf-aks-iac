resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_vm_size
    node_count           = var.node_count
    auto_scaling_enabled = true
    min_count            = var.min_node_count
    max_count            = var.max_node_count
    os_sku               = "Ubuntu"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  role_based_access_control_enabled = true
}
