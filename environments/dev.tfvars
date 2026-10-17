environment         = "dev"
resource_group_name = "rg-aks-dev-eus2-01"
location            = "eastus"
cluster_name        = "aks-cluster-dev-eus-02"
dns_prefix          = "scf-aks-dev"

node_vm_size   = "Standard_D4ds_v4"
node_count     = 2
min_node_count = 1
max_node_count = 3
