### creates CA

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

resource "local_file" "ca_key_pem" {
  content = tls_private_key.ca_root_key.private_key_pem
  filename = "${local.key_directory}/controller/ca-key.pem"
}

resource "local_file" "ca_pem" {
  content = tls_self_signed_cert.ca_root.cert_pem
  filename = "${local.key_directory}/controller/ca.pem"
}

### admin client cert

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

### kubelet client certs

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
  filename = "${local.key_directory}/worker/worker-${count.index}-key.pem"
}

resource "local_file" "worker_pem" {
  count = var.instance_count
  content = tls_locally_signed_cert.worker_cert[count.index].cert_pem
  filename = "${local.key_directory}/worker/worker-${count.index}.pem"
}

### controller manager client cert

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

### kube proxy client cert

resource "tls_private_key" "kube_proxy_key" {
  algorithm = local.ca_key_algorithm
  rsa_bits  = 2048
}

resource "tls_cert_request" "kube_proxy_request" {
  key_algorithm   = local.ca_key_algorithm
  private_key_pem = tls_private_key.kube_proxy_key.private_key_pem

  subject {
    common_name  = "system:kube-proxy"
    organization = "system:node-proxier"
    organizational_unit = "Kubernetes The Hard Way"
    country = local.country
    province = local.province
    locality = local.locality
  }
}

resource "tls_locally_signed_cert" "kube_proxy_cert" {
  cert_request_pem   = tls_cert_request.kube_proxy_request.cert_request_pem
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

resource "local_file" "kube_proxy_pem" {
  content = tls_private_key.kube_proxy_key.private_key_pem
  filename = "${local.key_directory}/kube-proxy-key.pem"
}

resource "local_file" "kube_proxy_key" {
  content = tls_locally_signed_cert.kube_proxy_cert.cert_pem
  filename = "${local.key_directory}/kube-proxy.pem"
}

### scheduler client cert

resource "tls_private_key" "scheduler_key" {
  algorithm = local.ca_key_algorithm
  rsa_bits  = 2048
}

resource "tls_cert_request" "scheduler_request" {
  key_algorithm   = local.ca_key_algorithm
  private_key_pem = tls_private_key.scheduler_key.private_key_pem

  subject {
    common_name  = "system:kube-scheduler"
    organization = "system:kube-scheduler"
    organizational_unit = "Kubernetes The Hard Way"
    country = local.country
    province = local.province
    locality = local.locality
  }
}

resource "tls_locally_signed_cert" "scheduler_cert" {
  cert_request_pem   = tls_cert_request.scheduler_request.cert_request_pem
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

resource "local_file" "scheduler_pem" {
  content = tls_private_key.scheduler_key.private_key_pem
  filename = "${local.key_directory}/kube-scheduler-key.pem"
}

resource "local_file" "scheduler_key" {
  content = tls_locally_signed_cert.scheduler_cert.cert_pem
  filename = "${local.key_directory}/kube-scheduler.pem"
}

### kubernetes api server cert

resource "tls_private_key" "api_server_key" {
  algorithm = local.ca_key_algorithm
  rsa_bits  = 2048
}

resource "tls_cert_request" "api_server_request" {
  key_algorithm   = local.ca_key_algorithm
  private_key_pem = tls_private_key.api_server_key.private_key_pem
  ip_addresses = concat(aws_instance.controller.*.private_ip, [
    aws_eip.lb_eip.public_ip,
    "10.32.0.1",
    "127.0.0.1"
  ])

  dns_names = [
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.svc.cluster.local"
  ]

  subject {
    common_name  = "kubernetes"
    organization = "Kubernetes"
    organizational_unit = "Kubernetes The Hard Way"
    country = local.country
    province = local.province
    locality = local.locality
  }
}

resource "tls_locally_signed_cert" "api_server_cert" {
  cert_request_pem   = tls_cert_request.api_server_request.cert_request_pem
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

resource "local_file" "api_server_key_pem" {
  content = tls_private_key.api_server_key.private_key_pem
  filename = "${local.key_directory}/controller/kubernetes-key.pem"
}

resource "local_file" "api_server_pem" {
  content = tls_locally_signed_cert.api_server_cert.cert_pem
  filename = "${local.key_directory}/controller/kubernetes.pem"
}

### service account key pair

resource "tls_private_key" "service_account_key" {
  algorithm = local.ca_key_algorithm
  rsa_bits  = 2048
}

resource "tls_cert_request" "service_account_request" {
  key_algorithm   = local.ca_key_algorithm
  private_key_pem = tls_private_key.service_account_key.private_key_pem

  subject {
    common_name  = "service-accounts"
    organization = "Kubernetes"
    organizational_unit = "Kubernetes The Hard Way"
    country = local.country
    province = local.province
    locality = local.locality
  }
}

resource "tls_locally_signed_cert" "service_account_cert" {
  cert_request_pem   = tls_cert_request.service_account_request.cert_request_pem
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

resource "local_file" "service_account_pem" {
  content = tls_private_key.service_account_key.private_key_pem
  filename = "${local.key_directory}/controller/service-account-key.pem"
}

resource "local_file" "service_account_key" {
  content = tls_locally_signed_cert.service_account_cert.cert_pem
  filename = "${local.key_directory}/controller/service-account.pem"
}

### put the certs on the servers

# TODO: there's probably a way to use the file provisioner instead of this local-exec scp thing i'm doing

resource "null_resource" "worker_scp" {
  count = var.instance_count
  
  triggers = {
    worker_instance_id = aws_instance.worker[count.index].id
  }

  # would be better to define the file prefixes/suffixes in local variables
  # because this copy command needs to be kept in sync with the file creation paths
  provisioner "local-exec" {
    command = "scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local_file.instance_private_key_pem.filename} ${local.key_directory}/worker/worker-${count.index}* ubuntu@${aws_instance.worker[count.index].public_dns}:~/"
  }

  depends_on = [
    local_file.worker_key_pem,
    local_file.worker_pem
  ]
}

resource "null_resource" "controller_scp" {
  count = var.instance_count
  
  triggers = {
    controller_instance_id = aws_instance.controller[count.index].id
  }

  provisioner "local-exec" {
    command = "scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local_file.instance_private_key_pem.filename} ${local.key_directory}/controller/* ubuntu@${aws_instance.controller[count.index].public_dns}:~/"
  }

  depends_on = [
    local_file.ca_key_pem,
    local_file.ca_pem,
    local_file.api_server_key_pem,
    local_file.api_server_pem,
    local_file.service_account_pem,
    local_file.service_account_key
  ]
}
