provider "aws" {
  region = "ap-south-1"
  default_tags {
    tags = {
      Environment = var.environment_name
      Owner       = "Kerol"
      Project     = "nginxdemo"
    }
  }
}

