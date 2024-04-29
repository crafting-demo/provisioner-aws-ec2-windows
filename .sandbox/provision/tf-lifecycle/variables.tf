variable "launch_template_name" {
  default     = "sandbox-windows-vm"
  description = "Name of the EC2 launch template for Windows."
}

variable "launch_template_version" {
  default     = "1"
  description = "Version of the EC2 launch template for Windows."
}

variable "keypair_file" {
  default     = "/run/sandbox/fs/secrets/shared/sandbox-shared.pem"
  description = "The keypair file (pem) used to provision the Windows EC2 instance. The password of the Windows requires this for decryption."
}

variable "suspended" {
  type        = bool
  description = "Flag indicate whether the Windows EC2 instance is suspended or not."
  default     = false
}

variable "ebs_availablity_zone" {
  type        = string
  description = "Availability zone for the additional ESB volume"
  default     = "us-east-2a"
}

variable "ebs_size" {
  type        = number
  description = "The size of the additional ESB volume. Unit is GB."
  default     = 10
}

variable "ebs_type" {
  type        = string
  description = "The size of the additional ESB volume."
  default     = "gp3"
}
