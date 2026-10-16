environment         = "production"
resource_group_name = "rg-scf-aks-production"
location            = "eastus"
cluster_name        = "scf-aks-production"
dns_prefix          = "scf-aks-production"

node_vm_size   = "Standard_D4s_v5"
node_count     = 3
min_node_count = 3
max_node_count = 6
