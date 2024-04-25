#!/bin/bash

terraform apply -var suspended=true --auto-approve -no-color -input=false >./on-resume.log 2>&1

jq .outputs ./terraform.tfstate