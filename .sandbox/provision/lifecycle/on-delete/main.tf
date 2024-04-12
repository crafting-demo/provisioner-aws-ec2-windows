terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4"
    }
  }

  backend "local" { path = "../terraform.tfstate" }
}
