<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_external_dns"></a> [external\_dns](#module\_external\_dns) | terraform-module/release/helm | ~> 2.0 |
| <a name="module_external_dns_pod_identity"></a> [external\_dns\_pod\_identity](#module\_external\_dns\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_values_templatefile"></a> [custom\_values\_templatefile](#input\_custom\_values\_templatefile) | Custom values templatefile to pass to the helm chart | `string` | `""` | no |
| <a name="input_custom_values_variables"></a> [custom\_values\_variables](#input\_custom\_values\_variables) | Variables for the custom values templatefile | `map(string)` | `{}` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_route53_zone_arn"></a> [route53\_zone\_arn](#input\_route53\_zone\_arn) | ARN of the Route53 zone | `string` | n/a | yes |
| <a name="input_route53_zone_name"></a> [route53\_zone\_name](#input\_route53\_zone\_name) | Name of the Route53 zone | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->