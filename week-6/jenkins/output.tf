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

output "jenkins_url" {
  value = "http://jenkins.${var.prefix}.${var.domain}, admin, password123"
}

output "harbor_url" {
  value = "http://harbor.${var.prefix}.${var.domain}, admin, ${var.harbor_password}"
}

output "tekton_url" {
  value = "http://tekton.${var.prefix}.${var.domain}, (not ready yet)"
}
