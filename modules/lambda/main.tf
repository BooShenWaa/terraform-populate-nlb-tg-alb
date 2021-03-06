terraform {
  required_version = ">= 0.14"
}

# IAM
# Creates the IAM Policy for Lambda Role

resource "aws_iam_policy" "lambda_policy" {
  name        = var.policy_name
  description = "Policy to allow lambda to update NLB target groups with ALB IPs"

  # policy      = file("./modules/lambda/nlb_TG_populate_policy.json")
  # "Resource": "*",
  policy = templatefile("./modules/lambda/nlb_TG_populate_policy.json", { bucket-arn = aws_s3_bucket.populate_nlb_tg_bucket.arn })

  tags = var.additional_tags
}

# Creates the Lambda Role 

resource "aws_iam_role" "lb-lambda-role" {
  name               = "lb-lambda-role"

  assume_role_policy = jsonencode({
    Version    = "2012-10-17"
    Statement  = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    var.additional_tags,
    {
      Name = var.role_name
    }
  )
}

# Attaches the policy to the role

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.lb-lambda-role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
# S3 BUCKET

resource "random_uuid" "nlb-tg-uuid" {
}

resource "aws_s3_bucket" "populate_nlb_tg_bucket" {
  bucket = "nlb-tg-bucket-${random_uuid.nlb-tg-uuid.result}"
  acl = "private"
  force_destroy = true

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        # kms_master_key_id = aws_kms_key.mykey.arn
        sse_algorithm     = "AES256"
      }
    }
  }

  tags = merge(
    var.additional_tags,
    {
      Description = "Bucket used to store data for the populate_NLB_TG_with_ALB Lambda function"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.populate_nlb_tg_bucket.id

  block_public_acls   = true
  block_public_policy = true
}

# LAMBDA

# Create the Lambda 

# Zip function
data "archive_file" "init"{
    type        = "zip"
    source_dir  = "./modules/lambda/populate_NLB_TG_with_ALB"
    output_path = "./modules/lambda/populate_NLB_TG_with_ALB.zip"
}

resource "aws_lambda_function" "populate_NLB_TG" {
  function_name    = var.lambda_name
  filename         = data.archive_file.init.output_path
  source_code_hash = filebase64sha256(data.archive_file.init.output_path)
  role             = aws_iam_role.lb-lambda-role.arn
  handler          = "populate_NLB_TG_with_ALB.lambda_handler"
  runtime          = "python3.6"

  environment {
    variables = {
      ALB_DNS_NAME                      = var.alb_dns_name    #
      ALB_LISTENER                      = 80
      S3_BUCKET                         = aws_s3_bucket.populate_nlb_tg_bucket.bucket
      NLB_TG_ARN                        = var.nlb_tg_arn   #
      MAX_LOOKUP_PER_INVOCATION         = "50"
      INVOCATIONS_BEFORE_DEREGISTRATION = "3"
      CW_METRIC_FLAG_IP_COUNT           = true
    }
  }

  tags = merge(
    var.additional_tags,
    {
      Name = var.lambda_name
    }
  )
}

# Schedule Lambda
resource "aws_cloudwatch_event_rule" "populate_NLB_TG" {
  name                = "populate_NLB_TG"
  description         = "Populate NLB target group with ALB eni IPs"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "populate_NLB_TG" {
  rule      = aws_cloudwatch_event_rule.populate_NLB_TG.name
  target_id = "value"
  arn       = aws_lambda_function.populate_NLB_TG.arn
}

# Allow CloudWatch to invoke lambda 
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.populate_NLB_TG.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.populate_NLB_TG.arn
}