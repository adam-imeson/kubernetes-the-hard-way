# TODO: refactor this to use a map containing the config-specific values and 
# a single module with a for-each, so you don't download the same module 5 times

module "worker_kubeconfigs" {
  count = var.instance_count

  source  = "redeux/kubeconfig/kubernetes"
  version = "0.0.2"

  filename = "kubeconfigs/worker-${count.index}.kubeconfig"
  
  clusters = [
    {
      "name": "kubernetes-the-hard-way",
      "server": "https://${aws_eip.lb_eip.public_ip}:6443",
      "certificate_authority_data": base64encode(tls_self_signed_cert.ca_root.cert_pem)
    }
  ]

  contexts = [
    {
      "name": "default",
      "cluster_name": "kubernetes-the-hard-way"
      "user": "system:node:worker-${count.index}"
    }
  ]

  users = [
    {
      "name": "system:node:worker-${count.index}"
      "client_certificate_data": base64encode(tls_locally_signed_cert.worker_cert[count.index].cert_pem)
      "client_key_data": base64encode(tls_private_key.worker_key[count.index].private_key_pem)
    }
  ]
}

module "kube_proxy_kubeconfig" {
  source  = "redeux/kubeconfig/kubernetes"
  version = "0.0.2"

  filename = "kubeconfigs/kube-proxy.kubeconfig"
  
  clusters = [
    {
      "name": "kubernetes-the-hard-way",
      "server": "https://${aws_eip.lb_eip.public_ip}:6443",
      "certificate_authority_data": base64encode(tls_self_signed_cert.ca_root.cert_pem)
    }
  ]

  contexts = [
    {
      "name": "default",
      "cluster_name": "kubernetes-the-hard-way"
      "user": "system:kube-proxy"
    }
  ]

  users = [
    {
      "name": "system:kube-proxy"
      "client_certificate_data": base64encode(tls_locally_signed_cert.kube_proxy_cert.cert_pem)
      "client_key_data": base64encode(tls_private_key.kube_proxy_key.private_key_pem)
    }
  ]
}

module "kube_controller_manager_kubeconfig" {
  source  = "redeux/kubeconfig/kubernetes"
  version = "0.0.2"

  filename = "kubeconfigs/kube-controller-manager.kubeconfig"
  
  clusters = [
    {
      "name": "kubernetes-the-hard-way",
      "server": "https://127.0.0.1:6443",
      "certificate_authority_data": base64encode(tls_self_signed_cert.ca_root.cert_pem)
    }
  ]

  contexts = [
    {
      "name": "default",
      "cluster_name": "kubernetes-the-hard-way"
      "user": "system:kube-controller-manager"
    }
  ]

  users = [
    {
      "name": "system:kube-controller-manager"
      "client_certificate_data": base64encode(tls_locally_signed_cert.controller_manager_cert.cert_pem)
      "client_key_data": base64encode(tls_private_key.controller_manager_key.private_key_pem)
    }
  ]
}

module "kube_scheduler_kubeconfig" {
  source  = "redeux/kubeconfig/kubernetes"
  version = "0.0.2"

  filename = "kubeconfigs/kube-scheduler.kubeconfig"
  
  clusters = [
    {
      "name": "kubernetes-the-hard-way",
      "server": "https://127.0.0.1:6443",
      "certificate_authority_data": base64encode(tls_self_signed_cert.ca_root.cert_pem)
    }
  ]

  contexts = [
    {
      "name": "default",
      "cluster_name": "kubernetes-the-hard-way"
      "user": "system:kube-scheduler"
    }
  ]

  users = [
    {
      "name": "system:kube-scheduler"
      "client_certificate_data": base64encode(tls_locally_signed_cert.scheduler_cert.cert_pem)
      "client_key_data": base64encode(tls_private_key.scheduler_key.private_key_pem)
    }
  ]
}

module "admin_kubeconfig" {
  source  = "redeux/kubeconfig/kubernetes"
  version = "0.0.2"

  filename = "kubeconfigs/admin.kubeconfig"
  
  clusters = [
    {
      "name": "kubernetes-the-hard-way",
      "server": "https://127.0.0.1:6443",
      "certificate_authority_data": base64encode(tls_self_signed_cert.ca_root.cert_pem)
    }
  ]

  contexts = [
    {
      "name": "default",
      "cluster_name": "kubernetes-the-hard-way"
      "user": "admin"
    }
  ]

  users = [
    {
      "name": "admin"
      "client_certificate_data": base64encode(tls_locally_signed_cert.admin_cert.cert_pem)
      "client_key_data": base64encode(tls_private_key.admin_key.private_key_pem)
    }
  ]
}

resource "null_resource" "worker_kubeconfig_scp" {
  count = var.instance_count
  
  triggers = {
    worker_instance_id = aws_instance.worker[count.index].id
  }

  # would be better to define the file prefixes/suffixes in local variables
  # because this copy command needs to be kept in sync with the file creation paths
  provisioner "local-exec" {
    command = "scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local_file.instance_private_key_pem.filename} ${module.worker_kubeconfigs[count.index].kubeconfig_path} ${module.kube_proxy_kubeconfig.kubeconfig_path} ubuntu@${aws_instance.worker[count.index].public_dns}:~/"
  }

  depends_on = [
    module.worker_kubeconfigs,
    module.kube_proxy_kubeconfig
  ]
}

resource "null_resource" "controller_kubeconfig_scp" {
  count = var.instance_count
  
  triggers = {
    controller_instance_id = aws_instance.controller[count.index].id
  }

  provisioner "local-exec" {
    command = "scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local_file.instance_private_key_pem.filename} ${module.admin_kubeconfig.kubeconfig_path} ${module.kube_scheduler_kubeconfig.kubeconfig_path} ${module.kube_controller_manager_kubeconfig.kubeconfig_path} ubuntu@${aws_instance.controller[count.index].public_dns}:~/"
  }

  depends_on = [
    module.kube_controller_manager_kubeconfig,
    module.kube_scheduler_kubeconfig,
    module.admin_kubeconfig
  ]
}
