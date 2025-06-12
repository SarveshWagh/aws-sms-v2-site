terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.2"
    }
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.42"
    }
  }
}

provider "aws" {
  region     = "eu-north-1"
}

provider "volterra" {
  api_p12_file = var.api_p12_file
  url          = var.api_url
}