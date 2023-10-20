output "public_ip" {
  description = "vm public ip address"
  value       = module.cvm.public_ip
}

output "kube_config" {
  description = "kubeconfig"
  value       = "${path.module}/config.yaml"
}

output "cvm_password" {
  description = "vm password"
  value       = var.password
}

output "harbor_url" {
  value = "https://harbor.${var.prefix}.${var.domain}"
}

output "harbor_login_info" {
  value = "Username: admin, Password: Harbor12345"
}
