provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = var.environment_name
      Owner       = "Kerol"
      Project     = "nginxdemo"
    }
  }
}

