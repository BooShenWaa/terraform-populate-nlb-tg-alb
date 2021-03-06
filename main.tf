terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.36"
    }
  }
}

provider "aws" {
  region = var.region
}

module "populate_nlb_tg" {
  source        = "./modules/lambda"
  lambda_name   = var.lambda_name
  alb_dns_name  = var.alb_dns_name
  nlb_tg_arn    = var.nlb_tg_arn
}