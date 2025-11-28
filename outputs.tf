output "kube_config" {
  value     = module.aks.config
  sensitive = true
}
