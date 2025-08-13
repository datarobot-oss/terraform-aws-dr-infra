# Changelog

All notable changes are documented in this file.


## v1.4.1

### Added

- VPCE endpoint service for ingress-nginx controller internal LB


## v1.4.0

### Added

- `postgres` and `redis` modules.
- database subnets


## v1.3.3

### Added

- nvidia_gpu_operator helm chart module


## v1.3.2

### Updated
- `helm` provider version to `>= 3.0.2`


## v1.3.1

### Added
- `install_helm_charts` variable to be able to enable/disable installation of all helm charts


## v1.3.0

### Added
- more kubernetes variables generally related to IAM and access control: `kubernetes_enable_irsa`, `kubernetes_cluster_encryption_config`, `kubernetes_enable_auto_mode_custom_tags`, `kubernetes_iam_role_name`, `kubernetes_iam_role_use_name_prefix`, `kubernetes_iam_role_permissions_boundary`, `kubernetes_authentication_mode`, `kubernetes_enable_cluster_creator_admin_permissions`, and `kubernetes_bootstrap_self_managed_addons`

### Updated
- allow for user-specified number of availability zones in the `availability_zones` input variable. additionally, ensure we are only using `available` zones where `opt-in-not-required`
- make kubernetes node groups fully configurable by specifying them in the `kubernetes_node_groups` input variable and specify defaults with `kubernetes_node_group_defaults`
- make kubernetes addons fully configurable by specifying them in the `kubernetes_cluster_addons` input variable

### Removed
- explicit pod identity for VPC CNI (`aws_vpc_cni_ipv4_pod_identity`). this is not required by default because the IAM role created for the EKS managed node groups include the VPC CNI policy.


## v1.2.7

### Updated
- allow use of existing IAM roles for the EKS cluster role and EKS node role


## v1.2.6

### Updated
- default list of network_private_endpoints to s3, ec2, ecr.api, ecr.dkr, elasticloadbalancing, logs, sts, eks-auth, eks


## v1.2.5

### Added
- dynamic reading of AWS partition


## v1.2.4

### Updated
- use helm_release instead of terraform-module/release/helm


## v1.2.3

### Added
- custom-jobs/managed-image and services/custom-model-conversion to ecr_repositories default set


## v1.2.2

### Updated
- ingress-nginx helm chart version to 4.11.5


## v1.2.1

### Updated
- Create one nodegroup per AZ


## v1.2.0

### Added
- Ability to use an existing EKS cluster
- metrics-server and descheduler amenities
- ASG tagging for improved cluster-autoscaler performance
- EKS cluster addon configuration including enableNetworkPolicy=true

### Updated
- All amenities to latest versions


## v1.1.0

### Updated

- Make toggle variable names more generic and consistent with modules for other cloud providers
- Create GPU node group by default scaled to 0 nodes
- external-dns values now only target ingress resources and use a policy of sync
- ingress-nginx values now correctly set externalTrafficPolicy to Local for internet-facing and allow for empty variables
- Only create public and private DNS zones when needed
- Extensive updates to examples and README
- Make helm charts that use pod identities depend on the kubernetes cluster_addons to ensure that the pod identity agents are installed before the helm charts


## v1.0.7

### Updated

- KMS key alias name as a prefix with a unique string appended


## v1.0.6

### Added

- eks_primary_nodegroup_name, eks_primary_nodegroup_labels, eks_gpu_nodegroup_name, eks_gpu_nodegroup_labels variables
- nvidia_device_plugin helm chart module

### Updated

- Default values for eks_gpu_nodegroup_labels and eks_gpu_nodegroup_taints


## v1.0.5

### Added

- vpc_endpoint variable with s3 as the default


## v1.0.4

### Fixed

- Removed explicit module.eks dependencies from helm charts which should decrease the likelihood that the aws_eks_cluster_auth token expires before helm charts can be installed

### Added

- dns_zone_force_destroy, s3_bucket_force_destroy, and ecr_repositories_force_destroy variables

### Updated

- Default IRSA role kubernetes_namespace from dr-core to dr-app


## v1.0.3

### Fixed

- Issue where helm charts failed to install on first run


## v1.0.2

### Fixed

- Race condition when aws-load-balancer-controller helm chart was installed before its pod identity association was created causing it to lack permissions required to create a load balancer

### Added

- Configurable EKS nodegroup taints and AMI types

### Updated

- Examples now source the module from the terraform registry rather than locally


## v1.0.1

### Added

- Variable eks_cluster_endpoint_private_access_cidrs for users to specify additional CIDR blocks allowed to access the EKS private API endpoint

### Updated

- Default eks_primary_nodegroup_instance_types to r6a.4xlarge
- Default eks_primary_nodegroup_desired_size to 5


## v1.0.0

### Added

- Initial module release
