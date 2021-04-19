variable "region" {
  type = string
  default = "eu-west-2"
}

variable "alb_dns_name" {
  type        = string
  description = "Application Load Balancer DNS Name"
}

variable "nlb_tg_arn" {
  type        = string
  description = "ARN of the NLB Target Group"
}

variable "lambda_name" {
  type        = string
  description = "Name tag of the lambda function"
  default     = "populate_NLB_TG_with_ALB"
}