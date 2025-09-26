# terraform-aws-dr-infra
Terraform module to create AWS Cloud infrastructure resources required to run DataRobot.

## Usage
```
module "datarobot_infra" {
  source = "datarobot-oss/dr-infra/aws"

  name        = "datarobot"
  domain_name = "yourdomain.com"

  create_network                  = true
  network_address_space           = "10.7.0.0/16"
  create_dns_zones                = false
  existing_public_route53_zone_id = "Z06110132R7HO9BLI64XY"
  create_acm_certificate          = false
  existing_acm_certificate_arn    = "arn:aws:acm:us-east-1:000000000000:certificate/00000000-0000-0000-0000-000000000000"
  create_storage                  = true
  create_container_registry       = true
  create_kubernetes_cluster       = true
  create_app_identity             = true
  create_postgres                 = true
  create_redis                    = true
  create_mongodb                  = true

  cluster_autoscaler           = true
  descheduler                  = true
  aws_ebs_csi_driver           = true
  aws_load_balancer_controller = true
  ingress_nginx                = true
  internet_facing_ingress_lb   = true
  cert_manager                 = true
  external_dns                 = true
  nvidia_gpu_operator          = true
  metrics_server               = true

  tags = {
    application = "datarobot"
    environment = "dev"
    managed-by  = "terraform"
  }
}
```

## Examples
- [Complete](examples/complete) - Demonstrates all input variables
- [Partial](examples/partial) - Demonstrates the use of existing resources
- [Minimal](examples/minimal) - Demonstrates the minimum set of input variables needed to deploy all infrastructure

### Using an example directly from source
1. Clone the repo
```bash
git clone https://github.com/datarobot-oss/terraform-aws-dr-infra.git
```
2. Change directories into the example that best suits your needs
```bash
cd terraform-aws-dr-infra/examples/minimal
```
3. Modify `main.tf` as needed with any changes to the input variables passed to the `datarobot_infra` module
4. Run terraform commands
```bash
terraform init
terraform plan
terraform apply
terraform destroy
```


## Module Descriptions

### Network
#### Toggle
- `create_network` to create a new VPC
- `existing_vpc_id` to use an existing VPC

#### Description
Uses the [terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) module to create a new VPC with one public and private subnet per Availability Zone, a NAT gateway with an Elastic IP, and an Internet Gateway.

An interface VPC endpoint for the S3 service is created by default. More can be specified by updating the `network_private_endpoints` input variable.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowVPCActions",
            "Effect": "Allow",
            "Action": [
              "ec2:DescribeAvailabilityZones",
              "ec2:CreateVpc",
              "ec2:DescribeVpcs",
              "ec2:DescribeVpcAttribute",
              "ec2:ModifyVpcAttribute",
              "ec2:DeleteVpc",
              "ec2:CreateSubnet",
              "ec2:DescribeSubnets",
              "ec2:DeleteSubnet",
              "ec2:CreateRouteTable",
              "ec2:DescribeRouteTables",
              "ec2:AssociateRouteTable",
              "ec2:DisassociateRouteTable",
              "ec2:DeleteRouteTable",
              "ec2:CreateRoute",
              "ec2:DeleteRoute",
              "ec2:CreateInternetGateway",
              "ec2:DescribeInternetGateways",
              "ec2:AttachInternetGateway",
              "ec2:DetachInternetGateway",
              "ec2:DeleteInternetGateway",
              "ec2:CreateNatGateway",
              "ec2:DescribeNatGateways",
              "ec2:DeleteNatGateway",
              "ec2:AllocateAddress",
              "ec2:DescribeAddresses",
              "ec2:DescribeAddressesAttribute",
              "ec2:DisassociateAddress",
              "ec2:ReleaseAddress",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeSecurityGroupRules",
              "ec2:RevokeSecurityGroupEgress",
              "ec2:RevokeSecurityGroupIngress",
              "ec2:CreateNetworkAclEntry",
              "ec2:DescribeNetworkAcls",
              "ec2:DeleteNetworkAclEntry",
              "ec2:DescribeNetworkInterfaces",
              "ec2:CreateTags"
            ],
            "Resource": "*"
        }
    ]
}
```


### DNS
#### Toggle
- `create_dns_zones` to create new Route53 zones
- `existing_public_route53_zone_id` / `existing_private_route53_zone_id` to use an existing Route53 zone

#### Description
Uses the [terraform-aws-route53](https://github.com/terraform-aws-modules/terraform-aws-route53) module to create new public and/or private Route53 hosted zone with name `domain_name`.

A public Route53 zone is used by `external_dns` to create records for the DataRobot ingress resources when `internet_facing_ingress_lb` is `true`. It is also used for DNS validation when creating a new ACM certificate.

A private Route53 zone is used by `external_dns` to create records for the DataRobot ingress resources when `internet_facing_ingress_lb` is `false`.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowRoute53Actions",
            "Effect": "Allow",
            "Action": [
                "route53:CreateHostedZone",
                "route53:GetHostedZone",
                "route53:DeleteHostedZone",
                "route53:ListResourceRecordSets",
                "route53:GetChange",
                "route53:GetDNSSEC",
                "route53:ListTagsForResource",
                "route53:ChangeTagsForResource"
            ],
            "Resource": "*"
        }
    ]
}
```


### ACM
#### Toggle
- `create_acm_certificate` to create a new ACM certificate
- `existing_acm_certificate_arn` to use an existing ACM certificate

