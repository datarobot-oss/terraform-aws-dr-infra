<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ingress_nginx"></a> [ingress\_nginx](#module\_ingress\_nginx) | terraform-module/release/helm | ~> 2.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | ARN of the certificate to use with the ingress NLB | `string` | n/a | yes |
| <a name="input_app_fqdn"></a> [app\_fqdn](#input\_app\_fqdn) | Hostname to expose the app on | `string` | n/a | yes |
| <a name="input_custom_values_templatefile"></a> [custom\_values\_templatefile](#input\_custom\_values\_templatefile) | Custom values templatefile to pass to the helm chart | `string` | `""` | no |
| <a name="input_custom_values_variables"></a> [custom\_values\_variables](#input\_custom\_values\_variables) | Variables for the custom values templatefile | `map(string)` | `{}` | no |
| <a name="input_public"></a> [public](#input\_public) | Connect to the DataRobot application via an internet-facing load balancer. If dns is enabled, create a public route53 zone | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->