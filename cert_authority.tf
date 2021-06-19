locals {
  ca_key_algorithm = "RSA"
  country = "US"
  locality = "Seattle"
  province = "Washington"
}

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
  ]
}

resource "local_file" "admin_pem" {
  content = tls_locally_signed_cert.admin_cert.cert_pem
  filename = "admin.pem"
}
