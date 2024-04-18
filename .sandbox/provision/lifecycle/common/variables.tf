variable "launch_template_name" {
  default = "sandbox-windows-vm"
}

variable "launch_template_version" {
  default = "1"
}

variable "keypair_file" {
  #default = "/run/sandbox/fs/secrets/shared/sandbox-shared.pem"
  default = "/run/sandbox/fs/secrets/shared/sandbox-temp.pem"
}
