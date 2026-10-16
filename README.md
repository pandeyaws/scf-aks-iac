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

The [Deploy AKS workflow](./.github/workflows/deploy-aks.yml) currently runs
when a commit is pushed to `master` and deploys the development configuration.
The production job is commented out in the workflow, so production is not
currently deployed by CI.

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
3. Grant the GitHub Actions service principal `Contributor` on the
   subscription(s) where the clusters will be created. Separately grant it
   the **data-plane** role `Storage Blob Data Contributor` on the Terraform
   state blob container (or on the storage account if you intentionally want
   the identity to access all containers). Azure's `Contributor` role alone
   does not grant blob data access.

   For example, an Azure administrator can assign the container-scoped role
   with Azure CLI. Use the service principal's **client ID** below; the CLI
   resolves it to the corresponding service principal:

   ```powershell
   $subscriptionId = "<state-storage-subscription-id>"
   $stateResourceGroup = "<state-storage-resource-group>"
   $storageAccount = "<state-storage-account>"
   $container = "<state-container>"
   $clientId = "<github-actions-service-principal-client-id>"
   $scope = "/subscriptions/$subscriptionId/resourceGroups/$stateResourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccount/blobServices/default/containers/$container"

   az role assignment create `
     --assignee $clientId `
     --role "Storage Blob Data Contributor" `
     --scope $scope
   ```

   The person running `az role assignment create` must have permission to
   create role assignments at that scope (for example, `Owner` or `User Access
   Administrator`). Allow time for the role assignment to propagate, then
   rerun the failed workflow. If dev and production use different service
   principals, assign this role to both.
4. In GitHub repository settings, create environments named `development` and
   `production`. Add these **secrets** to each environment for the workflow's
   Azure identity:
   - `CLIENT_ID`
   - `TENANT_ID`
   - `SUBSCRIPTION_ID`

   Add these **variables** to each environment for the remote backend:
   - `TF_STATE_RESOURCE_GROUP`
   - `TF_STATE_STORAGE_ACCOUNT`
   - `TF_STATE_CONTAINER`

   The state storage values can be the same in both environments; the workflow
   uses separate `dev.tfstate` and `production.tfstate` keys. The Azure
   subscription secret must be the subscription containing the state storage
   account for backend access. Enter actual Azure values: for example,
   `TF_STATE_RESOURCE_GROUP` must be the name of the resource group containing
   the storage account, not the literal text `TF_STATE_RESOURCE_GROUP`.
5. Configure required reviewers in the GitHub `production` environment. Leave
   the `development` environment without required reviewers for automatic
   deployment.

The workflow uses OIDC for Azure authentication and Azure AD authentication
for the remote state backend. It requires no stored Azure client secret.
If backend initialization fails with `AuthorizationPermissionMismatch`, verify
that the service principal selected by `CLIENT_ID` has the `Storage Blob Data
Contributor` data role on the configured state container, and allow time for
the role assignment to propagate. The subscription-level `Contributor` role
does not grant blob data-plane access.

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
