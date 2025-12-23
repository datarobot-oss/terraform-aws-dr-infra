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
  create_rabbitmq                 = true

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

A private Route53 zone is used by `external_dns` to create records for the DataRobot ingress resources when `internet_facing_ingress_lb` is `false`. It is also used to create CNAME records for AWS service private endpoints that do not have `private_dns_enabled`.

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

By default, only the DataRobot application IAM role will be allowed read/write access to these repositories.

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


### App Identity
#### Toggle
- `create_app_identity` to create an IRSA role used by pods within the `datarobot_namespace`
- `existing_app_role_arn` to use an existing IAM role

An IAM role named `${var.name}-app-irsa` will be created with a trust policy allowing any service account within the `datarobot_namespace` in the Kubernetes cluster either created by this module or specified in `existing_eks_cluster_name` to assume it.

To enable batch spark jobs using EMR serverless, the `emr-serverless.amazonaws.com` AWS Service is also allowed to assume the role.

The role is given the `AmazonEC2ContainerRegistryPowerUser` managed policy in order to manage ECR repositories as well as S3 bucket access to either the bucket created in this module or specified by the `existing_s3_bucket_id` variable.

A second role will also be created which the DataRobot app role will assume in order to access Amazon Bedrock resources.

#### IAM Policy
```
TBD
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


### RabbitMQ
#### Toggle
- `create_rabbitmq` to create a new AMQ RabbitMQ broker

#### Description
Create a AMQ RabbitMQ broker for use by the DataRobot application.

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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.19.0 |
| <a name="requirement_mongodbatlas"></a> [mongodbatlas](#requirement\_mongodbatlas) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 5.0 |
| <a name="module_app_identity"></a> [app\_identity](#module\_app\_identity) | terraform-aws-modules/iam/aws//modules/iam-role | ~> 6.0 |
| <a name="module_aws_ebs_csi_driver"></a> [aws\_ebs\_csi\_driver](#module\_aws\_ebs\_csi\_driver) | ./modules/aws-ebs-csi-driver | n/a |
| <a name="module_aws_load_balancer_controller"></a> [aws\_load\_balancer\_controller](#module\_aws\_load\_balancer\_controller) | ./modules/aws-load-balancer-controller | n/a |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | ./modules/cert-manager | n/a |
| <a name="module_cilium"></a> [cilium](#module\_cilium) | ./modules/cilium | n/a |
| <a name="module_cluster_autoscaler"></a> [cluster\_autoscaler](#module\_cluster\_autoscaler) | ./modules/cluster-autoscaler | n/a |
| <a name="module_container_registry"></a> [container\_registry](#module\_container\_registry) | terraform-aws-modules/ecr/aws | ~> 3.0 |
| <a name="module_custom_private_endpoints"></a> [custom\_private\_endpoints](#module\_custom\_private\_endpoints) | ./modules/custom-private-endpoints | n/a |
| <a name="module_descheduler"></a> [descheduler](#module\_descheduler) | ./modules/descheduler | n/a |
| <a name="module_endpoints"></a> [endpoints](#module\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | ~> 6.0 |
| <a name="module_external_dns"></a> [external\_dns](#module\_external\_dns) | ./modules/external-dns | n/a |
| <a name="module_external_secrets"></a> [external\_secrets](#module\_external\_secrets) | ./modules/external-secrets | n/a |
| <a name="module_flow_log"></a> [flow\_log](#module\_flow\_log) | terraform-aws-modules/vpc/aws//modules/flow-log | n/a |
| <a name="module_genai_identity"></a> [genai\_identity](#module\_genai\_identity) | terraform-aws-modules/iam/aws//modules/iam-role | ~> 6.0 |
| <a name="module_ingress_nginx"></a> [ingress\_nginx](#module\_ingress\_nginx) | ./modules/ingress-nginx | n/a |
| <a name="module_kubernetes"></a> [kubernetes](#module\_kubernetes) | terraform-aws-modules/eks/aws | ~> 21.0 |
| <a name="module_kyverno"></a> [kyverno](#module\_kyverno) | ./modules/kyverno | n/a |
| <a name="module_metrics_server"></a> [metrics\_server](#module\_metrics\_server) | ./modules/metrics-server | n/a |
| <a name="module_mongodb"></a> [mongodb](#module\_mongodb) | ./modules/mongodb | n/a |
| <a name="module_network"></a> [network](#module\_network) | terraform-aws-modules/vpc/aws | ~> 6.0 |
| <a name="module_nvidia_gpu_operator"></a> [nvidia\_gpu\_operator](#module\_nvidia\_gpu\_operator) | ./modules/nvidia-gpu-operator | n/a |
| <a name="module_postgres"></a> [postgres](#module\_postgres) | ./modules/postgres | n/a |
| <a name="module_private_dns"></a> [private\_dns](#module\_private\_dns) | terraform-aws-modules/route53/aws | ~> 6.0 |
| <a name="module_private_link_service"></a> [private\_link\_service](#module\_private\_link\_service) | ./modules/private-link-service | n/a |
| <a name="module_public_dns"></a> [public\_dns](#module\_public\_dns) | terraform-aws-modules/route53/aws | ~> 6.0 |
| <a name="module_rabbitmq"></a> [rabbitmq](#module\_rabbitmq) | ./modules/rabbitmq | n/a |
| <a name="module_redis"></a> [redis](#module\_redis) | ./modules/redis | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | terraform-aws-modules/s3-bucket/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group_tag.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group_tag) | resource |
| [aws_route53_record.s3_endpoint_cname](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_lb.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.existing_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_route53_zone.existing_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_vpc.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_dns_name"></a> [application\_dns\_name](#input\_application\_dns\_name) | Application dns name | `string` | `null` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Number of availability zones to deploy into | `number` | `2` | no |
| <a name="input_aws_ebs_csi_driver"></a> [aws\_ebs\_csi\_driver](#input\_aws\_ebs\_csi\_driver) | Install the aws-ebs-csi-driver helm chart to enable use of EBS for Kubernetes persistent volumes. All other ebs\_csi\_driver variables are ignored if this variable is false | `bool` | `true` | no |
| <a name="input_aws_ebs_csi_driver_values_overrides"></a> [aws\_ebs\_csi\_driver\_values\_overrides](#input\_aws\_ebs\_csi\_driver\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_aws_ebs_csi_driver_version"></a> [aws\_ebs\_csi\_driver\_version](#input\_aws\_ebs\_csi\_driver\_version) | Version of the aws-ebs-csi-driver helm chart to install | `string` | `null` | no |
| <a name="input_aws_load_balancer_controller"></a> [aws\_load\_balancer\_controller](#input\_aws\_load\_balancer\_controller) | Install the aws-load-balancer-controller helm chart to use AWS Network Load Balancers as ingress to the EKS cluster. All other aws\_load\_balancer\_controller variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_aws_load_balancer_controller_values_overrides"></a> [aws\_load\_balancer\_controller\_values\_overrides](#input\_aws\_load\_balancer\_controller\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_aws_load_balancer_controller_version"></a> [aws\_load\_balancer\_controller\_version](#input\_aws\_load\_balancer\_controller\_version) | Version of the aws-load-balancer-controller helm chart to install | `string` | `null` | no |
| <a name="input_cert_manager"></a> [cert\_manager](#input\_cert\_manager) | Install the cert-manager helm chart. All other cert\_manager variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_cert_manager_values_overrides"></a> [cert\_manager\_values\_overrides](#input\_cert\_manager\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_cert_manager_version"></a> [cert\_manager\_version](#input\_cert\_manager\_version) | Version of the cert-manager helm chart to install | `string` | `null` | no |
| <a name="input_cilium"></a> [cilium](#input\_cilium) | Install the cilium helm chart to provide extended cluster networking and security features. All other cilium variables are ignored if this variable is false. | `bool` | `false` | no |
| <a name="input_cilium_values_overrides"></a> [cilium\_values\_overrides](#input\_cilium\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_cilium_version"></a> [cilium\_version](#input\_cilium\_version) | Version of the cilium helm chart to install | `string` | `"1.18.3"` | no |
| <a name="input_cluster_autoscaler"></a> [cluster\_autoscaler](#input\_cluster\_autoscaler) | Install the cluster-autoscaler helm chart to enable horizontal autoscaling of the EKS cluster nodes. All other cluster\_autoscaler variables are ignored if this variable is false | `bool` | `true` | no |
| <a name="input_cluster_autoscaler_values_overrides"></a> [cluster\_autoscaler\_values\_overrides](#input\_cluster\_autoscaler\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_cluster_autoscaler_version"></a> [cluster\_autoscaler\_version](#input\_cluster\_autoscaler\_version) | Version of the cluster-autoscaler helm chart to install | `string` | `null` | no |
| <a name="input_create_acm_certificate"></a> [create\_acm\_certificate](#input\_create\_acm\_certificate) | Create a new ACM certificate for the ingress load balancer to use. Ignored if existing\_acm\_certificate\_arn is specified. | `bool` | `true` | no |
| <a name="input_create_app_identity"></a> [create\_app\_identity](#input\_create\_app\_identity) | Create an IAM role for the DataRobot application service accounts | `bool` | `true` | no |
| <a name="input_create_container_registry"></a> [create\_container\_registry](#input\_create\_container\_registry) | Create DataRobot image builder container repositories in Amazon Elastic Container Registry | `bool` | `true` | no |
| <a name="input_create_dns_zones"></a> [create\_dns\_zones](#input\_create\_dns\_zones) | Create DNS zones for domain\_name. Ignored if existing\_public\_route53\_zone\_id and existing\_private\_route53\_zone\_id are specified. | `bool` | `true` | no |
| <a name="input_create_ingress_vpce_service"></a> [create\_ingress\_vpce\_service](#input\_create\_ingress\_vpce\_service) | Expose the internal NLB created by the ingress-nginx controller as a VPC Endpoint Service. Only applies if internet\_facing\_ingress\_lb is false. | `bool` | `false` | no |
| <a name="input_create_kubernetes_cluster"></a> [create\_kubernetes\_cluster](#input\_create\_kubernetes\_cluster) | Create a new Amazon Elastic Kubernetes Cluster. All kubernetes and helm chart variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_create_mongodb"></a> [create\_mongodb](#input\_create\_mongodb) | Whether to create a MongoDB Atlas instance | `bool` | `false` | no |
| <a name="input_create_network"></a> [create\_network](#input\_create\_network) | Create a new Virtual Private Cloud. Ignored if an existing existing\_vpc\_id is specified. | `bool` | `true` | no |
| <a name="input_create_postgres"></a> [create\_postgres](#input\_create\_postgres) | Whether to create a RDS postgres instance | `bool` | `false` | no |
| <a name="input_create_rabbitmq"></a> [create\_rabbitmq](#input\_create\_rabbitmq) | Whether to create an AMQ RabbitMQ instance | `bool` | `false` | no |
| <a name="input_create_redis"></a> [create\_redis](#input\_create\_redis) | Whether to create a Elasticache Redis instance | `bool` | `false` | no |
| <a name="input_create_storage"></a> [create\_storage](#input\_create\_storage) | Create a new S3 storage bucket to use for DataRobot application file storage. Ignored if an existing\_s3\_bucket\_id is specified. | `bool` | `true` | no |
| <a name="input_custom_private_endpoints"></a> [custom\_private\_endpoints](#input\_custom\_private\_endpoints) | Configuration for the specific endpoint | <pre>list(object({<br/>    service_name     = string<br/>    private_dns_zone = optional(string, "")<br/>    private_dns_name = optional(string, "")<br/>  }))</pre> | `[]` | no |
| <a name="input_datarobot_namespace"></a> [datarobot\_namespace](#input\_datarobot\_namespace) | Kubernetes namespace in which the DataRobot application will be installed | `string` | `"dr-app"` | no |
| <a name="input_descheduler"></a> [descheduler](#input\_descheduler) | Install the descheduler helm chart to enable rescheduling of pods. All other descheduler variables are ignored if this variable is false | `bool` | `true` | no |
| <a name="input_descheduler_values_overrides"></a> [descheduler\_values\_overrides](#input\_descheduler\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_descheduler_version"></a> [descheduler\_version](#input\_descheduler\_version) | Version of the descheduler helm chart to install | `string` | `null` | no |
| <a name="input_dns_zones_force_destroy"></a> [dns\_zones\_force\_destroy](#input\_dns\_zones\_force\_destroy) | Force destroy the public and private Route53 zones. Ignored if an existing route53\_zone\_id is specified or create\_dns\_zones is false. | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Name of the domain to use for the DataRobot application. If create\_dns\_zones is true then zones will be created for this domain. It is also used by ACM for DNS validation and as a domain filter by the external-dns helm chart. | `string` | `""` | no |
| <a name="input_ecr_repositories"></a> [ecr\_repositories](#input\_ecr\_repositories) | Repositories to create. Names are prefixed with `name` variable as in `name`/`repository`. | `set(string)` | <pre>[<br/>  "base-image",<br/>  "custom-apps/managed-image",<br/>  "custom-jobs/managed-image",<br/>  "ephemeral-image",<br/>  "managed-image",<br/>  "services/custom-model-conversion",<br/>  "spark-batch-image"<br/>]</pre> | no |
| <a name="input_ecr_repositories_force_destroy"></a> [ecr\_repositories\_force\_destroy](#input\_ecr\_repositories\_force\_destroy) | Force destroy the ECR repositories. Ignored if create\_container\_registry is false. | `bool` | `false` | no |
| <a name="input_ecr_repositories_scan_on_push"></a> [ecr\_repositories\_scan\_on\_push](#input\_ecr\_repositories\_scan\_on\_push) | Indicates whether images are scanned after being pushed to the repository (`true`) or not scanned (`false`) | `bool` | `false` | no |
| <a name="input_existing_acm_certificate_arn"></a> [existing\_acm\_certificate\_arn](#input\_existing\_acm\_certificate\_arn) | ARN of existing ACM certificate to use with the ingress load balancer created by the ingress\_nginx module. When specified, create\_acm\_certificate will be ignored. | `string` | `null` | no |
| <a name="input_existing_app_role_arn"></a> [existing\_app\_role\_arn](#input\_existing\_app\_role\_arn) | ARN of existing IAM role which represents the DataRobot application | `string` | `null` | no |
| <a name="input_existing_eks_cluster_name"></a> [existing\_eks\_cluster\_name](#input\_existing\_eks\_cluster\_name) | Name of existing EKS cluster to use. When specified, all other kubernetes variables will be ignored. | `string` | `null` | no |
| <a name="input_existing_ingress_lb_arn"></a> [existing\_ingress\_lb\_arn](#input\_existing\_ingress\_lb\_arn) | ARN of an existing ingress load balancer to expose as a VPC Endpoint Service. When specified, the load balancer created by the ingress\_nginx module will not be used. | `string` | `null` | no |
| <a name="input_existing_kubernetes_node_subnets"></a> [existing\_kubernetes\_node\_subnets](#input\_existing\_kubernetes\_node\_subnets) | List of existing subnet IDs to be used for the EKS cluster. Required when an existing\_network\_id is specified. Ignored if create\_network is true and no existing\_network\_id is specified. Subnets must adhere to VPC requirements and considerations https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html. | `list(string)` | `null` | no |
| <a name="input_existing_mongodb_subnets"></a> [existing\_mongodb\_subnets](#input\_existing\_mongodb\_subnets) | List of existing subnet IDs to be used for the MongoDB Atlas instance. Required when an existing\_network\_id is specified. | `list(string)` | `null` | no |
| <a name="input_existing_postgres_subnets"></a> [existing\_postgres\_subnets](#input\_existing\_postgres\_subnets) | List of existing subnet IDs to be used for the RDS postgres instance. Required when an existing\_network\_id is specified. | `list(string)` | `null` | no |
| <a name="input_existing_private_route53_zone_id"></a> [existing\_private\_route53\_zone\_id](#input\_existing\_private\_route53\_zone\_id) | ID of existing private Route53 hosted zone to use for private DNS records created by external-dns. This is required when create\_dns\_zones is false and ingress\_nginx is true with internet\_facing\_ingress\_lb false. | `string` | `null` | no |
| <a name="input_existing_public_route53_zone_id"></a> [existing\_public\_route53\_zone\_id](#input\_existing\_public\_route53\_zone\_id) | ID of existing public Route53 hosted zone to use for public DNS records created by external-dns and ACM certificate validation. This is required when create\_dns\_zones is false and ingress\_nginx and internet\_facing\_ingress\_lb are true or when create\_acm\_certificate is true. | `string` | `null` | no |
| <a name="input_existing_rabbitmq_subnets"></a> [existing\_rabbitmq\_subnets](#input\_existing\_rabbitmq\_subnets) | List of existing subnet IDs to be used for the AMQ RabbitMQ instance. Required when an existing\_network\_id is specified. | `list(string)` | `null` | no |
| <a name="input_existing_redis_subnets"></a> [existing\_redis\_subnets](#input\_existing\_redis\_subnets) | List of existing subnet IDs to be used for the Elasticache Redis instance. Required when an existing\_network\_id is specified. | `list(string)` | `null` | no |
| <a name="input_existing_s3_bucket_id"></a> [existing\_s3\_bucket\_id](#input\_existing\_s3\_bucket\_id) | ID of existing S3 storage bucket to use for DataRobot application file storage. When specified, all other storage variables will be ignored. | `string` | `null` | no |
| <a name="input_existing_vpc_id"></a> [existing\_vpc\_id](#input\_existing\_vpc\_id) | ID of an existing VPC to use. When specified, other network variables are ignored. | `string` | `null` | no |
| <a name="input_external_dns"></a> [external\_dns](#input\_external\_dns) | Install the external\_dns helm chart to create DNS records for ingress resources matching the domain\_name variable. All other external\_dns variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_external_dns_values_overrides"></a> [external\_dns\_values\_overrides](#input\_external\_dns\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_external_dns_version"></a> [external\_dns\_version](#input\_external\_dns\_version) | Version of the external-dns helm chart to install | `string` | `null` | no |
| <a name="input_external_secrets"></a> [external\_secrets](#input\_external\_secrets) | Install the external\_secrets helm chart to manage external secrets resources in the EKS cluster. All other external\_secrets variables are ignored if this variable is false. | `bool` | `false` | no |
| <a name="input_external_secrets_secrets_manager_arns"></a> [external\_secrets\_secrets\_manager\_arns](#input\_external\_secrets\_secrets\_manager\_arns) | List of Secrets Manager ARNs that contain secrets to mount using External Secrets | `list(string)` | `[]` | no |
| <a name="input_external_secrets_values_overrides"></a> [external\_secrets\_values\_overrides](#input\_external\_secrets\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_external_secrets_version"></a> [external\_secrets\_version](#input\_external\_secrets\_version) | Version of the external-secrets helm chart to install | `string` | `null` | no |
| <a name="input_fips_enabled"></a> [fips\_enabled](#input\_fips\_enabled) | Enable FIPS endpoints for AWS services | `bool` | `false` | no |
| <a name="input_ingress_nginx"></a> [ingress\_nginx](#input\_ingress\_nginx) | Install the ingress-nginx helm chart to use as the ingress controller for the EKS cluster. All other ingress\_nginx variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_ingress_nginx_values_overrides"></a> [ingress\_nginx\_values\_overrides](#input\_ingress\_nginx\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_ingress_nginx_version"></a> [ingress\_nginx\_version](#input\_ingress\_nginx\_version) | Version of the ingress-nginx helm chart to install | `string` | `null` | no |
| <a name="input_ingress_vpce_service_allowed_principals"></a> [ingress\_vpce\_service\_allowed\_principals](#input\_ingress\_vpce\_service\_allowed\_principals) | The ARNs of one or more principals allowed to discover the endpoint service. Only applies if internet\_facing\_ingress\_lb is false. | `list(string)` | `null` | no |
| <a name="input_install_helm_charts"></a> [install\_helm\_charts](#input\_install\_helm\_charts) | Whether to install helm charts into the target EKS cluster. All other helm chart variables are ignored if this is `false`. | `bool` | `true` | no |
| <a name="input_internet_facing_ingress_lb"></a> [internet\_facing\_ingress\_lb](#input\_internet\_facing\_ingress\_lb) | Determines the type of NLB created for EKS ingress. If true, an internet-facing NLB will be created. If false, an internal NLB will be created. Ignored when ingress\_nginx is false. | `bool` | `true` | no |
| <a name="input_kubernetes_authentication_mode"></a> [kubernetes\_authentication\_mode](#input\_kubernetes\_authentication\_mode) | The authentication mode for the cluster. Valid values are `CONFIG_MAP`, `API` or `API_AND_CONFIG_MAP` | `string` | `"API_AND_CONFIG_MAP"` | no |
| <a name="input_kubernetes_cluster_access_entries"></a> [kubernetes\_cluster\_access\_entries](#input\_kubernetes\_cluster\_access\_entries) | Map of access entries to add to the cluster | `any` | `{}` | no |
| <a name="input_kubernetes_cluster_addons"></a> [kubernetes\_cluster\_addons](#input\_kubernetes\_cluster\_addons) | Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `name` | `any` | <pre>{<br/>  "coredns": {},<br/>  "eks-pod-identity-agent": {<br/>    "before_compute": true,<br/>    "configuration_values": "{\"agent\": {\"additionalArgs\": {\"-b\": \"169.254.170.23\"}}}"<br/>  },<br/>  "kube-proxy": {},<br/>  "vpc-cni": {<br/>    "before_compute": true,<br/>    "configuration_values": "{\"enableNetworkPolicy\": \"true\", \"env\": {\"ENABLE_PREFIX_DELEGATION\": \"true\", \"WARM_PREFIX_TARGET\": \"1\"}}",<br/>    "resolve_conflicts_on_create": "OVERWRITE"<br/>  }<br/>}</pre> | no |
| <a name="input_kubernetes_cluster_encryption_config"></a> [kubernetes\_cluster\_encryption\_config](#input\_kubernetes\_cluster\_encryption\_config) | Configuration block with encryption configuration for the cluster. To disable secret encryption, set this value to `{}` | `any` | <pre>{<br/>  "resources": [<br/>    "secrets"<br/>  ]<br/>}</pre> | no |
| <a name="input_kubernetes_cluster_endpoint_private_access_cidrs"></a> [kubernetes\_cluster\_endpoint\_private\_access\_cidrs](#input\_kubernetes\_cluster\_endpoint\_private\_access\_cidrs) | List of additional CIDR blocks allowed to access the Amazon EKS private API server endpoint. By default only the kubernetes nodes are allowed, if any other hosts such as a provisioner need to access the EKS private API endpoint they need to be added here. | `list(string)` | `[]` | no |
| <a name="input_kubernetes_cluster_endpoint_public_access"></a> [kubernetes\_cluster\_endpoint\_public\_access](#input\_kubernetes\_cluster\_endpoint\_public\_access) | Indicates whether or not the Amazon EKS public API server endpoint is enabled | `bool` | `true` | no |
| <a name="input_kubernetes_cluster_endpoint_public_access_cidrs"></a> [kubernetes\_cluster\_endpoint\_public\_access\_cidrs](#input\_kubernetes\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_kubernetes_cluster_version"></a> [kubernetes\_cluster\_version](#input\_kubernetes\_cluster\_version) | EKS cluster version | `string` | `"1.33"` | no |
| <a name="input_kubernetes_enable_auto_mode_custom_tags"></a> [kubernetes\_enable\_auto\_mode\_custom\_tags](#input\_kubernetes\_enable\_auto\_mode\_custom\_tags) | Determines whether to enable permissions for custom tags resources created by EKS Auto Mode | `bool` | `true` | no |
| <a name="input_kubernetes_enable_cluster_creator_admin_permissions"></a> [kubernetes\_enable\_cluster\_creator\_admin\_permissions](#input\_kubernetes\_enable\_cluster\_creator\_admin\_permissions) | Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry | `bool` | `true` | no |
| <a name="input_kubernetes_enable_irsa"></a> [kubernetes\_enable\_irsa](#input\_kubernetes\_enable\_irsa) | Determines whether to create an OpenID Connect Provider for EKS to enable IRSA | `bool` | `true` | no |
| <a name="input_kubernetes_iam_role_arn"></a> [kubernetes\_iam\_role\_arn](#input\_kubernetes\_iam\_role\_arn) | Existing IAM role ARN for the cluster. If not specified, a new one will be created. | `string` | `null` | no |
| <a name="input_kubernetes_iam_role_name"></a> [kubernetes\_iam\_role\_name](#input\_kubernetes\_iam\_role\_name) | Name to use on IAM role created | `string` | `null` | no |
| <a name="input_kubernetes_iam_role_permissions_boundary"></a> [kubernetes\_iam\_role\_permissions\_boundary](#input\_kubernetes\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_kubernetes_iam_role_use_name_prefix"></a> [kubernetes\_iam\_role\_use\_name\_prefix](#input\_kubernetes\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name (`kubernetes_iam_role_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_kubernetes_node_groups"></a> [kubernetes\_node\_groups](#input\_kubernetes\_node\_groups) | Map of EKS managed node groups. See https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/eks-managed-node-group for further configuration options. | `any` | <pre>{<br/>  "g4dn-2x": {<br/>    "ami_type": "AL2023_x86_64_NVIDIA",<br/>    "block_device_mappings": {<br/>      "xvda": {<br/>        "device_name": "/dev/xvda",<br/>        "ebs": {<br/>          "encrypted": true,<br/>          "volume_size": 200,<br/>          "volume_type": "gp3"<br/>        }<br/>      }<br/>    },<br/>    "create": true,<br/>    "desired_size": 0,<br/>    "instance_types": [<br/>      "g4dn.2xlarge"<br/>    ],<br/>    "labels": {<br/>      "datarobot.com/gpu-type": "nvidia-t4-2x",<br/>      "datarobot.com/node-capability": "gpu"<br/>    },<br/>    "max_size": 10,<br/>    "min_size": 0,<br/>    "taints": {<br/>      "nvidia_gpu": {<br/>        "effect": "NO_SCHEDULE",<br/>        "key": "nvidia.com/gpu",<br/>        "value": "true"<br/>      }<br/>    }<br/>  },<br/>  "r-4x": {<br/>    "ami_type": "AL2023_x86_64_STANDARD",<br/>    "block_device_mappings": {<br/>      "xvda": {<br/>        "device_name": "/dev/xvda",<br/>        "ebs": {<br/>          "encrypted": true,<br/>          "volume_size": 200,<br/>          "volume_type": "gp3"<br/>        }<br/>      }<br/>    },<br/>    "create": true,<br/>    "desired_size": 2,<br/>    "instance_types": [<br/>      "r6a.4xlarge",<br/>      "r6i.4xlarge",<br/>      "r5.4xlarge",<br/>      "r4.4xlarge"<br/>    ],<br/>    "labels": {<br/>      "datarobot.com/node-capability": "cpu"<br/>    },<br/>    "max_size": 10,<br/>    "min_size": 1,<br/>    "taints": {}<br/>  }<br/>}</pre> | no |
| <a name="input_kubernetes_node_security_group_additional_rules"></a> [kubernetes\_node\_security\_group\_additional\_rules](#input\_kubernetes\_node\_security\_group\_additional\_rules) | List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source | `any` | `{}` | no |
| <a name="input_kubernetes_node_security_group_enable_recommended_rules"></a> [kubernetes\_node\_security\_group\_enable\_recommended\_rules](#input\_kubernetes\_node\_security\_group\_enable\_recommended\_rules) | Determines whether to enable recommended security group rules for the node security group created. This includes node-to-node TCP ingress on ephemeral ports and allows all egress traffic | `bool` | `true` | no |
| <a name="input_kyverno"></a> [kyverno](#input\_kyverno) | Install the kyverno helm chart to manage policies within the Kubernetes cluster | `bool` | `false` | no |
| <a name="input_kyverno_notation_aws"></a> [kyverno\_notation\_aws](#input\_kyverno\_notation\_aws) | Install kyverno-notation-aws helm chart which executes the AWS Signer plugin for Notation to verify image signatures and attestations. | `bool` | `false` | no |
| <a name="input_kyverno_notation_aws_chart_version"></a> [kyverno\_notation\_aws\_chart\_version](#input\_kyverno\_notation\_aws\_chart\_version) | Version of the kyverno-notation-aws helm chart to install | `string` | `null` | no |
| <a name="input_kyverno_notation_aws_values_overrides"></a> [kyverno\_notation\_aws\_values\_overrides](#input\_kyverno\_notation\_aws\_values\_overrides) | Values in raw yaml format to pass to the kyverno-notation-aws helm chart. | `string` | `null` | no |
| <a name="input_kyverno_policies"></a> [kyverno\_policies](#input\_kyverno\_policies) | Install the Pod Security Standard policies | `bool` | `true` | no |
| <a name="input_kyverno_policies_chart_version"></a> [kyverno\_policies\_chart\_version](#input\_kyverno\_policies\_chart\_version) | Version of the kyverno-policies helm chart to install | `string` | `null` | no |
| <a name="input_kyverno_policies_values_overrides"></a> [kyverno\_policies\_values\_overrides](#input\_kyverno\_policies\_values\_overrides) | Values in raw yaml format to pass to the kyverno-policies helm chart. | `string` | `null` | no |
| <a name="input_kyverno_signer_profile_arn"></a> [kyverno\_signer\_profile\_arn](#input\_kyverno\_signer\_profile\_arn) | ARN of the signer profile to use for image signature verification with kyverno-notation-aws. Required if kyverno\_notation\_aws is true. | `string` | `null` | no |
| <a name="input_kyverno_values_overrides"></a> [kyverno\_values\_overrides](#input\_kyverno\_values\_overrides) | Values in raw yaml format to pass to the kyverno helm chart. | `string` | `null` | no |
| <a name="input_kyverno_version"></a> [kyverno\_version](#input\_kyverno\_version) | Version of the kyverno helm chart to install | `string` | `null` | no |
| <a name="input_metrics_server"></a> [metrics\_server](#input\_metrics\_server) | Install the metrics-server helm chart to expose resource metrics for Kubernetes built-in autoscaling pipelines. All other metrics\_server variables are ignored if this variable is false. | `bool` | `true` | no |
| <a name="input_metrics_server_values_overrides"></a> [metrics\_server\_values\_overrides](#input\_metrics\_server\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_metrics_server_version"></a> [metrics\_server\_version](#input\_metrics\_server\_version) | Version of the metrics-server helm chart to install | `string` | `null` | no |
| <a name="input_mongodb_admin_arns"></a> [mongodb\_admin\_arns](#input\_mongodb\_admin\_arns) | List of AWS IAM Principal ARNs to provide admin access to | `set(string)` | `[]` | no |
| <a name="input_mongodb_admin_username"></a> [mongodb\_admin\_username](#input\_mongodb\_admin\_username) | MongoDB admin username | `string` | `"pcs-mongodb"` | no |
| <a name="input_mongodb_atlas_auto_scaling_disk_gb_enabled"></a> [mongodb\_atlas\_auto\_scaling\_disk\_gb\_enabled](#input\_mongodb\_atlas\_auto\_scaling\_disk\_gb\_enabled) | Enable Atlas disk size autoscaling | `bool` | `true` | no |
| <a name="input_mongodb_atlas_disk_size"></a> [mongodb\_atlas\_disk\_size](#input\_mongodb\_atlas\_disk\_size) | Starting atlas disk size | `string` | `"20"` | no |
| <a name="input_mongodb_atlas_instance_type"></a> [mongodb\_atlas\_instance\_type](#input\_mongodb\_atlas\_instance\_type) | atlas instance type | `string` | `"M30"` | no |
| <a name="input_mongodb_atlas_org_id"></a> [mongodb\_atlas\_org\_id](#input\_mongodb\_atlas\_org\_id) | Atlas organization ID | `string` | `null` | no |
| <a name="input_mongodb_atlas_private_key"></a> [mongodb\_atlas\_private\_key](#input\_mongodb\_atlas\_private\_key) | Private API key for Mongo Atlas | `string` | `""` | no |
| <a name="input_mongodb_atlas_public_key"></a> [mongodb\_atlas\_public\_key](#input\_mongodb\_atlas\_public\_key) | Public API key for Mongo Atlas | `string` | `""` | no |
| <a name="input_mongodb_audit_enable"></a> [mongodb\_audit\_enable](#input\_mongodb\_audit\_enable) | Enable database auditing for production instances only(cost incurred 10%) | `bool` | `false` | no |
| <a name="input_mongodb_enable_slack_alerts"></a> [mongodb\_enable\_slack\_alerts](#input\_mongodb\_enable\_slack\_alerts) | Enable alert notifications to a Slack channel. When `true`, `slack_api_token` and `slack_notification_channel` must be set. | `string` | `false` | no |
| <a name="input_mongodb_slack_api_token"></a> [mongodb\_slack\_api\_token](#input\_mongodb\_slack\_api\_token) | Slack API token to use for alert notifications. Required when `enable_slack_alerts` is `true`. | `string` | `null` | no |
| <a name="input_mongodb_slack_notification_channel"></a> [mongodb\_slack\_notification\_channel](#input\_mongodb\_slack\_notification\_channel) | Slack channel to send alert notifications to. Required when `enable_slack_alerts` is `true`. | `string` | `null` | no |
| <a name="input_mongodb_termination_protection_enabled"></a> [mongodb\_termination\_protection\_enabled](#input\_mongodb\_termination\_protection\_enabled) | Enable protection to avoid accidental production cluster termination | `bool` | `false` | no |
| <a name="input_mongodb_version"></a> [mongodb\_version](#input\_mongodb\_version) | MongoDB version | `string` | `"7.0"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to use as a prefix for created resources | `string` | n/a | yes |
| <a name="input_network_address_space"></a> [network\_address\_space](#input\_network\_address\_space) | CIDR block to be used for the new VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_network_cloudwatch_log_group_retention_in_days"></a> [network\_cloudwatch\_log\_group\_retention\_in\_days](#input\_network\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days to retain log events. Set to `0` to keep logs indefinitely | `number` | `7` | no |
| <a name="input_network_enable_vpc_flow_logs"></a> [network\_enable\_vpc\_flow\_logs](#input\_network\_enable\_vpc\_flow\_logs) | Enable VPC Flow Logs for the created VPC | `bool` | `false` | no |
| <a name="input_network_private_endpoints"></a> [network\_private\_endpoints](#input\_network\_private\_endpoints) | List of AWS services to create interface VPC endpoints for | `list(string)` | <pre>[<br/>  "s3",<br/>  "ec2",<br/>  "ecr.api",<br/>  "ecr.dkr",<br/>  "elasticloadbalancing",<br/>  "logs",<br/>  "sts",<br/>  "eks-auth",<br/>  "eks"<br/>]</pre> | no |
| <a name="input_network_s3_private_dns_enabled"></a> [network\_s3\_private\_dns\_enabled](#input\_network\_s3\_private\_dns\_enabled) | Enable private DNS for the S3 VPC endpoint. Currently not supported in GovCloud regions https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-s3.html. | `bool` | `true` | no |
| <a name="input_nvidia_gpu_operator"></a> [nvidia\_gpu\_operator](#input\_nvidia\_gpu\_operator) | Install the nvidia-gpu-operator helm chart to manage NVIDIA GPU resources in the EKS cluster. All other nvidia\_gpu\_operator variables are ignored if this variable is false. | `bool` | `false` | no |
| <a name="input_nvidia_gpu_operator_values_overrides"></a> [nvidia\_gpu\_operator\_values\_overrides](#input\_nvidia\_gpu\_operator\_values\_overrides) | Values in raw yaml format to pass to helm. | `string` | `null` | no |
| <a name="input_nvidia_gpu_operator_version"></a> [nvidia\_gpu\_operator\_version](#input\_nvidia\_gpu\_operator\_version) | Version of the nvidia-gpu-operator helm chart to install | `string` | `null` | no |
| <a name="input_postgres_additional_ingress_cidr_blocks"></a> [postgres\_additional\_ingress\_cidr\_blocks](#input\_postgres\_additional\_ingress\_cidr\_blocks) | Additional CIDR blocks allowed to reach the PostgreSQL port | `list(string)` | `[]` | no |
| <a name="input_postgres_allocated_storage"></a> [postgres\_allocated\_storage](#input\_postgres\_allocated\_storage) | The allocated storage in gigabytes | `number` | `20` | no |
| <a name="input_postgres_backup_retention_period"></a> [postgres\_backup\_retention\_period](#input\_postgres\_backup\_retention\_period) | The days to retain backups for | `number` | `7` | no |
| <a name="input_postgres_deletion_protection"></a> [postgres\_deletion\_protection](#input\_postgres\_deletion\_protection) | The database can't be deleted when this value is set to true | `bool` | `false` | no |
| <a name="input_postgres_engine_version"></a> [postgres\_engine\_version](#input\_postgres\_engine\_version) | The engine version to use | `string` | `"13"` | no |
| <a name="input_postgres_instance_class"></a> [postgres\_instance\_class](#input\_postgres\_instance\_class) | The instance type of the RDS instance | `string` | `"db.m6g.large"` | no |
| <a name="input_postgres_max_allocated_storage"></a> [postgres\_max\_allocated\_storage](#input\_postgres\_max\_allocated\_storage) | Specifies the value for Storage Autoscaling | `number` | `500` | no |
| <a name="input_rabbitmq_authentication_strategy"></a> [rabbitmq\_authentication\_strategy](#input\_rabbitmq\_authentication\_strategy) | Authentication strategy used to secure the broker | `string` | `"simple"` | no |
| <a name="input_rabbitmq_auto_minor_version_upgrade"></a> [rabbitmq\_auto\_minor\_version\_upgrade](#input\_rabbitmq\_auto\_minor\_version\_upgrade) | Whether to automatically upgrade to new minor versions of brokers as Amazon MQ makes releases available. | `bool` | `true` | no |
| <a name="input_rabbitmq_cloudwatch_log_group_retention_in_days"></a> [rabbitmq\_cloudwatch\_log\_group\_retention\_in\_days](#input\_rabbitmq\_cloudwatch\_log\_group\_retention\_in\_days) | CloudWatch log retention for RabbitMQ | `string` | `90` | no |
| <a name="input_rabbitmq_enable_cloudwatch_logs"></a> [rabbitmq\_enable\_cloudwatch\_logs](#input\_rabbitmq\_enable\_cloudwatch\_logs) | Export RabbitMQ logs to CloudWatch | `bool` | `false` | no |
| <a name="input_rabbitmq_engine_version"></a> [rabbitmq\_engine\_version](#input\_rabbitmq\_engine\_version) | Version of the broker engine. See the [AmazonMQ Broker Engine docs](https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/broker-engine.html) for supported versions. | `string` | `"3.13"` | no |
| <a name="input_rabbitmq_instance_type"></a> [rabbitmq\_instance\_type](#input\_rabbitmq\_instance\_type) | Broker's instance type. For example, `mq.t3.micro`, `mq.m5.large`. | `string` | `"mq.m5.large"` | no |
| <a name="input_rabbitmq_username"></a> [rabbitmq\_username](#input\_rabbitmq\_username) | RabbitMQ broker usernmae | `string` | `"pcs-rabbitmq"` | no |
| <a name="input_redis_engine_version"></a> [redis\_engine\_version](#input\_redis\_engine\_version) | The Elasticache engine version to use | `string` | `"7.1"` | no |
| <a name="input_redis_node_type"></a> [redis\_node\_type](#input\_redis\_node\_type) | The instance type of the RDS instance | `string` | `"cache.t4g.medium"` | no |
| <a name="input_redis_snapshot_retention"></a> [redis\_snapshot\_retention](#input\_redis\_snapshot\_retention) | Number of days for which ElastiCache will retain automatic cache cluster snapshots before deleting them | `number` | `7` | no |
| <a name="input_s3_bucket_force_destroy"></a> [s3\_bucket\_force\_destroy](#input\_s3\_bucket\_force\_destroy) | Force destroy the public and private Route53 zones | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all created resources | `map(string)` | <pre>{<br/>  "managed-by": "terraform"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_certificate_arn"></a> [acm\_certificate\_arn](#output\_acm\_certificate\_arn) | ARN of the ACM certificate |
| <a name="output_app_role_arn"></a> [app\_role\_arn](#output\_app\_role\_arn) | ARN of the IAM role to be assumed by the DataRobot app service accounts |
| <a name="output_ecr_repository_urls"></a> [ecr\_repository\_urls](#output\_ecr\_repository\_urls) | URLs of the image builder repositories |
| <a name="output_genai_role_arn"></a> [genai\_role\_arn](#output\_genai\_role\_arn) | ARN of the IAM role assumed by the DataRobot app IRSA when accessing Amazon Bedrock AI Foundational Models |
| <a name="output_ingress_vpce_service_id"></a> [ingress\_vpce\_service\_id](#output\_ingress\_vpce\_service\_id) | Ingress VPCE service ID |
| <a name="output_kubernetes_cluster_certificate_authority_data"></a> [kubernetes\_cluster\_certificate\_authority\_data](#output\_kubernetes\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_kubernetes_cluster_endpoint"></a> [kubernetes\_cluster\_endpoint](#output\_kubernetes\_cluster\_endpoint) | Endpoint for your Kubernetes API server |
| <a name="output_kubernetes_cluster_name"></a> [kubernetes\_cluster\_name](#output\_kubernetes\_cluster\_name) | Name of the EKS cluster |
| <a name="output_kubernetes_cluster_node_groups"></a> [kubernetes\_cluster\_node\_groups](#output\_kubernetes\_cluster\_node\_groups) | EKS cluster node groups |
| <a name="output_mongodb_endpoint"></a> [mongodb\_endpoint](#output\_mongodb\_endpoint) | MongoDB endpoint |
| <a name="output_mongodb_password"></a> [mongodb\_password](#output\_mongodb\_password) | MongoDB admin password |
| <a name="output_postgres_endpoint"></a> [postgres\_endpoint](#output\_postgres\_endpoint) | RDS postgres endpoint |
| <a name="output_postgres_password"></a> [postgres\_password](#output\_postgres\_password) | RDS postgres master password |
| <a name="output_private_route53_zone_arn"></a> [private\_route53\_zone\_arn](#output\_private\_route53\_zone\_arn) | Zone ARN of the private Route53 zone |
| <a name="output_private_route53_zone_id"></a> [private\_route53\_zone\_id](#output\_private\_route53\_zone\_id) | Zone ID of the private Route53 zone |
| <a name="output_public_route53_zone_arn"></a> [public\_route53\_zone\_arn](#output\_public\_route53\_zone\_arn) | Zone ARN of the public Route53 zone |
| <a name="output_public_route53_zone_id"></a> [public\_route53\_zone\_id](#output\_public\_route53\_zone\_id) | Zone ID of the public Route53 zone |
| <a name="output_public_route53_zone_name_servers"></a> [public\_route53\_zone\_name\_servers](#output\_public\_route53\_zone\_name\_servers) | Name servers of Route53 zone |
| <a name="output_rabbitmq_endpoint"></a> [rabbitmq\_endpoint](#output\_rabbitmq\_endpoint) | RabbitMQ AMQP(S) endpoint |
| <a name="output_rabbitmq_password"></a> [rabbitmq\_password](#output\_rabbitmq\_password) | RabbitMQ broker password |
| <a name="output_redis_endpoint"></a> [redis\_endpoint](#output\_redis\_endpoint) | Elasticache redis endpoint |
| <a name="output_redis_password"></a> [redis\_password](#output\_redis\_password) | Elasticache redis auth token |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | Name of the S3 bucket |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_database_subnets"></a> [vpc\_database\_subnets](#output\_vpc\_database\_subnets) | List of IDs of database subnets |
| <a name="output_vpc_database_subnets_cidr_blocks"></a> [vpc\_database\_subnets\_cidr\_blocks](#output\_vpc\_database\_subnets\_cidr\_blocks) | List of CIDR blocks of the database subnets |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
| <a name="output_vpc_private_route_table_ids"></a> [vpc\_private\_route\_table\_ids](#output\_vpc\_private\_route\_table\_ids) | List of IDs of private route tables |
| <a name="output_vpc_private_subnets"></a> [vpc\_private\_subnets](#output\_vpc\_private\_subnets) | List of IDs of private subnets |
| <a name="output_vpc_private_subnets_cidr_blocks"></a> [vpc\_private\_subnets\_cidr\_blocks](#output\_vpc\_private\_subnets\_cidr\_blocks) | List of CIDR blocks of private subnets |
| <a name="output_vpc_public_subnets"></a> [vpc\_public\_subnets](#output\_vpc\_public\_subnets) | List of IDs of public subnets |
| <a name="output_vpc_public_subnets_cidr_blocks"></a> [vpc\_public\_subnets\_cidr\_blocks](#output\_vpc\_public\_subnets\_cidr\_blocks) | List of CIDR blocks of public subnets |
<!-- END_TF_DOCS -->

## Development and Contributing

If you'd like to report an issue or bug, suggest improvements, or contribute code to this project, please refer to [CONTRIBUTING.md](CONTRIBUTING.md).

# Code of Conduct

This project has adopted the Contributor Covenant for its Code of Conduct.
See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) to read it in full.

# License

Licensed under the Apache License 2.0.
See [LICENSE](LICENSE) to read it in full.
