resource "azurerm_resource_group" "aksrgname" {
  name     = var.resource_group_name
  location = var.location
}

module "keyvault" {
  source                      = "./modules/KeyVault"
  keyvault_name               = var.keyvault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  service_principal_name      = var.service_principal_name
  service_principal_object_id = "f6a8163f-66d1-45a4-b863-2632492ac346"
  service_principal_tenant_id = "1830154f-384b-4c58-a89e-002e8867da1c"
}

resource "azurerm_key_vault_secret" "secret_in_kv" {
  name         = var.client_id
  value        = var.client_secret
  key_vault_id = module.keyvault.keyvault_id

  depends_on = [
    module.keyvault
  ]
}

#create Azure Kubernetes Service
module "aks" {
  source                 = "./modules/AKSCluster/"
  service_principal_name = var.service_principal_name
  client_id              = var.client_id
  client_secret          = var.client_secret
  location               = var.location
  resource_group_name    = var.resource_group_name
  ssh_public_key         = var.ssh_public_key
  aks_cluster_name       = var.aks_cluster_name

  depends_on = [
    module.keyvault
  ]
}

resource "local_file" "kubeconfig" {
  depends_on = [module.aks]
  filename   = "./kubeconfig"
  content    = module.aks.config

}