#### Description
Uses the [terraform-aws-acm](https://github.com/terraform-aws-modules/terraform-aws-acm) module to create a new ACM certificate with SANs of `domain_name` and `*.domain_name`. Validation is performed against either an existing Route53 hosted zone id specified in the `existing_public_route53_zone_id` input variable or the public zone created by the `dns` module.

This certificate will be used on the NLB deployed by the `ingress-nginx` helm chart.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowACMActions",
            "Effect": "Allow",
            "Action": [
                "acm:RequestCertificate",
                "acm:DescribeCertificate",
                "acm:DeleteCertificate",
                "acm:AddTagsToCertificate",
                "acm:ListTagsForCertificate",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}
```


### Storage
#### Toggle
- `create_storage` to create a new S3 bucket
- `existing_s3_bucket_id` to use an existing S3 bucket

#### Description
Uses the [terraform-aws-s3](https://github.com/terraform-aws-modules/terraform-aws-s3) module to create a new S3 storage bucket.

The DataRobot application will use this storage bucket for persistent file storage.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowS3Actions",
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:ListBucket",
                "s3:ListBucketVersions",
                "s3:GetBucketPolicy",
                "s3:GetBucketAcl",
                "s3:GetBucketCORS",
                "s3:GetBucketWebsite",
                "s3:GetBucketVersioning",
                "s3:GetBucketLogging",
                "s3:GetBucketRequestPayment",
                "s3:GetBucketTagging",
                "s3:PutBucketTagging",
                "s3:GetBucketPublicAccessBlock",
                "s3:PutBucketPublicAccessBlock",
                "s3:GetBucketObjectLockConfiguration",
                "s3:GetAccelerateConfiguration",
                "s3:GetLifecycleConfiguration",
                "s3:GetReplicationConfiguration",
                "s3:GetEncryptionConfiguration",
                "s3:DeleteObjectVersion",
                "s3:DeleteBucket"
            ],
            "Resource": "*"
        }
    ]
}
```


### Container Registry
#### Toggle
- `create_container_registry` to create a new Amazon Elastic Container Registry

#### Description
Uses the [terraform-aws-ecr](https://github.com/terraform-aws-modules/terraform-aws-ecr) module to create a new ECR repositories used by the DataRobot application to host custom images created by various services.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowECRActions",
            "Effect": "Allow",
            "Action": [
                "ecr:CreateRepository",
                "ecr:DescribeRepositories",
                "ecr:DeleteRepository",
                "ecr:TagResource",
                "ecr:ListTagsForResource"
            ],
            "Resource": "*"
        }
    ]
}
```


### Kubernetes
#### Toggle
- `create_kubernetes_cluster` to create a new Amazon Elastic Kubernetes Service Cluster
- `existing_eks_cluster_name` to use an existing EKS cluster

#### Description
Uses the [terraform-aws-eks](https://github.com/terraform-aws-modules/terraform-aws-eks) module to create a new EKS cluster to host the DataRobot application and any other helm charts installed by this module.

Included EKS addons:
- `coredns`
- `eks-pod-identity-agent`
- `kube-proxy`
- `vpc-cni`

An access entry for the identity of the cluster creator is added as a cluster admin. More access entries can be created via the `kubernetes_cluster_access_entries` variable.

Network access to the cluster's public API endpoint (via the public internet) is enabled by default. This access can be restricted to a specific set of public IP addresses using the `kubernetes_cluster_endpoint_public_access_cidrs` variable or disabled completely by setting the `kubernetes_cluster_endpoint_public_access` variable to `false`.

Network access to the cluster's private API endpoint is only allowed for the Kubernetes nodes by default. If the private API endpoint needs to be accessed from other hosts (such as a provisioner or bastion within the same VPC), the IP address of that host needs to be specified in the `kubernetes_cluster_endpoint_private_access_cidrs` variable.

Two node groups are created:
- A `datarobot-cpu` node group intended to host the majority of the DataRobot pods
- A `datarobot-gpu` node group intended to host GPU workload pods

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEKSActions",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:CreateLaunchTemplate",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:DeleteLaunchTemplate",
                "ec2:RunInstances",
                "ec2:DescribeTags",
                "ec2:DeleteTags",
                "eks:CreateCluster",
                "eks:DescribeCluster",
                "eks:DeleteCluster",
                "eks:CreateAccessEntry",
                "eks:DescribeAccessEntry",
                "eks:DeleteAccessEntry",
                "eks:CreateNodegroup",
                "eks:DescribeNodegroup",
                "eks:DeleteNodegroup",
                "eks:AssociateAccessPolicy",
                "eks:ListAssociatedAccessPolicies",
                "eks:DisassociateAccessPolicy",
                "eks:CreateAddon",
                "eks:DescribeAddon",
                "eks:DescribeAddonVersions",
                "eks:DeleteAddon",
                "eks:TagResource",
                "iam:CreateRole",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:TagRole",
                "iam:PassRole",
                "iam:DeleteRole",
                "iam:CreatePolicy",
                "iam:GetPolicy",
                "iam:TagPolicy",
                "iam:GetPolicyVersion",
                "iam:ListPolicyVersions",
                "iam:DeletePolicy",
                "iam:AttachRolePolicy",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:PutRolePolicy",
                "iam:DetachRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:ListInstanceProfilesForRole",
                "iam:CreateOpenIDConnectProvider",
                "iam:GetOpenIDConnectProvider",
                "iam:TagOpenIDConnectProvider",
                "iam:DeleteOpenIDConnectProvider",
                "logs:CreateLogGroup",
                "logs:DescribeLogGroups",
                "logs:DeleteLogGroup",
                "logs:PutRetentionPolicy",
                "logs:TagResource",
                "logs:ListTagsForResource"
            ],
            "Resource": "*"
        }
    ]
}
```


### Postgres
#### Toggle
- `create_postgres` to create a new Amazon RDS for PostgreSQL instance

#### Description
Uses the [terraform-aws-rds](https://github.com/terraform-aws-modules/terraform-aws-rds) module to create a new RDS postgres instance for use by the DataRobot application.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowRDSActions",
            "Effect": "Allow",
            "Action": [
                "rds:CreateDBInstance",
                "rds:ModifyDBInstance",
                "rds:DeleteDBInstance",
                "rds:DescribeDBInstances",
                "rds:StartDBInstance",
                "rds:StopDBInstance",
                "rds:CreateDBSubnetGroup",
                "rds:ModifyDBSubnetGroup",
                "rds:DeleteDBSubnetGroup",
                "rds:DescribeDBSubnetGroups",
                "rds:CreateOptionGroup",
                "rds:ModifyOptionGroup",
                "rds:DeleteOptionGroup",
                "rds:DescribeOptionGroups",
                "rds:CreateDBParameterGroup",
                "rds:ModifyDBParameterGroup",
                "rds:DeleteDBParameterGroup",
                "rds:DescribeDBParameterGroups",
                "rds:DescribeDBParameters",
                "rds:AddTagsToResource",
                "rds:ListTagsForResource"
            ],
            "Resource": "*"
        }
    ]
}
```


### Redis
#### Toggle
- `create_redis` to create a new ElastiCache Redis replication group

#### Description
Uses the [terraform-aws-elasticache](https://github.com/terraform-aws-modules/terraform-aws-elasticache) module to create a new ElastiCache Redis replication group for use by the DataRobot application.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowElasticacheActions",
            "Effect": "Allow",
            "Action": [
                "elasticache:*"
            ],
            "Resource": "*"
        }
    ]
}
```


### MongoDB
#### Toggle
- `create_mongodb` to create a new MongoDB Atlas cluster

#### Description
Create a MongoDB Atlas project and cluster for use by the DataRobot application.

#### IAM Policy
Not required


