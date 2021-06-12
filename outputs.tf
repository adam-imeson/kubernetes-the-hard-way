output "instance_key_pair_name" {
  value = aws_key_pair.kubernetes.key_name
}

output "instance_private_key" {
  value = nonsensitive(tls_private_key.kubernetes.private_key_pem)
}
