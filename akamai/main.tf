terraform {
  required_version = ">= 0.12"
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.3.0"
    }
  }
}

provider "linode" {}

locals {
  retry_join = "provider=linode tag_name=nomad:auto-join"
}

resource "linode_firewall" "nomad_server" {
  label = "${var.name}-server"

  inbound {
    label    = "accept-icmp"
    action   = "ACCEPT"
    protocol = "ICMP"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "accept-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "accept-nomad-ui"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "4646"
    ipv4     = [var.allowlist_ip]
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
}

resource "linode_firewall" "nomad_client" {
  label = "${var.name}-client"

  inbound {
    label    = "accept-icmp"
    action   = "ACCEPT"
    protocol = "ICMP"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "accept-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "accept-app"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "5000"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
}

# TODO: use ubuntu 16.04 image with cloud-init support
data "linode_image" "ubuntu-1604" {
  #id = "linode/ubuntu16.04lts"
  id = "linode/ubuntu22.10-cloud-init"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Uncomment the private key resource below if you want to SSH to any of the instances
# Run init and apply again after uncommenting:
# terraform init && terraform apply
# Then SSH with the tf-key.pem file:
# ssh -i tf-key.pem root@INSTANCE_IP_ADDRESS

resource "local_file" "tf_pem" {
  filename        = "${path.module}/tf-key.pem"
  content         = tls_private_key.private_key.private_key_pem
  file_permission = "0400"
}

resource "linode_token" "server" {
  label  = "${var.name}-server-${count.index}"
  scopes = "linodes:read_only"
  expiry = "2100-01-02T03:04:05Z"
  count  = var.server_count
}

resource "linode_instance" "server" {
  image  = data.linode_image.ubuntu-1604.id
  type   = var.server_instance_type
  label  = "${var.name}-server-${count.index}"
  region = var.region
  count  = var.server_count

  # TODO: random root pass
  root_pass       = "ThisIsNotSecure123!"
  authorized_keys = [chomp(tls_private_key.private_key.public_key_openssh)]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = tls_private_key.private_key.private_key_openssh
    host        = self.ip_address
  }

  tags = [
    "nomad:auto-join",
    "nomad:server"
  ]

  # TODO: VLAN networking
  private_ip = true

  provisioner "remote-exec" {
    inline = ["sudo mkdir -p /ops", "sudo chmod 777 -R /ops"]
  }

  provisioner "file" {
    source      = "../shared"
    destination = "/ops"
  }

  metadata {
    user_data = base64encode(templatefile("../shared/data-scripts/user-data-server.sh", {
      server_count  = var.server_count
      region        = var.region
      cloud_env     = "akamai"
      retry_join    = local.retry_join
      nomad_version = var.nomad_version
      linode_url    = "https://api.dev.linode.com"
      linode_token  = linode_token.server[count.index].token
    }))
  }
}

# TODO: block devices
