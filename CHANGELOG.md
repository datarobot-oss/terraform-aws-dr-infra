# Changelog

All notable changes are documented in this file.


## v1.1.0

### Updated

- Make toggle variable names more generic and consistent with modules for other cloud providers
- Create GPU node group by default scaled to 0 nodes
- external-dns values now only target ingress resources and use a policy of sync
- ingress-nginx values now correctly set externalTrafficPolicy to Local for internet-facing and allow for empty variables
- Only create public and private DNS zones when needed
- Extensive updates to examples and README


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
