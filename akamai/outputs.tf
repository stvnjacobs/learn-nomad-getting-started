output "nomad_ip" {
  value = "http://${linode_instance.server[0].ip_address}:4646/ui"
}

output "IP_Addresses" {
  value = <<CONFIGURATION

It will take a little bit for setup to complete and the UI to become available.
Once it is, you can access the Nomad UI at:

http://${linode_instance.server[0].ip_address}:4646/ui

Set the Nomad address, run the bootstrap, export the management token, set the token variable, and test connectivity:

export NOMAD_ADDR=http://${linode_instance.server[0].ip_address}:4646 && \
nomad acl bootstrap | grep -i secret | awk -F "=" '{print $2}' | xargs > nomad-management.token && \
export NOMAD_TOKEN=$(cat nomad-management.token) && \
nomad server members

Copy the token value and use it to log in to the UI:

cat nomad-management.token
CONFIGURATION
}
