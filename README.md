

**Project Overview**
- **Purpose:** Deploy an Azure Kubernetes Service (AKS) cluster using modular Terraform code for a  Key Vault, and AKS Cluster.
- **Audience:** Learners who want a step-by-step Terraform + Azure experience, including local testing and CI pipeline usage.

**Repository Layout**
- `backend.tf`, `main.tf`, `provider.tf`, `variables.tf`, `outputs.tf`: top-level Terraform that wires modules together.
- `modules/KeyVault/`: creates an Azure Key Vault to store secrets.
- `modules/AKSCluster/`: creates the AKS cluster and related networking resources.
- `environments/dev/terraform.tfvars`: example environment variables used for development.
- `pipelines/deploy-aks-pipeline.yaml`: CICD pipeline for automated deploys.
- `Generate_Azure_ClientCredentials/`: helper notes to create Azure client credentials and SSH keys.

**ADO Pipeline Layout**
- Create a Variable group and add azuer client credentials. Ensure to lock sensitive secret information
- In the pipeline definition, refer that variable group and use the values from variable group for az login command in bash script. These credentials are used to execute all Terraform commands on build agent 
- Upload the generated ssh_public_keys to secured files location in variable group
- Upload the environment.tfvars files also in secured files location. This is needed as we are nto storing any tfvars files in source code

**Prerequisites**
- **Azure subscription**: You must have access to a subscription with permission to create RBAC, networking, and compute resources.
- **Local tools:** Install the following locally:
	- `az` (Azure CLI) — login and subscription management
	- `terraform` (>= 1.0 recommended)
	- `kubectl` (for verifying AKS)


**High-level Workflow**
1. Create or obtain Azure credentials (Service Principal) for Terraform.
2. Configure environment-specific `terraform.tfvars` in `environments/<env>/`.
3. Initialize and apply Terraform to create infra (Key Vault, SP, AKS).
4. Verify the AKS cluster with `kubectl`.
5. Optionally, run the provided CI pipeline (`pipelines/deploy-aks-pipeline.yaml`) for automated deploys.
6. The pipeline definition is meant to be used in Azure DevOps. Please ensure to upload 
    a. environment/dev/terraform.tfvars as a securedfile under library
    b. ssh_pub_keys as a securedfile under library
    c. Add Two pipeline level variables 
            i.  client_id
            ii. client_secret (Enable "Keep this value secret" )


**Detailed Steps (Local / Learning)**

1) Login & select subscription

```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID_OR_NAME>"
```

2) Create Service Principal (recommended for Terraform automation)

Option A — Use helper notes in `Generate_Azure_ClientCredentials/client_generate_steps.txt` to generate credentials, then store the values securely.

Option B — Create a temporary SP locally (example):

```bash
az ad sp create-for-rbac --name "tf-aks-sp-$(date +%s)" \
	--role Contributor \
	--scopes /subscriptions/<SUB_ID> \
	--sdk-auth
```

Save the JSON output securely — it contains `clientId`, `clientSecret`, `tenantId`, and `subscriptionId` used by Terraform.

3) (Optional) Create or configure Key Vault and place secrets

If you prefer to store SP secrets in Key Vault and let Terraform read them, create the Key Vault or use the `modules/KeyVault` module during Terraform apply. See `modules/KeyVault/variables.tf` for names and options.

4) Configure `terraform.tfvars`

Copy `environments/dev/terraform.tfvars` and edit values for your subscription, names, location, and any CIDR ranges. Example fields you will provide:
- `subscription_id`, `tenant_id`, `client_id`, `client_secret` (if not using managed identities)
- `resource_group_name`, `location`, `aks_cluster_name`, etc.

5) Initialize Terraform and apply

From the repo root (where `main.tf` and `backend.tf` live):

```bash
terraform init -backend-config="path=states/dev.tfstate"
terraform plan -var-file=environments/dev/terraform.tfvars -out=tfplan
terraform apply tfplan
```

Note: Backend configuration in `backend.tf` may require an Azure Storage Account and container for remote state. If using remote state, ensure the backend storage is configured and accessible.

6) Verify AKS access

After Terraform finishes, retrieve credentials and check nodes:

```bash
az aks get-credentials --resource-group <resource_group> --name <aks_cluster_name>
kubectl get nodes
kubectl get pods -A
```

7) Cleanup (if learning / temporary)

```bash
terraform destroy -var-file=environments/dev/terraform.tfvars
```

**CI/CD Pipeline Usage**
- The pipeline file is `pipelines/deploy-aks-pipeline.yaml`.
- This pipeline is written to integrate with your CI provider (update the pipeline definition to match your CI system: Azure DevOps, GitHub Actions, etc.).
- Typical pipeline steps:
	- Checkout code
	- Authenticate to Azure (using a service connection or SP credentials)
	- Run `terraform init` (with remote backend)
	- Run `terraform plan` and `terraform apply` (with stored secrets from Key Vault or CI secrets)

Tips:
- Store SP credentials in your CI's secure variables or use an Azure DevOps service connection / GitHub OIDC for better security.
- Use Key Vault integration to pull secrets at pipeline runtime rather than embedding them in pipeline files.

**Troubleshooting**
- `terraform init` fails: confirm Azure Storage backend exists and the SP has access.
- `az aks get-credentials` fails: check the resource group and AKS name outputs from Terraform.
- Permission errors: ensure the Service Principal has the required role and scope.

**Security Recommendations (learning best practices)**
- Do NOT check secrets into source control.
- Prefer managed identities or OIDC where possible instead of long-lived client secrets.
- Limit SP roles and scope to the minimum required.
- Use Key Vault for secrets and enable RBAC and purge protection as needed.

**Suggested Next Steps / Learning Exercises**
- Add a sample Kubernetes deployment and service manifests, then deploy them after AKS creation.
- Integrate GitOps: use Flux or ArgoCD to continuously deploy workloads to the AKS cluster.
- Add logging & monitoring: enable Azure Monitor for containers and forward logs to Log Analytics.

**Files to Review**
- `environments/dev/terraform.tfvars` — example variables for local runs.
- `modules/ServicePrincipal/` — how SP is created (if included in root apply).
- `modules/KeyVault/` — how Key Vault resources and secrets are managed.
- `modules/AKSCluster/` — AKS configuration and node pool definitions.

If you want, I can also:
- Run a quick local `terraform plan` check (requires Azure login and credentials).
- Update `pipelines/deploy-aks-pipeline.yaml` to a GitHub Actions workflow or Azure DevOps pipeline template.


