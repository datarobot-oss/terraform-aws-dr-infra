## Example: private-partial
Use existing VPC, subnets, Route53 DNS zone, and ACM certificate to create the remaining infrastructure required to install the DataRobot helm charts using an internal NLB for ingress.

## Usage
```
terraform init
terraform plan
terraform apply
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.63 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_datarobot-infra"></a> [datarobot-infra](#module\_datarobot-infra) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_fqdn"></a> [app\_fqdn](#output\_app\_fqdn) | FQDN of the DataRobot application |
| <a name="output_app_role_arn"></a> [app\_role\_arn](#output\_app\_role\_arn) | ARN of the IAM role to be assumed by the DataRobot app service accounts |
| <a name="output_ecr_repository_urls"></a> [ecr\_repository\_urls](#output\_ecr\_repository\_urls) | URLs of the image builder repositories |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | S3 bucket name to use for DataRobot application file storage |
| <a name="output_s3_bucket_regional_domain"></a> [s3\_bucket\_regional\_domain](#output\_s3\_bucket\_regional\_domain) | S3 bucket region-specific domain name |
<!-- END_TF_DOCS -->