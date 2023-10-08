terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "nginxdemo-statefiles"
    key    = "nginxdemo-devl.tfstate"
    region = "us-east-1"
  }
}
