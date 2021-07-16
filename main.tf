provider "aws" {
  profile = "devops-terraform-staging"
  region  = "eu-west-1"
}


# Create a VPC to launch our instances into
resource "aws_vpc" "development" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "development" {
  vpc_id = aws_vpc.development.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.development.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.development.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "development" {
  vpc_id                  = aws_vpc.development.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# A security group for the development so it is accessible
resource "aws_security_group" "development" {
  name        = "development"
  description = "Development remote machines"
  vpc_id      = aws_vpc.development.id

  # HTTP access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_spot_instance_request" "development" {
  ami                  = var.ami
  spot_price           = "0.40"
  instance_type        = var.instance_type
  key_name             = "user-key"
  wait_for_fulfillment = true

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [aws_security_group.development.id]
  subnet_id              = aws_subnet.development.id

  root_block_device {
    volume_size = 80
  }

  tags = {
    Name = "development machine"
  }
}


resource "aws_ec2_tag" "spot-instance-tag" {
  resource_id = aws_spot_instance_request.development.spot_instance_id
  key         = "Name"
  value       = "${var.username}.comptoirdubitcoin.fr"
}

resource "aws_route53_record" "dev" {
  zone_id         = "Z1MGNXOT9FXTV1"
  name            = "${var.username}.comptoirdubitcoin.fr"
  type            = "CNAME"
  ttl             = "60"
  allow_overwrite = true
  records         = [aws_spot_instance_request.development.public_dns]
}

resource "aws_key_pair" "user" {
  key_name   = "user-key"
  public_key = file(var.public_key_location)
}


resource "null_resource" "provision-machine" {
  # triggers = {
  #   always_run = "${timestamp()}"
  # }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_location)
    host        = aws_spot_instance_request.development.public_ip
    agent       = true
  }

  provisioner "file" {
    source      = var.private_key_location
    destination = "/home/ubuntu/id_rsa"
  }


  provisioner "file" {
    source      = var.public_key_location
    destination = "/home/ubuntu/id_rsa.pub"
  }

  # setup docker and user
  provisioner "remote-exec" {
    inline = [
      "sudo hostname development",
      "sudo add-apt-repository ppa:kelleyk/emacs -y",
      "sudo apt-get update",
      "sudo apt-get -y install docker.io git emacs27 ripgrep",
      "sudo usermod -aG docker $USER",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo useradd -G docker,adm,sudo -m -s /bin/bash ${var.username}",
      "sudo mkdir /home/${var.username}/.ssh",
      "sudo cp /home/ubuntu/id_rsa.pub /home/${var.username}/.ssh/authorized_keys",
      "sudo mv /home/ubuntu/id_rsa /home/${var.username}/.ssh",
      "sudo mv /home/ubuntu/id_rsa.pub /home/${var.username}/.ssh",
      "sudo chmod 0600 /home/${var.username}/.ssh/id_rsa",
      "sudo chown -R ${var.username}:${var.username} /home/${var.username}",
      "echo '${var.username} ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo",
    ]
  }
}

resource "null_resource" "provision-user" {
  triggers = {
    order = null_resource.provision-machine.id
  }

  connection {
    type        = "ssh"
    user        = var.username
    private_key = file(var.private_key_location)
    host        = aws_spot_instance_request.development.public_ip
    agent       = true
  }

  # install local doom emacs configurations
  provisioner "file" {
    source      = "/Users/stefan/.doom.d"
    destination = "/home/${var.username}"
    on_failure  = continue
  }

  # install local gitconfig configurations
  provisioner "file" {
    source      = "/Users/stefan/.gitconfig"
    destination = "/home/${var.username}/.gitconfig"
    on_failure  = continue
  }

  # install local tmux configurations
  provisioner "file" {
    source      = "/Users/stefan/.tmux.conf"
    destination = "/home/${var.username}/.tmux.conf"
    on_failure  = continue
  }

  # install .profile (from this repo)
  provisioner "file" {
    source      = ".profile"
    destination = "/home/${var.username}/.profile"
    on_failure  = continue
  }

  # install doom emacs
  provisioner "remote-exec" {
    inline = [
      "git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.emacs.d",
      "yes | ~/.emacs.d/bin/doom install",
      "mkdir Projects"
    ]
  }

  # custom script
  provisioner "remote-exec" {
    inline = [
      "sh local_custom.sh"
    ]
    on_failure = continue
  }
}
