# Lifecycle based Terraform solution

Unlike the built-in Terraform resource provider, this solution leverages Sandbox's lifecycle handlers and Terraform to provision the Windows resources in Amazon EC2. 

This solution consists of two major resources:
- EC2 instance (Windows VM)
- EBS volume (to retain the data)

During the creation of a sandbox, a Windows EC2 instance is created together with the EBS volume. The key development data should be kept in the EBS volume after its attachment and formatting. During sandbox restarting, the original EC2 instance should be re-created with the attachment of EBS volume.