### Helm Chart - aws-load-balancer-controller
#### Toggle
- `aws_load_balancer_controller` to install the `aws-load-balancer-controller` helm chart

#### Description
Uses the [terraform-aws-eks-pod-identity](https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity) module to create a pod identity for the `aws-load-balancer-controller` service account in the `aws-load-balancer-controller` namespace with an [IAM policy](https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity/blob/master/aws_lb_controller.tf) that allows the management of AWS load balancers.

Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `https://aws.github.io/eks-charts/aws-load-balancer-controller` helm chart into the `aws-load-balancer-controller` namespace.

This helm chart provisions Network Load Balancers for Kubernetes Service resources. In the default use-case, the AWS Load Balancer Controller will create a NLB directing traffic to the `ingress-nginx` Kubernetes services.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowPodIdentityActions",
            "Effect": "Allow",
            "Action": [
                "eks:CreatePodIdentityAssociation",
                "eks:DescribePodIdentityAssociation",
                "eks:DeletePodIdentityAssociation"
            ],
            "Resource": "*"
        }
    ]
}
```


### Helm Chart - cluster-autoscaler
#### Toggle
- `cluster_autoscaler` to install the `cluster-autoscaler` helm chart

#### Description
Uses the [terraform-aws-eks-pod-identity](https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity) module to create a pod identity for the `cluster-autoscaler-aws-cluster-autoscaler` service account in the `cluster-autoscaler` namespace with an [IAM policy](https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity/blob/master/cluster_autoscaler.tf) that allows the creation and management of EC2 instances.

Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `cluster-autoscaler` helm chart from the  `https://kubernetes.github.io/autoscaler` helm repo into the `cluster-autoscaler` namespace.

This helm chart allows for automatic horizontal scaling of EKS cluster nodes.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowPodIdentityActions",
            "Effect": "Allow",
            "Action": [
                "eks:CreatePodIdentityAssociation",
                "eks:DescribePodIdentityAssociation",
                "eks:DeletePodIdentityAssociation"
            ],
            "Resource": "*"
        }
    ]
}
```


### Helm Chart - descheduler
#### Toggle
- `descheduler` to install the `descheduler` helm chart

#### Description
Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `descheduler` helm chart from the `https://kubernetes-sigs.github.io/descheduler/` helm repo into the `descheduler` namespace.

This helm chart allows for automatic rescheduling of pods for optimizing resource consumption.

#### IAM Policy
Not required


### Helm Chart - aws-ebs-csi-driver
#### Toggle
- `aws_ebs_csi_driver` to install the `aws-ebs-csi-driver` helm chart

#### Description
Uses the [terraform-aws-eks-pod-identity](https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity) module to create a pod identity for the `ebs-csi-controller-sa` service account in the `aws-ebs-csi-driver` namespace with an [IAM policy](https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity/blob/master/aws_ebs_csi.tf) that allows the creation and management of EBS volumes.

Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `aws-ebs-csi-driver` helm chart from the `https://kubernetes-sigs.github.io/aws-ebs-csi-driver/` repo into the `aws-ebs-csi-driver` namespace.

This helm chart creates default EBS storage class called `ebs-gp3` of type `gp3` using with encryption enabled. These storage classes are used by the DataRobot application Persistent Volume Claims.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowPodIdentityActions",
            "Effect": "Allow",
            "Action": [
                "eks:CreatePodIdentityAssociation",
                "eks:DescribePodIdentityAssociation",
                "eks:DeletePodIdentityAssociation"
            ],
            "Resource": "*"
        }
    ]
}
```


### Helm Chart - ingress-nginx
#### Toggle
- `ingress_nginx` to install the `ingress-nginx` helm chart

#### Description
Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `ingress-nginx` helm chart from the `https://kubernetes.github.io/ingress-nginx` repo into the `ingress-nginx` namespace.

The `ingress-nginx` helm chart will trigger the deployment of an AWS Network Load Balancer to act as ingress for the DataRobot application. When `internet_facing_ingress_lb` is `true`, the NLB will be of type `internet-facing`. When `internet_facing_ingress_lb` is `false`, the NLB will be of type `internal`.

By default this NLB will terminate TLS using either the certificate specified with the `existing_acm_certificate_arn` variable or the certificate created in the ACM module if `create_acm_certificate` is `true`. It is possible not to use ACM at all by setting `create_acm_certificate` to `false` and overriding the `controller.service.targetPorts.https` setting as demonstrated in the [complete example](examples/complete).

Optionally expose the `internal` NLB as a VPCE endpoint service using the `create_ingress_vpce_service` flag. A list of AWS principals may be allowed to discover the endpoint service using the `ingress_vpce_service_allowed_principals` variable.

#### IAM Policy
Not required


### Helm Chart - cert-manager
#### Toggle
- `cert_manager` to install the `cert-manager` helm chart

#### Description
Uses the [terraform-aws-eks-pod-identity](https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity) module to create a pod identity for the `cert-manager` service account in the `cert-manager` namespace with an [IAM policy](https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity/blob/master/cert_manager.tf) that allows the creation of DNS resources within the specified DNS zone.

Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `cert-manager` helm chart from the `https://charts.jetstack.io` repo into the `cert-manager` namespace.

`cert-manager` can be used by the DataRobot application to create and manage various certificates. When an ACM certificate is used in the ingress load balancer, `cert-manager` is typically just used to generate self-signed certificates that can be used for service to service communications.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowPodIdentityActions",
            "Effect": "Allow",
            "Action": [
                "eks:CreatePodIdentityAssociation",
                "eks:DescribePodIdentityAssociation",
                "eks:DeletePodIdentityAssociation"
            ],
            "Resource": "*"
        }
    ]
}
```


### Helm Chart - external-dns
#### Toggle
- `external_dns` to install the `external-dns` helm chart

#### Description
Uses the [terraform-aws-eks-pod-identity](https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity) module to create a pod identity for the `external-dns` service account in the `external-dns` namespace with an [IAM policy](https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity/blob/master/external_dns.tf) that allows the creation of DNS resources within the specified DNS zone.

Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `external-dns` helm chart from the `https://charts.bitnami.com/bitnami` repo into the `external-dns` namespace.

`external-dns` is used to automatically create DNS records for ingress resources in the Kubernetes cluster. When the DataRobot application is installed and the ingress resources are created, `external-dns` will automatically create a DNS record pointing at the ingress resource.

#### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowPodIdentityActions",
            "Effect": "Allow",
            "Action": [
                "eks:CreatePodIdentityAssociation",
                "eks:DescribePodIdentityAssociation",
                "eks:DeletePodIdentityAssociation"
            ],
            "Resource": "*"
        }
    ]
}
```


### Helm Chart - nvidia-device-plugin
#### Toggle
- `nvidia_device_plugin` to install the `nvidia-device-plugin` helm chart

#### Description
Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `nvidia-device-plugin` helm chart from the `https://nvidia.github.io/k8s-device-plugin` repo into the `nvidia-device-plugin` namespace.

This helm chart is used to expose GPU resources on nodes intended for GPU workloads such as the default `gpu` node group.

#### IAM Policy
Not required


### Helm Chart - nvidia-gpu-operator
#### Toggle
- `nvidia_gpu_operator` to install the `nvidia-gpu-operator` helm chart

#### Description
Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `gpu-operator` helm chart from the `https://helm.ngc.nvidia.com/nvidia` repo into the `gpu-operator` namespace.

This helm chart is used to manage NVIDIA drivers, the Kubernetes device plugin for GPUs, the NVIDIA Container Runtime, and various other NVIDIA GPU-related operations.

#### IAM Policy
Not required


### Helm Chart - metrics-server
#### Toggle
- `metrics_server` to install the `metrics-server` helm chart

