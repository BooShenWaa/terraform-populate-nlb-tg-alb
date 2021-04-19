variable "lambda_name" {
  type        = string
  description = "Name of the lambda function"
}

variable "alb_dns_name" {
  type        = string
  description = "Application Load Balancer DNS Name"
}

variable "nlb_tg_arn" {
  type        = string
  description = "ARN of the NLB Target Group"
}

variable "role_name" {
  type        = string
  description = "Role name for the populate_nlb_tg lambda function"
  default     = "populate_NLB_TG_with_ALB"
}

variable "policy_name" {
  type        = string
  description = "Policy name for the populate_nlb_tg lambda function role"
  default     = "populate_NLB_TG_with_ALB"
}

variable "additional_tags" {
  default = {
    terraform = true,
    creator = "CHS"
  }
  description = "Default resource tags"
  tags = map(string)
}