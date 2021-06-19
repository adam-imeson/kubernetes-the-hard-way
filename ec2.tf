resource "tls_private_key" "kubernetes" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kubernetes" {
  key_name = "${var.username}-key"
  public_key = tls_private_key.kubernetes.public_key_openssh
}

resource "local_file" "instance_private_key_pem" {
  content = tls_private_key.kubernetes.private_key_pem
  filename = "${local.key_directory}/${aws_key_pair.kubernetes.key_name}.pem"
}

resource "aws_instance" "controller" {
  # kubernetes controllers
  count         = var.instance_count

  ami           = data.aws_ami.ubuntu_server_20.id
  instance_type = "m5.xlarge"
  subnet_id     = aws_subnet.main_az_1_public.id
  source_dest_check = false
  key_name = aws_key_pair.kubernetes.key_name
  vpc_security_group_ids = [
    aws_security_group.main.id,
    aws_security_group.alpha.id,
    aws_security_group.internal.id
  ]

  root_block_device {
    volume_size = 200
    encrypted = true
    tags = {
    Name = "${var.username}-controller-ubuntu-${count.index}-root-volume"
    }
  }

  tags = {
    Name = "${var.username}-controller-ubuntu-${count.index}"
  }
}

resource "aws_instance" "worker" {
  # kubernetes workers
  count         = var.instance_count

  ami           = data.aws_ami.ubuntu_server_20.id
  instance_type = "m5.xlarge"
  subnet_id     = aws_subnet.main_az_1_public.id
  source_dest_check = false
  key_name = aws_key_pair.kubernetes.key_name
  vpc_security_group_ids = [
    aws_security_group.main.id,
    aws_security_group.alpha.id,
    aws_security_group.internal.id
  ]

  root_block_device {
    volume_size = 200
    encrypted = true
    tags = {
    Name = "${var.username}-worker-ubuntu-${count.index}-root-volume"
    }
  }

  tags = {
    Name = "${var.username}-worker-ubuntu-${count.index}"
  }
}
