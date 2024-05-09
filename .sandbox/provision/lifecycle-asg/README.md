# Lifecyle based solution with ASG enabled

This solution offers a lifecycle based resource managed. With ASG being enabled, a resource could be provisioned much  faster during `create` and `resume` stages.

## Prerequisitions

### Launch Template
An EC2 launch template with proper user-data must be created first. Unlike the general Terraform solution, the instances within ASG are provisioned before being claimed. Some initial provisioning script must be provided in the launch template.

### ASG
To simplify the management of all instances from ASG, all instances provisioned in ASG should be tagged with `sandbox-asg: true` or something simlar (this is a configurable variable, see the next section). This tag can be further used to tidy up the leaked and/or orphaned instances (if needed).

### Template
Please refer to `sample-template.yaml`.

## Variables

The below variables can be injected to the sandbox template to override the default values. 

- `DEVICE_NAME`: The additional EBS volume will be mounted to the EC2 instance as a device, of which the name is specified. The default value is `xvdf`, as suggested by https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/device_naming.html.
- `ASG_NAME`: The name of the ASG, from which the EC2 instance is claimed and detached.
- `SANDBOX_NAME_TAG`: This is part of the ASG configuration, all instances in the ASG or claimed from the ASG will have this tag. The default value is `sandbox-asg`.
- `SANDBOX_ID_TAG`: All claimed EC2 instances will be tagged with the ID of the current Sandbox. The tag name is specified by `SANDBOX_ID_TAG`. The default value `SandboxManaged-SandboxID`.
- `SANDBOX_ASG_TAG`: All claimed EC2 instances will be tagged with the ID of the current Sandbox. The tag name is specified by `SANDBOX_NAME_TAG`. The default value `SandboxManaged-SandboxNAME`.




