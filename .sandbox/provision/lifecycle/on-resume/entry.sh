#!/bin/bash

terraform init -no-color -input=false >./on-resume.log 2>&1
terraform apply --auto-approve -no-color -input=false >./on-resume.log 2>&1

jq .outputs ../terraform.tfstate

# cs restart rdp 