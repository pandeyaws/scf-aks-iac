variable "subscription_id" {
  description = "Azure subscription ID. Leave null to use the Azure CLI or ARM_SUBSCRIPTION_ID context."
  type        = string
  default     = null
  nullable    = true
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "environment must be either dev or production."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the AKS cluster."
  type        = string
  default     = "rg-scf-aks"
}

variable "location" {
  description = "Azure region for the resource group and AKS cluster."
  type        = string
  default     = "eastus"
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = "scf-aks"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster. Must be unique within the Azure region."
  type        = string
  default     = "scf-aks"
}

variable "kubernetes_version" {
  description = "Kubernetes version. Leave null to use the default supported version in the selected region."
  type        = string
  default     = null
  nullable    = true
}

variable "node_vm_size" {
  description = "VM size for the system node pool."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "node_count" {
  description = "Initial number of nodes in the system node pool."
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of nodes when system node pool autoscaling is enabled."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes when system node pool autoscaling is enabled."
  type        = number
  default     = 3
}
