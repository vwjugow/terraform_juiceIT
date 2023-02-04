terraform {
  cloud {
    organization = "JuiceIT"
    workspaces {
      name = "dev-portfolio"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}
