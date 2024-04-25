terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4"
    }
  }
}

data "external" "env" {
  program = ["${path.module}/env.sh"]
}

provider "aws" {
  default_tags {
    tags = {
      Sandbox   = data.external.env.result.sandbox_name
      SandboxID = data.external.env.result.sandbox_id
    }
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_ebs_volume" "data_volume" {
  size              = 10
  type              = "gp3"
  availability_zone = data.external.env.result.availablity_zone
}

resource "aws_instance" "vm" {
  count = var.suspended ? 0 : 1
  launch_template {
    name = var.launch_template_name
    version = var.launch_template_version
  }
  get_password_data = true
  # optional. user_data can be moved to launch template.
  user_data         = <<-EOT
    <powershell>
    # Install the OpenSSH Client
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

    # Install the OpenSSH Server
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

    # Start the sshd service
    Start-Service sshd

    Set-Service -Name sshd -StartupType 'Automatic'

    # Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
    if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
        Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
    }

    # Add the public key to the authrozied_keys file
    Add-Content -Path "C:\ProgramData\ssh\administrators_authorized_keys" "${data.external.env.result.ssh_pub}"

    # Ensure the administrators_authorized_keys file complies with the permissions requirement.
    icacls.exe ""C:\ProgramData\ssh\administrators_authorized_keys"" /inheritance:r /grant ""Administrators:F"" /grant ""SYSTEM:F""

    # Generate the init-volume.ps1 file
    @'
try {
  $disk=Get-Disk -Number 1
  if ($disk.NumberOfPartitions -eq 0) {
    Write-Host "Initializing the disk"
    Initialize-Disk -Number 1 -PartitionStyle GPT -ErrorAction Stop
    New-Partition -AssignDriveLetter -UseMaximumSize -DiskNumber 1 -ErrorAction Stop
    
    Format-Volume -FileSystem NTFS -NewFileSystemLabel DevVolume -DriveLetter D -ErrorAction Stop
  }
} catch {
  Write-Host "Error occurred: $_"
  exit 1
}
'@ | Out-File -FilePath C:\init-volume.ps1

    # Generate dev certificate
    dotnet dev-certs https -v
    </powershell>
EOT
}

resource "aws_volume_attachment" "data_volume_attachment" {
  count = var.suspended ? 0 : 1
  device_name = "/dev/xvdf"
  instance_id = aws_instance.vm[0].id
  volume_id   = aws_ebs_volume.data_volume.id
}