#### Description
Uses the [terraform-helm-release](https://github.com/terraform-module/terraform-helm-release) module to install the `metrics-server` helm chart from the `https://kubernetes-sigs.github.io/metrics-server` repo into the `metrics-server` namespace.

This helm chart is used to expose CPU and memory metrics to the Kubernetes cluster.

#### IAM Policy
Not required



### Comprehensive IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowVPCActions",
            "Effect": "Allow",
            "Action": [
              "ec2:DescribeAvailabilityZones",
              "ec2:CreateVpc",
              "ec2:DescribeVpcs",
              "ec2:DescribeVpcAttribute",
              "ec2:ModifyVpcAttribute",
              "ec2:DeleteVpc",
              "ec2:CreateSubnet",
              "ec2:DescribeSubnets",
              "ec2:DeleteSubnet",
              "ec2:CreateRouteTable",
              "ec2:DescribeRouteTables",
              "ec2:AssociateRouteTable",
              "ec2:DisassociateRouteTable",
              "ec2:DeleteRouteTable",
              "ec2:CreateRoute",
              "ec2:DeleteRoute",
              "ec2:CreateInternetGateway",
              "ec2:DescribeInternetGateways",
              "ec2:AttachInternetGateway",
              "ec2:DetachInternetGateway",
              "ec2:DeleteInternetGateway",
              "ec2:CreateNatGateway",
              "ec2:DescribeNatGateways",
              "ec2:DeleteNatGateway",
              "ec2:AllocateAddress",
              "ec2:DescribeAddresses",
              "ec2:DescribeAddressesAttribute",
              "ec2:DisassociateAddress",
              "ec2:ReleaseAddress",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeSecurityGroupRules",
              "ec2:RevokeSecurityGroupEgress",
              "ec2:RevokeSecurityGroupIngress",
              "ec2:CreateNetworkAclEntry",
              "ec2:DescribeNetworkAcls",
              "ec2:DeleteNetworkAclEntry",
              "ec2:DescribeNetworkInterfaces",
              "ec2:CreateTags"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowRoute53Actions",
            "Effect": "Allow",
            "Action": [
                "route53:CreateHostedZone",
                "route53:GetHostedZone",
                "route53:DeleteHostedZone",
                "route53:ListResourceRecordSets",
                "route53:GetChange",
                "route53:GetDNSSEC",
                "route53:ListTagsForResource",
                "route53:ChangeTagsForResource"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowACMActions",
            "Effect": "Allow",
            "Action": [
                "acm:RequestCertificate",
                "acm:DescribeCertificate",
                "acm:DeleteCertificate",
                "acm:AddTagsToCertificate",
                "acm:ListTagsForCertificate",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowKMSActions",
            "Effect": "Allow",
            "Action": [
                "kms:TagResource",
                "kms:CreateKey",
                "kms:CreateAlias",
                "kms:ListAliases",
                "kms:DeleteAlias"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowS3Actions",
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:ListBucket",
                "s3:ListBucketVersions",
                "s3:GetBucketPolicy",
                "s3:GetBucketAcl",
                "s3:GetBucketCORS",
                "s3:GetBucketWebsite",
                "s3:GetBucketVersioning",
                "s3:GetBucketLogging",
                "s3:GetBucketRequestPayment",
                "s3:GetBucketTagging",
                "s3:PutBucketTagging",
                "s3:GetBucketPublicAccessBlock",
                "s3:PutBucketPublicAccessBlock",
                "s3:GetBucketObjectLockConfiguration",
                "s3:GetAccelerateConfiguration",
                "s3:GetLifecycleConfiguration",
                "s3:GetReplicationConfiguration",
                "s3:GetEncryptionConfiguration",
                "s3:DeleteObjectVersion",
                "s3:DeleteBucket"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowECRActions",
            "Effect": "Allow",
            "Action": [
                "ecr:CreateRepository",
                "ecr:DescribeRepositories",
                "ecr:DeleteRepository",
                "ecr:TagResource",
                "ecr:ListTagsForResource"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowEKSActions",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:CreateLaunchTemplate",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:DeleteLaunchTemplate",
                "ec2:RunInstances",
                "ec2:DescribeTags",
                "ec2:DeleteTags",
                "eks:CreateCluster",
                "eks:DescribeCluster",
                "eks:DeleteCluster",
                "eks:CreateAccessEntry",
                "eks:DescribeAccessEntry",
                "eks:DeleteAccessEntry",
                "eks:CreateNodegroup",
                "eks:DescribeNodegroup",
                "eks:DeleteNodegroup",
                "eks:AssociateAccessPolicy",
                "eks:ListAssociatedAccessPolicies",
                "eks:DisassociateAccessPolicy",
                "eks:CreateAddon",
                "eks:DescribeAddon",
                "eks:DescribeAddonVersions",
                "eks:DeleteAddon",
                "eks:TagResource",
                "iam:CreateRole",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:TagRole",
                "iam:PassRole",
                "iam:DeleteRole",
                "iam:CreatePolicy",
                "iam:GetPolicy",
                "iam:TagPolicy",
                "iam:GetPolicyVersion",
                "iam:ListPolicyVersions",
                "iam:DeletePolicy",
                "iam:AttachRolePolicy",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:PutRolePolicy",
                "iam:DetachRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:ListInstanceProfilesForRole",
                "iam:CreateOpenIDConnectProvider",
                "iam:GetOpenIDConnectProvider",
                "iam:TagOpenIDConnectProvider",
                "iam:DeleteOpenIDConnectProvider",
                "logs:CreateLogGroup",
                "logs:DescribeLogGroups",
                "logs:DeleteLogGroup",
                "logs:PutRetentionPolicy",
                "logs:TagResource",
                "logs:ListTagsForResource"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowPodIdentityActions",
            "Effect": "Allow",
            "Action": [
                "eks:CreatePodIdentityAssociation",
                "eks:DescribePodIdentityAssociation",
                "eks:DeletePodIdentityAssociation"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowRDSActions",
            "Effect": "Allow",
            "Action": [
                "rds:CreateDBInstance",
                "rds:ModifyDBInstance",
                "rds:DeleteDBInstance",
                "rds:DescribeDBInstances",
                "rds:StartDBInstance",
                "rds:StopDBInstance",
                "rds:CreateDBSubnetGroup",
                "rds:ModifyDBSubnetGroup",
                "rds:DeleteDBSubnetGroup",
                "rds:DescribeDBSubnetGroups",
                "rds:CreateOptionGroup",
                "rds:ModifyOptionGroup",
                "rds:DeleteOptionGroup",
                "rds:DescribeOptionGroups",
                "rds:CreateDBParameterGroup",
                "rds:ModifyDBParameterGroup",
                "rds:DeleteDBParameterGroup",
                "rds:DescribeDBParameterGroups",
                "rds:DescribeDBParameters",
                "rds:AddTagsToResource",
                "rds:ListTagsForResource"
            ],
            "Resource": "*"
        }
    ]
}
```


## DataRobot versions
Currently the only thing coupling a release of this module to a DataRobot Enterprise Release is the default set of ecr_repositories. Technically, this module can be used with any DataRobot version if the user specifies the correct list of ecr_repositories for that version.

The default installation supports DataRobot versions >= 10.1.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.61 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.15 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.61 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 4.0 |
| <a name="module_app_identity"></a> [app\_identity](#module\_app\_identity) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| <a name="module_aws_load_balancer_controller"></a> [aws\_load\_balancer\_controller](#module\_aws\_load\_balancer\_controller) | ./modules/aws-load-balancer-controller | n/a |
| <a name="module_aws_vpc_cni_ipv4_pod_identity"></a> [aws\_vpc\_cni\_ipv4\_pod\_identity](#module\_aws\_vpc\_cni\_ipv4\_pod\_identity) | terraform-aws-modules/eks-pod-identity/aws | ~> 1.0 |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | ./modules/cert-manager | n/a |
| <a name="module_cluster_autoscaler"></a> [cluster\_autoscaler](#module\_cluster\_autoscaler) | ./modules/cluster-autoscaler | n/a |
| <a name="module_container_registry"></a> [container\_registry](#module\_container\_registry) | terraform-aws-modules/ecr/aws | ~> 2.0 |
| <a name="module_descheduler"></a> [descheduler](#module\_descheduler) | ./modules/descheduler | n/a |
| <a name="module_dns"></a> [dns](#module\_dns) | terraform-aws-modules/route53/aws//modules/zones | ~> 3.0 |
| <a name="module_ebs_csi_driver"></a> [ebs\_csi\_driver](#module\_ebs\_csi\_driver) | ./modules/ebs-csi-driver | n/a |
| <a name="module_encryption_key"></a> [encryption\_key](#module\_encryption\_key) | terraform-aws-modules/kms/aws | ~> 3.0 |
| <a name="module_endpoints"></a> [endpoints](#module\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | ~> 5.0 |
| <a name="module_external_dns"></a> [external\_dns](#module\_external\_dns) | ./modules/external-dns | n/a |
| <a name="module_ingress_nginx"></a> [ingress\_nginx](#module\_ingress\_nginx) | ./modules/ingress-nginx | n/a |
| <a name="module_kubernetes"></a> [kubernetes](#module\_kubernetes) | terraform-aws-modules/eks/aws | ~> 20.0 |
| <a name="module_metrics_server"></a> [metrics\_server](#module\_metrics\_server) | ./modules/metrics-server | n/a |
| <a name="module_network"></a> [network](#module\_network) | terraform-aws-modules/vpc/aws | ~> 5.0 |
| <a name="module_nvidia_device_plugin"></a> [nvidia\_device\_plugin](#module\_nvidia\_device\_plugin) | ./modules/nvidia-device-plugin | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | terraform-aws-modules/s3-bucket/aws | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group_tag.gpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group_tag) | resource |
| [aws_autoscaling_group_tag.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group_tag) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_route53_zone.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_route53_zone.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_load_balancer_controller"></a> [aws\_load\_balancer\_controller](#input\_aws\_load\_balancer\_controller) | Install the aws-load-balancer-controller helm chart to use AWS Network Load Balancers as ingress to the EKS cluster. All other aws\_load\_balancer\_controller variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_aws_load_balancer_controller_values"></a> [aws\_load\_balancer\_controller\_values](#input\_aws\_load\_balancer\_controller\_values) | Path to templatefile containing custom values for the aws-load-balancer-controller helm chart | `string` | `""` | no |
| <a name="input_aws_load_balancer_controller_variables"></a> [aws\_load\_balancer\_controller\_variables](#input\_aws\_load\_balancer\_controller\_variables) | Variables passed to the aws\_load\_balancer\_controller\_values templatefile | `any` | `{}` | no |
| <a name="input_cert_manager"></a> [cert\_manager](#input\_cert\_manager) | Install the cert-manager helm chart. All other cert\_manager variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_cert_manager_values"></a> [cert\_manager\_values](#input\_cert\_manager\_values) | Path to templatefile containing custom values for the cert-manager helm chart | `string` | `""` | no |
| <a name="input_cert_manager_variables"></a> [cert\_manager\_variables](#input\_cert\_manager\_variables) | Variables passed to the cert\_manager\_values templatefile | `any` | `{}` | no |
| <a name="input_cluster_autoscaler"></a> [cluster\_autoscaler](#input\_cluster\_autoscaler) | Install the cluster-autoscaler helm chart to enable horizontal autoscaling of the EKS cluster nodes. All other cluster\_autoscaler variables are ignored if this variable is false | `bool` | `true` | no |
| <a name="input_cluster_autoscaler_values"></a> [cluster\_autoscaler\_values](#input\_cluster\_autoscaler\_values) | Path to templatefile containing custom values for the cluster-autoscaler helm chart | `string` | `""` | no |
| <a name="input_cluster_autoscaler_variables"></a> [cluster\_autoscaler\_variables](#input\_cluster\_autoscaler\_variables) | Variables passed to the cluster\_autoscaler\_values templatefile | `any` | `{}` | no |
| <a name="input_create_acm_certificate"></a> [create\_acm\_certificate](#input\_create\_acm\_certificate) | Create a new ACM certificate for the ingress load balancer to use. Ignored if existing\_acm\_certificate\_arn is specified. | `bool` | `true` | no |
| <a name="input_create_app_identity"></a> [create\_app\_identity](#input\_create\_app\_identity) | Create an IAM role for the DataRobot application service accounts | `bool` | `true` | no |
| <a name="input_create_container_registry"></a> [create\_container\_registry](#input\_create\_container\_registry) | Create DataRobot image builder container repositories in Amazon Elastic Container Registry | `bool` | `true` | no |
| <a name="input_create_dns_zones"></a> [create\_dns\_zones](#input\_create\_dns\_zones) | Create DNS zones for domain\_name. Ignored if existing\_public\_route53\_zone\_id and existing\_private\_route53\_zone\_id are specified. | `bool` | `true` | no |
| <a name="input_create_encryption_key"></a> [create\_encryption\_key](#input\_create\_encryption\_key) | Create a new KMS key used for EBS volume encryption on EKS nodes. Ignored if existing\_kms\_key\_arn is specified. | `bool` | `true` | no |
| <a name="input_create_kubernetes_cluster"></a> [create\_kubernetes\_cluster](#input\_create\_kubernetes\_cluster) | Create a new Amazon Elastic Kubernetes Cluster. All kubernetes and helm chart variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_create_network"></a> [create\_network](#input\_create\_network) | Create a new Virtual Private Cloud. Ignored if an existing existing\_vpc\_id is specified. | `bool` | `true` | no |
| <a name="input_create_storage"></a> [create\_storage](#input\_create\_storage) | Create a new S3 storage bucket to use for DataRobot application file storage. Ignored if an existing\_s3\_bucket\_id is specified. | `bool` | `true` | no |
| <a name="input_datarobot_namespace"></a> [datarobot\_namespace](#input\_datarobot\_namespace) | Kubernetes namespace in which the DataRobot application will be installed | `string` | `"dr-app"` | no |
| <a name="input_descheduler"></a> [descheduler](#input\_descheduler) | Install the descheduler helm chart to enable rescheduling of pods. All other descheduler variables are ignored if this variable is false | `bool` | `true` | no |
| <a name="input_descheduler_values"></a> [descheduler\_values](#input\_descheduler\_values) | Path to templatefile containing custom values for the descheduler helm chart | `string` | `""` | no |
| <a name="input_descheduler_variables"></a> [descheduler\_variables](#input\_descheduler\_variables) | Variables passed to the descheduler templatefile | `any` | `{}` | no |
| <a name="input_dns_zones_force_destroy"></a> [dns\_zones\_force\_destroy](#input\_dns\_zones\_force\_destroy) | Force destroy the public and private Route53 zones. Ignored if an existing route53\_zone\_id is specified or create\_dns\_zones is false. | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Name of the domain to use for the DataRobot application. If create\_dns\_zones is true then zones will be created for this domain. It is also used by ACM for DNS validation and as a domain filter by the external-dns helm chart. | `string` | `""` | no |
| <a name="input_ebs_csi_driver"></a> [ebs\_csi\_driver](#input\_ebs\_csi\_driver) | Install the aws-ebs-csi-driver helm chart to enable use of EBS for Kubernetes persistent volumes. All other ebs\_csi\_driver variables are ignored if this variable is false | `bool` | `true` | no |
| <a name="input_ebs_csi_driver_values"></a> [ebs\_csi\_driver\_values](#input\_ebs\_csi\_driver\_values) | Path to templatefile containing custom values for the aws-ebs-csi-driver helm chart | `string` | `""` | no |
| <a name="input_ebs_csi_driver_variables"></a> [ebs\_csi\_driver\_variables](#input\_ebs\_csi\_driver\_variables) | Variables passed to the ebs\_csi\_driver\_values templatefile | `any` | `{}` | no |
| <a name="input_ecr_repositories"></a> [ecr\_repositories](#input\_ecr\_repositories) | Repositories to create | `set(string)` | <pre>[<br>  "base-image",<br>  "ephemeral-image",<br>  "managed-image",<br>  "custom-apps-managed-image"<br>]</pre> | no |
| <a name="input_ecr_repositories_force_destroy"></a> [ecr\_repositories\_force\_destroy](#input\_ecr\_repositories\_force\_destroy) | Force destroy the ECR repositories. Ignored if create\_container\_registry is false. | `bool` | `false` | no |
| <a name="input_existing_acm_certificate_arn"></a> [existing\_acm\_certificate\_arn](#input\_existing\_acm\_certificate\_arn) | ARN of existing ACM certificate to use with the ingress load balancer created by the ingress\_nginx module. When specified, create\_acm\_certificate will be ignored. | `string` | `""` | no |
| <a name="input_existing_eks_cluster_name"></a> [existing\_eks\_cluster\_name](#input\_existing\_eks\_cluster\_name) | Name of existing EKS cluster to use. When specified, all other kubernetes variables will be ignored. | `string` | `null` | no |
| <a name="input_existing_kms_key_arn"></a> [existing\_kms\_key\_arn](#input\_existing\_kms\_key\_arn) | ARN of existing KMS key used for EBS volume encryption on EKS nodes. When specified, create\_encryption\_key will be ignored. | `string` | `""` | no |
| <a name="input_existing_kubernetes_nodes_subnet_ids"></a> [existing\_kubernetes\_nodes\_subnet\_id](#input\_existing\_kubernetes\_nodes\_subnet\_id) | List of existing subnet IDs to be used for the EKS cluster. Required when an existing\_network\_id is specified. Ignored if create\_network is true and no existing\_network\_id is specified. Subnets must adhere to VPC requirements and considerations https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html. | `list(string)` | `[]` | no |
| <a name="input_existing_private_route53_zone_id"></a> [existing\_private\_route53\_zone\_id](#input\_existing\_private\_route53\_zone\_id) | ID of existing private Route53 hosted zone to use for private DNS records created by external-dns. This is required when create\_dns\_zones is false and ingress\_nginx is true with internet\_facing\_ingress\_lb false. | `string` | `""` | no |
| <a name="input_existing_public_route53_zone_id"></a> [existing\_public\_route53\_zone\_id](#input\_existing\_public\_route53\_zone\_id) | ID of existing public Route53 hosted zone to use for public DNS records created by external-dns and ACM certificate validation. This is required when create\_dns\_zones is false and ingress\_nginx and internet\_facing\_ingress\_lb are true or when create\_acm\_certificate is true. | `string` | `""` | no |
| <a name="input_existing_s3_bucket_id"></a> [existing\_s3\_bucket\_id](#input\_existing\_s3\_bucket\_id) | ID of existing S3 storage bucket to use for DataRobot application file storage. When specified, all other storage variables will be ignored. | `string` | `""` | no |
| <a name="input_existing_vpc_id"></a> [existing\_vpc\_id](#input\_existing\_vpc\_id) | ID of an existing VPC to use. When specified, other network variables are ignored. | `string` | `""` | no |
| <a name="input_external_dns"></a> [external\_dns](#input\_external\_dns) | Install the external\_dns helm chart to create DNS records for ingress resources matching the domain\_name variable. All other external\_dns variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_external_dns_values"></a> [external\_dns\_values](#input\_external\_dns\_values) | Path to templatefile containing custom values for the external-dns helm chart | `string` | `""` | no |
| <a name="input_external_dns_variables"></a> [external\_dns\_variables](#input\_external\_dns\_variables) | Variables passed to the external\_dns\_values templatefile | `any` | `{}` | no |
| <a name="input_ingress_nginx"></a> [ingress\_nginx](#input\_ingress\_nginx) | Install the ingress-nginx helm chart to use as the ingress controller for the EKS cluster. All other ingress\_nginx variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_ingress_nginx_values"></a> [ingress\_nginx\_values](#input\_ingress\_nginx\_values) | Path to templatefile containing custom values for the ingress-nginx helm chart. | `string` | `""` | no |
| <a name="input_ingress_nginx_variables"></a> [ingress\_nginx\_variables](#input\_ingress\_nginx\_variables) | Variables passed to the ingress\_nginx\_values templatefile | `any` | `{}` | no |
| <a name="input_internet_facing_ingress_lb"></a> [internet\_facing\_ingress\_lb](#input\_internet\_facing\_ingress\_lb) | Determines the type of NLB created for EKS ingress. If true, an internet-facing NLB will be created. If false, an internal NLB will be created. Ignored when ingress\_nginx is false. | `bool` | `true` | no |
| <a name="input_kubernetes_cluster_access_entries"></a> [kubernetes\_cluster\_access\_entries](#input\_kubernetes\_cluster\_access\_entries) | Map of access entries to add to the cluster | `any` | `{}` | no |
| <a name="input_kubernetes_cluster_endpoint_private_access_cidrs"></a> [kubernetes\_cluster\_endpoint\_private\_access\_cidrs](#input\_kubernetes\_cluster\_endpoint\_private\_access\_cidrs) | List of additional CIDR blocks allowed to access the Amazon EKS private API server endpoint. By default only the kubernetes nodes are allowed, if any other hosts such as a provisioner need to access the EKS private API endpoint they need to be added here. | `list(string)` | `[]` | no |
| <a name="input_kubernetes_cluster_endpoint_public_access"></a> [kubernetes\_cluster\_endpoint\_public\_access](#input\_kubernetes\_cluster\_endpoint\_public\_access) | Indicates whether or not the Amazon EKS public API server endpoint is enabled | `bool` | `true` | no |
| <a name="input_kubernetes_cluster_endpoint_public_access_cidrs"></a> [kubernetes\_cluster\_endpoint\_public\_access\_cidrs](#input\_kubernetes\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_kubernetes_cluster_version"></a> [kubernetes\_cluster\_version](#input\_kubernetes\_cluster\_version) | EKS cluster version | `string` | `null` | no |
| <a name="input_kubernetes_gpu_nodegroup_ami_type"></a> [kubernetes\_gpu\_nodegroup\_ami\_type](#input\_kubernetes\_gpu\_nodegroup\_ami\_type) | Type of Amazon Machine Image (AMI) associated with the EKS GPU Node Group. See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values | `string` | `"AL2_x86_64_GPU"` | no |
| <a name="input_kubernetes_gpu_nodegroup_desired_size"></a> [kubernetes\_gpu\_nodegroup\_desired\_size](#input\_kubernetes\_gpu\_nodegroup\_desired\_size) | Desired number of nodes in the GPU node group | `number` | `0` | no |
| <a name="input_kubernetes_gpu_nodegroup_instance_types"></a> [kubernetes\_gpu\_nodegroup\_instance\_types](#input\_kubernetes\_gpu\_nodegroup\_instance\_types) | Instance types used for the GPU node group | `list(string)` | <pre>[<br>  "g4dn.2xlarge"<br>]</pre> | no |
| <a name="input_kubernetes_gpu_nodegroup_labels"></a> [kubernetes\_gpu\_nodegroup\_labels](#input\_kubernetes\_gpu\_nodegroup\_labels) | Key-value map of Kubernetes labels to be applied to the nodes in the GPU node group. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed | `map(string)` | <pre>{<br>  "datarobot.com/node-capability": "gpu"<br>}</pre> | no |
| <a name="input_kubernetes_gpu_nodegroup_max_size"></a> [kubernetes\_gpu\_nodegroup\_max\_size](#input\_kubernetes\_gpu\_nodegroup\_max\_size) | Maximum number of nodes in the GPU node group | `number` | `10` | no |
| <a name="input_kubernetes_gpu_nodegroup_min_size"></a> [kubernetes\_gpu\_nodegroup\_min\_size](#input\_kubernetes\_gpu\_nodegroup\_min\_size) | Minimum number of nodes in the GPU node group | `number` | `0` | no |
| <a name="input_kubernetes_gpu_nodegroup_name"></a> [kubernetes\_gpu\_nodegroup\_name](#input\_kubernetes\_gpu\_nodegroup\_name) | Name of the GPU node group | `string` | `"gpu"` | no |
| <a name="input_kubernetes_gpu_nodegroup_taints"></a> [kubernetes\_gpu\_nodegroup\_taints](#input\_kubernetes\_gpu\_nodegroup\_taints) | The Kubernetes taints to be applied to the nodes in the GPU node group. Maximum of 50 taints per node group | `any` | <pre>{<br>  "nvidia_gpu": {<br>    "effect": "NO_SCHEDULE",<br>    "key": "nvidia.com/gpu",<br>    "value": "true"<br>  }<br>}</pre> | no |
| <a name="input_kubernetes_primary_nodegroup_ami_type"></a> [kubernetes\_primary\_nodegroup\_ami\_type](#input\_kubernetes\_primary\_nodegroup\_ami\_type) | Type of Amazon Machine Image (AMI) associated with the EKS Primary Node Group. See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values | `string` | `"AL2023_x86_64_STANDARD"` | no |
| <a name="input_kubernetes_primary_nodegroup_desired_size"></a> [kubernetes\_primary\_nodegroup\_desired\_size](#input\_kubernetes\_primary\_nodegroup\_desired\_size) | Desired number of nodes in the primary node group | `number` | `1` | no |
| <a name="input_kubernetes_primary_nodegroup_instance_types"></a> [kubernetes\_primary\_nodegroup\_instance\_types](#input\_kubernetes\_primary\_nodegroup\_instance\_types) | Instance types used for the primary node group | `list(string)` | <pre>[<br>  "r6a.4xlarge",<br>  "r6i.4xlarge",<br>  "r5.4xlarge",<br>  "r4.4xlarge"<br>]</pre> | no |
| <a name="input_kubernetes_primary_nodegroup_labels"></a> [kubernetes\_primary\_nodegroup\_labels](#input\_kubernetes\_primary\_nodegroup\_labels) | Key-value map of Kubernetes labels to be applied to the nodes in the primary node group. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed. | `map(string)` | <pre>{<br>  "datarobot.com/node-capability": "cpu"<br>}</pre> | no |
| <a name="input_kubernetes_primary_nodegroup_max_size"></a> [kubernetes\_primary\_nodegroup\_max\_size](#input\_kubernetes\_primary\_nodegroup\_max\_size) | Maximum number of nodes in the primary node group | `number` | `10` | no |
| <a name="input_kubernetes_primary_nodegroup_min_size"></a> [kubernetes\_primary\_nodegroup\_min\_size](#input\_kubernetes\_primary\_nodegroup\_min\_size) | Minimum number of nodes in the primary node group | `number` | `0` | no |
| <a name="input_kubernetes_primary_nodegroup_name"></a> [kubernetes\_primary\_nodegroup\_name](#input\_kubernetes\_primary\_nodegroup\_name) | Name of the primary EKS node group | `string` | `"primary"` | no |
| <a name="input_kubernetes_primary_nodegroup_taints"></a> [kubernetes\_primary\_nodegroup\_taints](#input\_kubernetes\_primary\_nodegroup\_taints) | The Kubernetes taints to be applied to the nodes in the primary node group. Maximum of 50 taints per node group | `any` | `{}` | no |
| <a name="input_metrics_server"></a> [metrics\_server](#input\_metrics\_server) | Install the metrics-server helm chart to expose resource metrics for Kubernetes built-in autoscaling pipelines. All other metrics\_server variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_metrics_server_values"></a> [metrics\_server\_values](#input\_metrics\_server\_values) | Path to templatefile containing custom values for the metrics\_server helm chart | `string` | `""` | no |
| <a name="input_metrics_server_variables"></a> [metrics\_server\_variables](#input\_metrics\_server\_variables) | Variables passed to the metrics\_server\_values templatefile | `any` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use as a prefix for created resources | `string` | n/a | yes |
| <a name="input_network_address_space"></a> [network\_address\_space](#input\_network\_address\_space) | CIDR block to be used for the new VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_network_private_endpoints"></a> [network\_private\_endpoints](#input\_network\_private\_endpoints) | List of AWS services to create interface VPC endpoints for | `list(string)` | <pre>[<br>  "s3"<br>]</pre> | no |
| <a name="input_nvidia_device_plugin"></a> [nvidia\_device\_plugin](#input\_nvidia\_device\_plugin) | Install the nvidia-device-plugin helm chart to expose node GPU resources to the EKS cluster. All other nvidia\_device\_plugin variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_nvidia_device_plugin_values"></a> [nvidia\_device\_plugin\_values](#input\_nvidia\_device\_plugin\_values) | Path to templatefile containing custom values for the nvidia-device-plugin helm chart | `string` | `""` | no |
| <a name="input_nvidia_device_plugin_variables"></a> [nvidia\_device\_plugin\_variables](#input\_nvidia\_device\_plugin\_variables) | Variables passed to the nvidia\_device\_plugin\_values templatefile | `any` | `{}` | no |
| <a name="input_s3_bucket_force_destroy"></a> [s3\_bucket\_force\_destroy](#input\_s3\_bucket\_force\_destroy) | Force destroy the public and private Route53 zones | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all created resources | `map(string)` | <pre>{<br>  "managed-by": "terraform"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_certificate_arn"></a> [acm\_certificate\_arn](#output\_acm\_certificate\_arn) | ARN of the ACM certificate |
| <a name="output_app_role_arn"></a> [app\_role\_arn](#output\_app\_role\_arn) | ARN of the IAM role to be assumed by the DataRobot app service accounts |
| <a name="output_ebs_encryption_key_id"></a> [ebs\_encryption\_key\_id](#output\_ebs\_encryption\_key\_id) | ARN of the EBS KMS key |
| <a name="output_ecr_repository_urls"></a> [ecr\_repository\_urls](#output\_ecr\_repository\_urls) | URLs of the image builder repositories |
| <a name="output_kubernetes_cluster_certificate_authority_data"></a> [kubernetes\_cluster\_certificate\_authority\_data](#output\_kubernetes\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_kubernetes_cluster_endpoint"></a> [kubernetes\_cluster\_endpoint](#output\_kubernetes\_cluster\_endpoint) | Endpoint for your Kubernetes API server |
| <a name="output_kubernetes_cluster_name"></a> [kubernetes\_cluster\_name](#output\_kubernetes\_cluster\_name) | Name of the EKS cluster |
| <a name="output_private_route53_zone_arn"></a> [private\_route53\_zone\_arn](#output\_private\_route53\_zone\_arn) | Zone ARN of the private Route53 zone |
| <a name="output_private_route53_zone_id"></a> [private\_route53\_zone\_id](#output\_private\_route53\_zone\_id) | Zone ID of the private Route53 zone |
| <a name="output_public_route53_zone_arn"></a> [public\_route53\_zone\_arn](#output\_public\_route53\_zone\_arn) | Zone ARN of the public Route53 zone |
| <a name="output_public_route53_zone_id"></a> [public\_route53\_zone\_id](#output\_public\_route53\_zone\_id) | Zone ID of the public Route53 zone |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | Name of the S3 bucket |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
<!-- END_TF_DOCS -->

## Development and Contributing

If you'd like to report an issue or bug, suggest improvements, or contribute code to this project, please refer to [CONTRIBUTING.md](CONTRIBUTING.md).

# Code of Conduct

This project has adopted the Contributor Covenant for its Code of Conduct.
See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) to read it in full.

# License

Licensed under the Apache License 2.0.
See [LICENSE](LICENSE) to read it in full.
