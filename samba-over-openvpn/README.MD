# Samba over OpenVPN

## Context

After the introduction of lifecycle based Windows resource provision, data persistence becomes a critical thing across different lifecycle stages (which means different Windows instances). The default solution is to use an additional ESB volume and attach it to the newly provisioned Windows instances each time. However, the extra cost might be a potential concern for some users. It might be useful if there is a solution that can leverage the SMB protocol to simplify the data sharing between Sandbox workspaces and Windows resources.

It is not feasible or diffcult to directly use reverse SSH port forwarding to map the workspace's port 445 (Samba) to Windows instance's port 445, which is a reserved one in Windows Server. In this case, VPN should be in place to help the entire flow.

This README summarises a Samba over OpenVPN solution to achieve the data sharing between Sandbox workspace and Windows EC2 instances. It can also be used as a OpenVPN guide to bridge the network between them.

## Solution

The overview of this solution is:

- Establish a SSH reverse port forwarding between Sandbox workspace and Windows instance.
- use minimal OpenVPN static secret mode to establish the VPN connection between sandbox workspace (server) and Windows instance (client). The OpenVPN’s proto must be switched to TCP.
- start the Samba server on the Sandbox workspace using the tun device created by OpenVPN.
- use symbolic link or network drive to mount the essential folders in Windows

### Sandbox workspace

There are 3 parts invovled:

- SSH tunnel (reverse port forwarding)
- OpenVPN
- Samba

#### SSH tunnel

```bash
ssh -i PATH-TO-PRIVATE-PEM -N -R 1194:127.0.0.1:1194 Administrator@WINDOWS-PUBLIC-DNS-NAME
```

The private pem used here should be stored as org shared secret.

#### OpenVPN

To simplify the setup, a minimal OpenVPN setup is used: [static key](https://openvpn.net/community-resources/static-key-mini-howto/). Alternatively, TLS based mode can be used.

```bash
sudo apt install openvpn
openvpn --genkey --secret static.key
```

Save the generated static key as an org shared secret. The foreground OpenVPN process can be started as below, a corresponding configuration file can be created based on the flags.

```bash
sudo openvpn --dev tun --cipher aes-256-cbc  --ifconfig 10.8.0.1 10.8.0.2 --secret PATH-TO-STATIC-KEY --local 127.0.0.1 --proto tcp-server
```

The key things in the above command are:

- proto should be changed to `tcp`.
- cipher should be changed to something that can be supported in the target Windows OpenVPN client. e.g. `aes-256-cbc`.
- secret should be the one stored as org shared secret, this key should be copied to Windows as well.

#### Samba

```bash
sudo apt update
sudo apt install samba
```

Edit `/etc/samba/smb.conf` to use the below config:

```
[global]

   allow hosts = 10.8.0.0/24

   interfaces = 169.254.16.1/32 10.8.0.0/24 tun0

[sambashare]
   comment = Samba on Ubuntu
   path = /home/owner
   readonly = no
   browsable = yes
   guest ok = yes
   writable = yes
   force user = owner
   directory mask = 0755
   create mask = 0644
```

Then restart the service `sudo service smbd restart`.

#### Considering Snapshot

The setup for OpenVPN and Samba should be stored as a base snapshot to ease the reuse.

### Windows

To simplify the setup, we do not require user/password auth for the Samba Server. However, Windows might requires some additional configuration.

#### Adjust Windows settings

##### Enable guest access for SMB2

https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/guest-access-in-smb2-is-disabled-by-default

##### Update Firewall rules to allow 1194 TCP.

#### OpenVPN

Download the matched OpenVPN client msi and complete the installation.

Create a config file called `sandbox.ovpn` as below:

```
remote 127.0.0.1 1194
proto tcp-client
dev tun
cipher AES-256-CBC
secret PATH-TO-STATIC-KEY
ifconfig 10.8.0.2 10.8.0.1
```

And start the OpenVPN service with the above config.

#### Directories Mounting

There are two main ways:

- Symbolic link

```
mklink /d "C:\MOUNT-POINT" "\\10.8.0.1\sharefolder"
```

- Network Drive

```
net use E: \\10.8.0.1\sharefolder
```

#### AMI

The installation and/or setup for OpenVPN, system setting adjustment could be captured in the base AMI.
