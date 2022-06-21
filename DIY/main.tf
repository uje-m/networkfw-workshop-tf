terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  # backend "s3" {
  #   bucket         = "tf-state"
  #   key            = "networkfw/tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "terraform-up-and-running-locks"
  # }
}

provider "aws" {
  region = "ap-southeast-1"
}
