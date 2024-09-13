# DataRobot amenities sub-module
This module contains helm charts which can be installed in an EKS cluster and provide required functionality for a DataRobot installation.

## Usage
```
module "datarobot_amenities" {
  source = "datarobot-oss/dr-infra/aws//modules/amenities"

  eks_cluster_name = module.datarobot_infra.eks_cluster_name
  vpc_id           = local.vpc_id

  install_cluster_autoscaler           = true
  install_ebs_csi_driver               = true
  ebs_csi_driver_kms_arn               = local.kms_key_arn
  install_aws_load_balancer_controller = true
  install_ingress_nginx                = true
  ingress_nginx_acm_certificate_arn    = local.acm_certificate_arn
  ingress_nginx_internet_facing        = false
  install_cert_manager                 = true
  cert_manager_hosted_zone_arns        = [local.route53_zone_arn]
  install_external_dns                 = true
  external_dns_hosted_zone_arn         = local.route53_zone_arn
  external_dns_hosted_zone_id          = local.route53_zone_id
  external_dns_hosted_zone_name        = local.domain_name

  tags = {
    application   = "datarobot"
    environment   = "dev"
    managed-by    = "terraform"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.30 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.30 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_load_balancer_controller"></a> [aws\_load\_balancer\_controller](#module\_aws\_load\_balancer\_controller) | terraform-module/release/helm | ~> 2.0 |
| <a name="module_aws_load_balancer_controller_pod_identity"></a> [aws\_load\_balancer\_controller\_pod\_identity](#module\_aws\_load\_balancer\_controller\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 1.0 |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | terraform-module/release/helm | ~> 2.0 |
| <a name="module_cert_manager_pod_identity"></a> [cert\_manager\_pod\_identity](#module\_cert\_manager\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 1.0 |
| <a name="module_cluster_autoscaler"></a> [cluster\_autoscaler](#module\_cluster\_autoscaler) | terraform-module/release/helm | ~> 2.0 |
| <a name="module_cluster_autoscaler_pod_identity"></a> [cluster\_autoscaler\_pod\_identity](#module\_cluster\_autoscaler\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 1.0 |
| <a name="module_ebs_csi_driver"></a> [ebs\_csi\_driver](#module\_ebs\_csi\_driver) | terraform-module/release/helm | 2.8.1 |
| <a name="module_ebs_csi_driver_pod_identity"></a> [ebs\_csi\_driver\_pod\_identity](#module\_ebs\_csi\_driver\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 1.0 |
| <a name="module_external_dns"></a> [external\_dns](#module\_external\_dns) | terraform-module/release/helm | ~> 2.0 |
| <a name="module_external_dns_pod_identity"></a> [external\_dns\_pod\_identity](#module\_external\_dns\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 1.0 |
| <a name="module_ingress_nginx"></a> [ingress\_nginx](#module\_ingress\_nginx) | terraform-module/release/helm | ~> 2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_load_balancer_controller_values"></a> [aws\_load\_balancer\_controller\_values](#input\_aws\_load\_balancer\_controller\_values) | Path to templatefile containing custom values for the aws-load-balancer-controller helm chart | `string` | `""` | no |
| <a name="input_aws_load_balancer_controller_variables"></a> [aws\_load\_balancer\_controller\_variables](#input\_aws\_load\_balancer\_controller\_variables) | Variables passed to the aws\_load\_balancer\_controller\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_cert_manager_hosted_zone_arns"></a> [cert\_manager\_hosted\_zone\_arns](#input\_cert\_manager\_hosted\_zone\_arns) | Route53 hosted zone ARNs to allow Cert manager to manage records | `list(string)` | `[]` | no |
| <a name="input_cert_manager_values"></a> [cert\_manager\_values](#input\_cert\_manager\_values) | Path to templatefile containing custom values for the cert-manager helm chart | `string` | `""` | no |
| <a name="input_cert_manager_variables"></a> [cert\_manager\_variables](#input\_cert\_manager\_variables) | Variables passed to the cert\_manager\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_cluster_autoscaler_values"></a> [cluster\_autoscaler\_values](#input\_cluster\_autoscaler\_values) | Path to templatefile containing custom values for the cluster-autoscaler helm chart | `string` | `""` | no |
| <a name="input_cluster_autoscaler_variables"></a> [cluster\_autoscaler\_variables](#input\_cluster\_autoscaler\_variables) | Variables passed to the cluster\_autoscaler\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_ebs_csi_driver_kms_arn"></a> [ebs\_csi\_driver\_kms\_arn](#input\_ebs\_csi\_driver\_kms\_arn) | ARN of the KMS key used to encrypt EBS volumes | `string` | n/a | yes |
| <a name="input_ebs_csi_driver_values"></a> [ebs\_csi\_driver\_values](#input\_ebs\_csi\_driver\_values) | Path to templatefile containing custom values for the aws-ebs-csi-driver helm chart | `string` | `""` | no |
| <a name="input_ebs_csi_driver_variables"></a> [ebs\_csi\_driver\_variables](#input\_ebs\_csi\_driver\_variables) | Variables passed to the ebs\_csi\_driver\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_external_dns_hosted_zone_arn"></a> [external\_dns\_hosted\_zone\_arn](#input\_external\_dns\_hosted\_zone\_arn) | Route53 hosted zone ARN to allow external-dns to manage records | `string` | `""` | no |
| <a name="input_external_dns_hosted_zone_id"></a> [external\_dns\_hosted\_zone\_id](#input\_external\_dns\_hosted\_zone\_id) | Route53 hosted zone ID to pass as a zoneFilter to the external-dns helm chart | `string` | `""` | no |
| <a name="input_external_dns_hosted_zone_name"></a> [external\_dns\_hosted\_zone\_name](#input\_external\_dns\_hosted\_zone\_name) | Route53 hosted zone name to pass as a domainFilter to the external-dns helm chart | `string` | `""` | no |
| <a name="input_external_dns_values"></a> [external\_dns\_values](#input\_external\_dns\_values) | Path to templatefile containing custom values for the external-dns helm chart | `string` | `""` | no |
| <a name="input_external_dns_variables"></a> [external\_dns\_variables](#input\_external\_dns\_variables) | Variables passed to the external\_dns\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_ingress_nginx_acm_certificate_arn"></a> [ingress\_nginx\_acm\_certificate\_arn](#input\_ingress\_nginx\_acm\_certificate\_arn) | ARN of the certificate to use with the ingress NLB | `string` | n/a | yes |
| <a name="input_ingress_nginx_internet_facing"></a> [ingress\_nginx\_internet\_facing](#input\_ingress\_nginx\_internet\_facing) | Connect to the DataRobot application via an internet-facing load balancer. If dns is enabled, create a public route53 zone | `bool` | `true` | no |
| <a name="input_ingress_nginx_values"></a> [ingress\_nginx\_values](#input\_ingress\_nginx\_values) | Path to templatefile containing custom values for the ingress-nginx helm chart. | `string` | `""` | no |
| <a name="input_ingress_nginx_variables"></a> [ingress\_nginx\_variables](#input\_ingress\_nginx\_variables) | Variables passed to the ingress\_nginx\_values templatefile | `map(string)` | `{}` | no |
| <a name="input_install_aws_load_balancer_controller"></a> [install\_aws\_load\_balancer\_controller](#input\_install\_aws\_load\_balancer\_controller) | Install the aws-load-balancer-controller helm chart to use AWS Network Load Balancers as ingress to the EKS cluster | `bool` | `true` | no |
| <a name="input_install_cert_manager"></a> [install\_cert\_manager](#input\_install\_cert\_manager) | Install the cert-manager helm chart to manage certificates within the EKS cluster | `bool` | `true` | no |
| <a name="input_install_cluster_autoscaler"></a> [install\_cluster\_autoscaler](#input\_install\_cluster\_autoscaler) | Install the cluster-autoscaler helm chart to enable horizontal autoscaling of the EKS cluster nodes | `bool` | `true` | no |
| <a name="input_install_ebs_csi_driver"></a> [install\_ebs\_csi\_driver](#input\_install\_ebs\_csi\_driver) | Install the aws-ebs-csi-driver helm chart to enable use of EBS for Kubernetes persistent volumes | `bool` | `true` | no |
| <a name="input_install_external_dns"></a> [install\_external\_dns](#input\_install\_external\_dns) | Install the external-dns helm chart to manage DNS records for EKS ingress and service resources | `bool` | `true` | no |
| <a name="input_install_ingress_nginx"></a> [install\_ingress\_nginx](#input\_install\_ingress\_nginx) | Install the ingress-nginx helm chart to use as the ingress controller for the EKS cluster | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
