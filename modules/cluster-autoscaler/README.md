<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_autoscaler"></a> [cluster\_autoscaler](#module\_cluster\_autoscaler) | terraform-module/release/helm | ~> 2.0 |
| <a name="module_cluster_autoscaler_pod_identity"></a> [cluster\_autoscaler\_pod\_identity](#module\_cluster\_autoscaler\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_values_templatefile"></a> [custom\_values\_templatefile](#input\_custom\_values\_templatefile) | Custom values templatefile to pass to the helm chart | `string` | `""` | no |
| <a name="input_custom_values_variables"></a> [custom\_values\_variables](#input\_custom\_values\_variables) | Variables for the custom values templatefile | `map(string)` | `{}` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->