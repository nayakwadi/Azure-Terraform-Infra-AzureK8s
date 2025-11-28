variable "aks_cluster_name" {
  type = string
}

variable "location" {

}
variable "resource_group_name" {}

variable "service_principal_name" {
  type = string
}

variable "ssh_public_key" {}

variable "client_id" {}
variable "client_secret" {
  type      = string
  sensitive = true
}
