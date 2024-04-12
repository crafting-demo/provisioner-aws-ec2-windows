terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4"
    }
  }

  backend "local" { path = "../terraform.tfstate" }
}

data "external" "env" {
  program = ["${path.module}/../common/env.sh"]
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
