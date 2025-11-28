variable "resource_group_name" {
  type        = string
  description = "resource group name"

}

variable "location" {
  type    = string
  default = "canadacentral"
}

variable "service_principal_name" {
  type = string
}

variable "keyvault_name" {
  type = string
}

variable "aks_cluster_name" {
  type = string

}
variable "subscription_id" {
  type    = string
  default = "5e9e32c1-3ce2-41c4-958f-82dcdfb98924"
}

variable "tenant_id" {
  type    = string
  default = "1830154f-384b-4c58-a89e-002e8867da1c"

}

variable "ssh_public_key" {}

variable "client_id" {

}

variable "client_secret" {

}
