resource "tls_private_key" "ca_root_key" {
  algorithm = local.ca_key_algorithm
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca_root" {
  key_algorithm   = local.ca_key_algorithm
  private_key_pem = tls_private_key.ca_root_key.private_key_pem
  is_ca_certificate = true

  subject {
    common_name  = "Kubernetes"
    organization = "Kubernetes"
    organizational_unit = "CA"
    country = local.country
    province = local.province
    locality = local.locality
  }

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "server_auth",
    "client_auth"
  ]
}

resource "tls_private_key" "admin_key" {
  algorithm = local.ca_key_algorithm
  rsa_bits  = 2048
}

resource "tls_cert_request" "admin_request" {
  key_algorithm   = local.ca_key_algorithm
  private_key_pem = tls_private_key.admin_key.private_key_pem

  subject {
    common_name  = "admin"
    organization = "system:masters"
    organizational_unit = "Kubernetes The Hard Way"
    country = local.country
    province = local.province
    locality = local.locality
  }
}

resource "tls_locally_signed_cert" "admin_cert" {
  cert_request_pem   = tls_cert_request.admin_request.cert_request_pem
  ca_key_algorithm   = local.ca_key_algorithm
  ca_private_key_pem = tls_private_key.ca_root_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_root.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth"
  ]
}

resource "local_file" "admin_pem" {
  content = tls_locally_signed_cert.admin_cert.cert_pem
  filename = "${local.key_directory}/admin.pem"
}

resource "tls_private_key" "worker_key" {
  count = var.instance_count
  algorithm = local.ca_key_algorithm
  rsa_bits  = 2048
}

resource "tls_cert_request" "worker_request" {
  count = var.instance_count
  key_algorithm   = local.ca_key_algorithm
  private_key_pem = tls_private_key.worker_key[count.index].private_key_pem
  ip_addresses = [
    aws_instance.worker[count.index].private_ip,
    aws_instance.worker[count.index].public_ip
  ]

  subject {
    common_name  = "system:node:worker-${count.index}"
    organization = "system:nodes"
    organizational_unit = "Kubernetes The Hard Way"
    country = local.country
    province = local.province
    locality = local.locality
  }
}

resource "tls_locally_signed_cert" "worker_cert" {
  count = var.instance_count
  cert_request_pem   = tls_cert_request.worker_request[count.index].cert_request_pem
  ca_key_algorithm   = local.ca_key_algorithm
  ca_private_key_pem = tls_private_key.ca_root_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_root.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth"
  ]
}

resource "local_file" "worker_key_pem" {
  count = var.instance_count
  content = tls_private_key.worker_key[count.index].private_key_pem
  filename = "${local.key_directory}/worker-${count.index}-key.pem"
}

resource "local_file" "worker_pem" {
  count = var.instance_count
  content = tls_locally_signed_cert.worker_cert[count.index].cert_pem
  filename = "${local.key_directory}/worker-${count.index}.pem"
}

resource "tls_private_key" "controller_manager_key" {
  algorithm = local.ca_key_algorithm
  rsa_bits  = 2048
}

resource "tls_cert_request" "controller_manager_request" {
  key_algorithm   = local.ca_key_algorithm
  private_key_pem = tls_private_key.controller_manager_key.private_key_pem

  subject {
    common_name  = "system:kube-controller-manager"
    organization = "system:kube-controller-manager"
    organizational_unit = "Kubernetes The Hard Way"
    country = local.country
    province = local.province
    locality = local.locality
  }
}

resource "tls_locally_signed_cert" "controller_manager_cert" {
  cert_request_pem   = tls_cert_request.controller_manager_request.cert_request_pem
  ca_key_algorithm   = local.ca_key_algorithm
  ca_private_key_pem = tls_private_key.ca_root_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_root.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth"
  ]
}

resource "local_file" "controller_manager_pem" {
  content = tls_private_key.controller_manager_key.private_key_pem
  filename = "${local.key_directory}/kube-controller-manager-key.pem"
}

resource "local_file" "controller_manager_key" {
  content = tls_locally_signed_cert.controller_manager_cert.cert_pem
  filename = "${local.key_directory}/kube-controller-manager.pem"
}
