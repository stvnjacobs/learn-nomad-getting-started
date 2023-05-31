variable "name" {
  description = "Prefix used to name various infrastructure components. Alphanumeric characters only."
  default     = "nomad"
}

variable "region" {
  description = "The Akamai Cloud region to deploy to."
}

variable "allowlist_ip" {
  description = "IP to allow access for the security groups (set 0.0.0.0/0 for world)"
  default     = "0.0.0.0/0"
}

variable "server_instance_type" {
  description = "The Akamai Cloud instance type to use for servers."
  default     = "g6-nanode-1"
}

variable "client_instance_type" {
  description = "The Akamai Cloud instance type to use for clients."
  default     = "g6-nanode-1"
}

variable "server_count" {
  description = "The number of servers to provision."
  default     = "3"
}

variable "client_count" {
  description = "The number of clients to provision."
  default     = "2"
}

variable "root_block_device_size" {
  description = "The volume size of the root block device."
  default     = 16
}

variable "nomad_version" {
  description = "The version of the Nomad binary to install."
  default     = "1.5.0"
}
