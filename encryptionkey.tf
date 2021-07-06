# definitely the weirdest terrafrom i've ever written

data "external" "gen_key" {
  program = ["bash", "gen_encryption_key.sh"]
}

resource "local_file" "encryption_config_file" {
  content = templatefile(
      "encryption_config_template.tpl",
      {
        "ENCRYPTION_KEY" = lookup(data.external.gen_key.result, "encryption_key")
      }
    )
  filename = "${local.key_directory}/encryption-config.yaml"
}

resource "null_resource" "controller_encryptionconfig_scp" {
  count = var.instance_count
  
  triggers = {
    controller_instance_id = aws_instance.controller[count.index].id
  }

  provisioner "local-exec" {
    command = "scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local_file.instance_private_key_pem.filename} ${local_file.encryption_config_file.filename} ubuntu@${aws_instance.controller[count.index].public_dns}:~/"
  }

  depends_on = [
    local_file.encryption_config_file
  ]
}
