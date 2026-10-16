output "resource_group_name" {
  description = "Resource group containing the AKS cluster."
  value       = azurerm_resource_group.aks.name
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.id
}

output "kube_config_command" {
  description = "Azure CLI command to retrieve the cluster credentials."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}
