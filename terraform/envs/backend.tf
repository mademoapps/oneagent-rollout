terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "acme-demo-tfstate-mo-4821"
    key          = "web-servers.tfstate"
    region       = "us-west-2"
    use_lockfile = true # two runs can't change the same state at once
  }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      Project     = "acme-demo"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}