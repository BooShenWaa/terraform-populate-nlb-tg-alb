variable "lambda_name" {
  type        = string
  description = "Name tag of the lambda function"
  default     = "populate_NLB_TG_with_ALB"
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

