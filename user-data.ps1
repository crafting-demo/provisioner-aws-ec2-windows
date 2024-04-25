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
Add-Content -Path "C:\ProgramData\ssh\administrators_authorized_keys" "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuuD7OlxvPNh0WJMPMPN86dpo6bJlkzsKFTXy3PL3a08iqItmXMuCtJAajOHbCN0RBlFACPkmDI7UdBYbSQOOeyst0VhzycA2RA+zAyMnH/MxHXO6s6SGPQLcxaB+MtbTXh69VOKAkFUNH9GMnF+zcD5E4F/sbKf3FHy+uqgDbxTGjnS7Sv11ILVJ+ovV8anxl/CoKlwBuIwqa+r1+b8pehIPOhgtPh+sj2p7/VatHdTUFXlkWkrknP/XAkt27dbGd0eD54SymIAaPXd72Q1nGYe5QgYeGmuG6KHLpAijoXNXGcd/ktqzPDjv9BmicqwOU/kixgTg0Fi9cCAXWuR7L"

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