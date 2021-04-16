# Auto populate NLB target group with ALB IPs

This IaC is designed to be run in an existing VPC.

Prerequisites:

- A Network Load Balancer
- An internal Application Load Balancer
- Both the internal Application Load Balancer and Network Load Balancer need to be in the same Availability Zones
- An IP-address-based target group for the NLB (This is the group the lambda funtion will update)

Deploys the following:

- Lambda Function & Trigger
- IAM Policy & Role
- S3 Bucket

## Inputs

Update terraform.tfvars prior to running `terraform apply`

| Name         | Description                                   | Type   | Default | Required |
| ------------ | --------------------------------------------- | ------ | ------- | -------- |
| alb_dns_name | DNS name of the Application Load Balancer     | string |         | yes      |
| nlb_tg_arn   | ARN of the Network Load Balancer Target Group | string |         | yes      |

## Lambda

Steps the lambda function takes:

1. Query DNS for IP addresses in use by the ALB. Upload the results (NEW IP LIST) to the S3 bucket.
2. Call the describe-target-health API action to get a list of the IP addresses that are currently registered to the NLB (REGISTERED LIST).
3. Download previous IP address list (OLD LIST). If it is the first invocation of the Lambda function, this IP address list is empty.
4. Publish the NEW LIST to the Lambda function’s CloudWatch Logs log stream. This can be used later to search for IP addresses that were used by the ALB.
5. Update the CloudWatch metric that tracks the number of the internal ALB IP addresses (created on first invocation). This metric shows how many IP addresses changed since the last run. This is useful if you want to track how many IP addresses your load balancer had over time. You can disable it by setting CW_METRIC_FLAG_IP_COUNT to “false”. Here is an example of the CloudWatch metric, showing that the number of IP addresses of the ALB changed from 20 IP addresses to 24 then to 28.
6. Register IP addresses to the NLB that are in NEW LIST but missing from the OLD LIST or REGISTERED LIST.
7. Deregister IP addresses in the OLD LIST that are missing from the NEW LIST.
