module "vpc" {
  source     = "../../../module/vpc"
  secret_id  = var.secret_id
  secret_key = var.secret_key
}

module "cvm" {
  source        = "../../../module/cvm"
  secret_id     = var.secret_id
  secret_key    = var.secret_key
  password      = var.password
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_id
  instance_name = "harbor"
}

module "cloudflare" {
  source = "../../../module/cloudflare"
  domain = var.domain
  prefix = var.prefix
  ip     = module.cvm.public_ip
  values = ["harbor"]
}

resource "null_resource" "connect_ubuntu" {
  depends_on = [module.k3s]
  connection {
    host     = module.cvm.public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = var.password
  }

  triggers = {
    script_hash = filemd5("${path.module}/init.sh")
  }

  provisioner "file" {
    destination = "/tmp/init.sh"
    source      = "${path.module}/init.sh"
  }

  provisioner "file" {
    destination = "/tmp/values.yaml"
    content = templatefile(
      "${path.module}/chart/values.yaml.tpl",
      {
        "prefix" : "${var.prefix}"
        "domain" : "${var.domain}"
      }
    )
  }

  provisioner "file" {
    destination = "/tmp/Chart.yaml"
    source      = "${path.module}/chart/Chart.yaml"
  }

  provisioner "file" {
    destination = "/tmp/cloudflare-token.yaml"
    source      = "yaml/cloudflare-token.yaml"
  }

  provisioner "file" {
    destination = "/tmp/issuer.yaml"
    source      = "yaml/issuer.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "sh /tmp/init.sh",
    ]
  }
}

module "k3s" {
  source      = "../../../module/k3s"
  public_ip   = module.cvm.public_ip
  private_ip  = module.cvm.private_ip
  server_name = "k3s-hongkong-1"
}

resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s.kube_config
  filename = "${path.module}/config.yaml"
}
