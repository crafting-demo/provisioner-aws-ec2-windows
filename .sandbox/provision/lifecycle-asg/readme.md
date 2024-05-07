# Lifecyle based solution with ASG enabled

This solution offers a lifecycle based resource managed. With ASG being enabled, a resource could be provisioned much  faster during `create` and `resume` stages.

## Prerequisitions

### Launch Template
An EC2 launch template with proper user-data must be created first. Unlike the general Terraform solution, the instances within ASG are provisioned before being claimed. Some initial provisioning script must be provided in the launch template.

### ASG
To simplify the management of all instances from ASG, all instances provisioned in ASG should be tagged with `sandbox-asg: true`. This tag can be further used to tidy up the leaked and/or orphaned instances (if needed).

### Template
Please refer to `sample-template.yaml`.

