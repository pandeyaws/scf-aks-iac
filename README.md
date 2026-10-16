# scf-aks-iac

Terraform configuration and GitHub Actions workflow for deploying separate
development and production Azure Kubernetes Service (AKS) clusters.

## Environments

Environment-specific settings are committed in:

- [environments/dev.tfvars](./environments/dev.tfvars)
- [environments/production.tfvars](./environments/production.tfvars)

Each environment has its own resource group, cluster name, node size, scaling
limits, and remote Terraform state file. Adjust the region and VM sizes to
ones available in your subscription. The production defaults use more/larger
nodes and will cost more than development.

## Automatic deployment

The [Deploy AKS workflow](./.github/workflows/deploy-aks.yml) runs when a
commit is pushed to `main`. It plans and applies the development configuration
first. After that succeeds, it waits for approval in the GitHub `production`
environment before planning and applying production.

### One-time Azure setup

1. Create an Azure Storage account and private blob container for Terraform
   state. The storage account name must be globally unique. Keep the state
   account outside the resource groups managed by this Terraform configuration.
2. Create an Azure identity for GitHub Actions with workload identity
   federation (OIDC); do not use a client secret. Add federated credentials
   with issuer `https://token.actions.githubusercontent.com`, audience
   `api://AzureADTokenExchange`, and these subjects:
   - `repo:pandeyaws/scf-aks-iac:environment:development`
   - `repo:pandeyaws/scf-aks-iac:environment:production`
3. Grant the identity `Contributor` on the subscription(s) where the clusters
   will be created. Grant it `Storage Blob Data Contributor` on the state
   storage account or container. If using separate Azure identities per
   environment, configure each identity's federated credential and permissions
   accordingly.
4. In GitHub repository settings, create environments named `development` and
   `production`. Add these **variables** to each environment:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
   - `TF_STATE_RESOURCE_GROUP`
   - `TF_STATE_STORAGE_ACCOUNT`
   - `TF_STATE_CONTAINER`

   The Azure IDs select the identity and subscription for that environment.
   The state storage values can be the same in both environments; the workflow
   uses separate `dev.tfstate` and `production.tfstate` keys.
5. Configure required reviewers in the GitHub `production` environment. Leave
   the `development` environment without required reviewers for automatic
   deployment.

The workflow uses OIDC for Azure authentication and Azure AD authentication
for the remote state backend. It requires no stored Azure client secret.

## Local validation

Install Terraform 1.5 or later, then run from the repository root:

```powershell
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

For local plans or applies, first configure Azure CLI authentication and
initialize the `azurerm` backend with the storage account and state key for
the environment you intend to use. Use `environments/dev.tfvars` or
`environments/production.tfvars` with `-var-file`; never share a state key
between environments.

## Connect to a cluster

After deployment, retrieve credentials using the cluster's resource group and
name from its environment `.tfvars` file:

```powershell
az aks get-credentials --resource-group "<resource-group-name>" --name "<cluster-name>"
kubectl get nodes
```

## Clean up

To remove an environment, authenticate to its Azure subscription, initialize
the remote backend with that environment's state key, and run:

```powershell
terraform destroy -var-file="environments/dev.tfvars"
```

Use `environments/production.tfvars` and the `production.tfstate` backend key
to remove production instead. Be certain the selected state key and variable
file refer to the same environment before destroying resources.
