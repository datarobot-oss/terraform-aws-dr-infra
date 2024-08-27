# dr-terraform-infra-aws
Terraform for infrastructure required to run DataRobot in AWS.

## Usage
```
module "datarobot_infra" {
  source = "git@github.com/datarobot/dr-terraform-infra-aws"

  name     = "datarobot"
  app_fqdn = "datarobot.yourdomain.com"

  create_vpc               = true
  vpc_cidr                 = "10.7.0.0/16"
  create_dns_zone          = false
  route53_zone_id          = "<existing-route53-zone-id>"
  create_acm_certificate   = false
  acm_certificate_arn      = "<existing-acm-certificate-arn>"
  create_kms_key           = true
  create_s3_storage_bucket = true
  create_ecr_repositories  = true
  create_eks_cluster       = true
  eks_create_gpu_nodegroup = true
  create_app_irsa_role     = true

  aws_load_balancer_controller = true
  cert_manager                 = true
  cluster_autoscaler           = true
  ebs_csi_driver               = true
  external_dns                 = true
  ingress_nginx                = true
  internet_facing_ingress_lb   = true

  tags = {
    application   = "datarobot"
    environment   = "dev"
    managed-by    = "terraform"
  }
}
```

## Examples
- [Internet Facing Comprehensive](examples/internet-facing)
- [Internal](examples/internal)
- [Minimal](examples/minimal)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.62 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.62 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 4.0 |
| <a name="module_app_irsa_role"></a> [app\_irsa\_role](#module\_app\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_aws_load_balancer_controller"></a> [aws\_load\_balancer\_controller](#module\_aws\_load\_balancer\_controller) | ./modules/aws-load-balancer-controller | n/a |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | ./modules/cert-manager | n/a |
| <a name="module_cluster_autoscaler"></a> [cluster\_autoscaler](#module\_cluster\_autoscaler) | ./modules/cluster-autoscaler | n/a |
| <a name="module_dns"></a> [dns](#module\_dns) | terraform-aws-modules/route53/aws//modules/zones | ~> 3.0 |
| <a name="module_ebs_csi_driver"></a> [ebs\_csi\_driver](#module\_ebs\_csi\_driver) | ./modules/ebs-csi-driver | n/a |
| <a name="module_ecr"></a> [ecr](#module\_ecr) | terraform-aws-modules/ecr/aws | ~> 2.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 20.0 |
| <a name="module_external_dns"></a> [external\_dns](#module\_external\_dns) | ./modules/external-dns | n/a |
| <a name="module_ingress_nginx"></a> [ingress\_nginx](#module\_ingress\_nginx) | ./modules/ingress-nginx | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-aws-modules/kms/aws | ~> 3.0 |
| <a name="module_storage"></a> [storage](#module\_storage) | terraform-aws-modules/s3-bucket/aws | ~> 4.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | ARN of existing ACM certificate to use with the ingress load balancer created by the ingress\_nginx module. When specified, create\_acm\_certificate will be ignored. | `string` | `""` | no |
| <a name="input_app_fqdn"></a> [app\_fqdn](#input\_app\_fqdn) | FQDN for the Datarobot application | `string` | n/a | yes |
| <a name="input_aws_load_balancer_controller"></a> [aws\_load\_balancer\_controller](#input\_aws\_load\_balancer\_controller) | Install the aws-load-balancer-controller helm chart | `bool` | `true` | no |
| <a name="input_aws_load_balancer_controller_values"></a> [aws\_load\_balancer\_controller\_values](#input\_aws\_load\_balancer\_controller\_values) | Path to templatefile containing custom values for the aws-load-balancer-controller helm chart | `string` | `""` | no |
| <a name="input_aws_load_balancer_controller_variables"></a> [aws\_load\_balancer\_controller\_variables](#input\_aws\_load\_balancer\_controller\_variables) | Variables passed to the aws\_load\_balancer\_controller\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_cert_manager"></a> [cert\_manager](#input\_cert\_manager) | Install the cert-manager helm chart | `bool` | `true` | no |
| <a name="input_cert_manager_values"></a> [cert\_manager\_values](#input\_cert\_manager\_values) | Path to templatefile containing custom values for the cert-manager helm chart | `string` | `""` | no |
| <a name="input_cert_manager_variables"></a> [cert\_manager\_variables](#input\_cert\_manager\_variables) | Variables passed to the cert\_manager\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_cluster_autoscaler"></a> [cluster\_autoscaler](#input\_cluster\_autoscaler) | Install the cluster-autoscaler helm chart | `bool` | `true` | no |
| <a name="input_cluster_autoscaler_values"></a> [cluster\_autoscaler\_values](#input\_cluster\_autoscaler\_values) | Path to templatefile containing custom values for the cluster-autoscaler helm chart | `string` | `""` | no |
| <a name="input_cluster_autoscaler_variables"></a> [cluster\_autoscaler\_variables](#input\_cluster\_autoscaler\_variables) | Variables passed to the cluster\_autoscaler\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_create_acm_certificate"></a> [create\_acm\_certificate](#input\_create\_acm\_certificate) | Create a new ACM certificate to use with the ingress load balancer created by the ingress\_nginx module. Ignored if existing acm\_certificate\_arn is specified. DNS validation will be performed against route53\_zone\_id if specified. Otherwise, it will be performed against the public zone created by the dns module. | `bool` | `true` | no |
| <a name="input_create_app_irsa_role"></a> [create\_app\_irsa\_role](#input\_create\_app\_irsa\_role) | Create IAM role for Datarobot application service account | `bool` | `true` | no |
| <a name="input_create_dns_zone"></a> [create\_dns\_zone](#input\_create\_dns\_zone) | Create new public and private Route53 zones with domain name app\_fqdn. Ignored if an existing route53\_zone\_id is specified. | `bool` | `true` | no |
| <a name="input_create_ecr_repositories"></a> [create\_ecr\_repositories](#input\_create\_ecr\_repositories) | Create Datarobot image builder container repositories | `bool` | `true` | no |
| <a name="input_create_eks_cluster"></a> [create\_eks\_cluster](#input\_create\_eks\_cluster) | Create an EKS cluster. Ignored if an existing eks\_cluster\_name is specified. | `bool` | `true` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Create a new KMS key used for EBS volume encryption on EKS nodes. Ignored if kms\_key\_arn is specified. | `bool` | `true` | no |
| <a name="input_create_s3_storage_bucket"></a> [create\_s3\_storage\_bucket](#input\_create\_s3\_storage\_bucket) | Create a new S3 storage bucket to use for Datarobot application file storage. Ignored if an existing s3\_bucket\_id is specified. | `bool` | `true` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Create a new VPC. This variable is ignored if an existing vpc\_id is specified. | `bool` | `true` | no |
| <a name="input_ebs_csi_driver"></a> [ebs\_csi\_driver](#input\_ebs\_csi\_driver) | Install the aws-ebs-csi-driver helm chart | `bool` | `true` | no |
| <a name="input_ebs_csi_driver_values"></a> [ebs\_csi\_driver\_values](#input\_ebs\_csi\_driver\_values) | Path to templatefile containing custom values for the aws-ebs-csi-driver helm chart | `string` | `""` | no |
| <a name="input_ebs_csi_driver_variables"></a> [ebs\_csi\_driver\_variables](#input\_ebs\_csi\_driver\_variables) | Variables passed to the ebs\_csi\_driver\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_eks_cluster_access_entries"></a> [eks\_cluster\_access\_entries](#input\_eks\_cluster\_access\_entries) | Map of access entries to add to the cluster. Ignored if an existing eks\_cluster\_name is specified or create\_eks\_cluster is false. | `any` | `{}` | no |
| <a name="input_eks_cluster_endpoint_public_access"></a> [eks\_cluster\_endpoint\_public\_access](#input\_eks\_cluster\_endpoint\_public\_access) | Indicates whether or not the Amazon EKS public API server endpoint is enabled | `bool` | `true` | no |
| <a name="input_eks_cluster_endpoint_public_access_cidrs"></a> [eks\_cluster\_endpoint\_public\_access\_cidrs](#input\_eks\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of existing EKS cluster. When specified, create\_eks\_cluster will be ignored. | `string` | `""` | no |
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | EKS cluster version. Ignored if an existing eks\_cluster\_name is specified or create\_eks\_cluster is false. | `string` | `"1.30"` | no |
| <a name="input_eks_create_gpu_nodegroup"></a> [eks\_create\_gpu\_nodegroup](#input\_eks\_create\_gpu\_nodegroup) | Whether to create a nodegroup with GPU instances. Ignored if an existing eks\_cluster\_name is specified or create\_eks\_cluster is false. | `bool` | `false` | no |
| <a name="input_eks_gpu_nodegroup_desired_size"></a> [eks\_gpu\_nodegroup\_desired\_size](#input\_eks\_gpu\_nodegroup\_desired\_size) | Desired number of nodes in the GPU node group. Ignored if an existing eks\_cluster\_name is specified or create\_eks\_cluster is false. | `number` | `1` | no |
| <a name="input_eks_gpu_nodegroup_instance_types"></a> [eks\_gpu\_nodegroup\_instance\_types](#input\_eks\_gpu\_nodegroup\_instance\_types) | Instance types used for the primary node group. Ignored if an existing eks\_cluster\_name is specified or create\_eks\_cluster is false. | `list(string)` | <pre>[<br>  "g4dn.2xlarge"<br>]</pre> | no |
| <a name="input_eks_gpu_nodegroup_max_size"></a> [eks\_gpu\_nodegroup\_max\_size](#input\_eks\_gpu\_nodegroup\_max\_size) | Maximum number of nodes in the GPU node group. Ignored if an existing eks\_cluster\_name is specified or create\_eks\_cluster is false. | `number` | `3` | no |
| <a name="input_eks_gpu_nodegroup_min_size"></a> [eks\_gpu\_nodegroup\_min\_size](#input\_eks\_gpu\_nodegroup\_min\_size) | Minimum number of nodes in the GPU node group. Ignored if an existing eks\_cluster\_name is specified or create\_eks\_cluster is false. | `number` | `1` | no |
| <a name="input_eks_primary_nodegroup_desired_size"></a> [eks\_primary\_nodegroup\_desired\_size](#input\_eks\_primary\_nodegroup\_desired\_size) | Desired number of nodes in the primary node group. Ignored if an existing eks\_cluster\_name is specified or create\_eks\_cluster is false. | `number` | `6` | no |
| <a name="input_eks_primary_nodegroup_instance_types"></a> [eks\_primary\_nodegroup\_instance\_types](#input\_eks\_primary\_nodegroup\_instance\_types) | Instance types used for the primary node group. Ignored if an existing eks\_cluster\_name is specified or create\_eks\_cluster is false. | `list(string)` | <pre>[<br>  "r6i.4xlarge"<br>]</pre> | no |
| <a name="input_eks_primary_nodegroup_max_size"></a> [eks\_primary\_nodegroup\_max\_size](#input\_eks\_primary\_nodegroup\_max\_size) | Maximum number of nodes in the primary node group. Ignored if an existing eks\_cluster\_name is specified or create\_eks\_cluster is false. | `number` | `10` | no |
| <a name="input_eks_primary_nodegroup_min_size"></a> [eks\_primary\_nodegroup\_min\_size](#input\_eks\_primary\_nodegroup\_min\_size) | Minimum number of nodes in the primary node group. Ignored if an existing eks\_cluster\_name is specified or create\_eks\_cluster is false. | `number` | `5` | no |
| <a name="input_eks_subnet_ids"></a> [eks\_subnet\_ids](#input\_eks\_subnet\_ids) | List of existing subnet IDs to be used for the EKS cluster. Ignored if existing vpc\_id is not specified. Ensure the subnets adhere to VPC requirements and considerations https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html. | `list(string)` | `[]` | no |
| <a name="input_external_dns"></a> [external\_dns](#input\_external\_dns) | Install the external-dns helm chart | `bool` | `true` | no |
| <a name="input_external_dns_values"></a> [external\_dns\_values](#input\_external\_dns\_values) | Path to templatefile containing custom values for the external-dns helm chart | `string` | `""` | no |
| <a name="input_external_dns_variables"></a> [external\_dns\_variables](#input\_external\_dns\_variables) | Variables passed to the external\_dns\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_ingress_nginx"></a> [ingress\_nginx](#input\_ingress\_nginx) | Install the ingress-nginx helm chart | `bool` | `true` | no |
| <a name="input_ingress_nginx_values"></a> [ingress\_nginx\_values](#input\_ingress\_nginx\_values) | Path to templatefile containing custom values for the ingress-nginx helm chart | `string` | `""` | no |
| <a name="input_ingress_nginx_variables"></a> [ingress\_nginx\_variables](#input\_ingress\_nginx\_variables) | Variables passed to the ingress\_nginx\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_internet_facing_ingress_lb"></a> [internet\_facing\_ingress\_lb](#input\_internet\_facing\_ingress\_lb) | Determines the type of NLB created for EKS ingress. If true, an internet-facing NLB will be created. If false, an internal NLB will be created. Ignored when ingress\_nginx is false. | `bool` | `true` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of existing KMS key used for EBS volume encryption on EKS nodes. When specified, create\_kms\_key will be ignored. | `string` | `""` | no |
| <a name="input_kubernetes_namespace"></a> [kubernetes\_namespace](#input\_kubernetes\_namespace) | Namespace where the Datarobot application will be installed. Ignored if create\_app\_irsa\_role is false. | `string` | `"dr-core"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use as a prefix for created resources | `string` | n/a | yes |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | ID of an existing route53 zone. When specified, create\_dns\_zone will be ignored. | `string` | `""` | no |
| <a name="input_s3_bucket_id"></a> [s3\_bucket\_id](#input\_s3\_bucket\_id) | ID of existing S3 storage bucket to use for Datarobot application file storage. When specified, create\_s3\_storage\_bucket will be ignored. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all created resources | `map(string)` | <pre>{<br>  "managed-by": "terraform"<br>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block to be used for the new VPC. Ignored if an existing vpc\_id is specified or create\_vpc is false. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of an existing VPC. When specified, create\_vpc and vpc\_cidr will be ignored. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_fqdn"></a> [app\_fqdn](#output\_app\_fqdn) | FQDN of the DataRobot application |
| <a name="output_app_role_arn"></a> [app\_role\_arn](#output\_app\_role\_arn) | ARN of the IAM role to be assumed by the DataRobot app service accounts |
| <a name="output_ecr_repository_urls"></a> [ecr\_repository\_urls](#output\_ecr\_repository\_urls) | URLs of the image builder repositories |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | S3 bucket name to use for DataRobot application file storage |
<!-- END_TF_DOCS -->

## Development and Contributing

If you'd like to report an issue or bug, suggest improvements, or contribute code to this project, please refer to [CONTRIBUTING.md](CONTRIBUTING.md).

# Code of Conduct

This project has adopted the Contributor Covenant for its Code of Conduct. 
See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) to read it in full.

# License

Licensed under the Apache License 2.0. 
See [LICENSE](LICENSE) to read it in full.
