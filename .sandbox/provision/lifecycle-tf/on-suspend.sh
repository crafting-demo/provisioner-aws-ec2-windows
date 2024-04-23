#!/bin/bash

terraform apply -var-file=no-vm.tfvars --auto-approve -no-color -input=false >./on-suspend.log 2>&1

jq .outputs ./terraform.tfstate