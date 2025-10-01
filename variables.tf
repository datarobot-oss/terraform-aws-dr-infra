variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "domain_name" {
  description = "Name of the domain to use for the DataRobot application. If create_dns_zones is true then zones will be created for this domain. It is also used by ACM for DNS validation and as a domain filter by the external-dns helm chart."
  type        = string
  default     = ""
}

variable "availability_zones" {
  description = "Number of availability zones to deploy into"
  type        = number
  default     = 2
}

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
  default = {
    managed-by = "terraform"
  }
}


################################################################################
# Network
################################################################################

variable "existing_vpc_id" {
  description = "ID of an existing VPC to use. When specified, other network variables are ignored."
  type        = string
  default     = null
}

variable "create_network" {
  description = "Create a new Virtual Private Cloud. Ignored if an existing existing_vpc_id is specified."
  type        = bool
  default     = true
}

variable "network_address_space" {
  description = "CIDR block to be used for the new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "network_private_endpoints" {
  description = "List of AWS services to create interface VPC endpoints for"
  type        = list(string)
  default = [
    "s3",
    "ec2",
    "ecr.api",
    "ecr.dkr",
    "elasticloadbalancing",
    "logs",
    "sts",
    "eks-auth",
    "eks"
  ]
}


################################################################################
# DNS
################################################################################

variable "existing_public_route53_zone_id" {
  description = "ID of existing public Route53 hosted zone to use for public DNS records created by external-dns and ACM certificate validation. This is required when create_dns_zones is false and ingress_nginx and internet_facing_ingress_lb are true or when create_acm_certificate is true."
  type        = string
  default     = null
}

variable "existing_private_route53_zone_id" {
  description = "ID of existing private Route53 hosted zone to use for private DNS records created by external-dns. This is required when create_dns_zones is false and ingress_nginx is true with internet_facing_ingress_lb false."
  type        = string
  default     = null
}

variable "create_dns_zones" {
  description = "Create DNS zones for domain_name. Ignored if existing_public_route53_zone_id and existing_private_route53_zone_id are specified."
  type        = bool
  default     = true
}

variable "dns_zones_force_destroy" {
  description = "Force destroy the public and private Route53 zones. Ignored if an existing route53_zone_id is specified or create_dns_zones is false."
  type        = bool
  default     = false
}


################################################################################
# ACM
################################################################################

variable "existing_acm_certificate_arn" {
  description = "ARN of existing ACM certificate to use with the ingress load balancer created by the ingress_nginx module. When specified, create_acm_certificate will be ignored."
  type        = string
  default     = null
}

variable "create_acm_certificate" {
  description = "Create a new ACM certificate for the ingress load balancer to use. Ignored if existing_acm_certificate_arn is specified."
  type        = bool
  default     = true
}


################################################################################
# Storage
################################################################################

variable "existing_s3_bucket_id" {
  description = "ID of existing S3 storage bucket to use for DataRobot application file storage. When specified, all other storage variables will be ignored."
  type        = string
  default     = null
}

variable "create_storage" {
  description = "Create a new S3 storage bucket to use for DataRobot application file storage. Ignored if an existing_s3_bucket_id is specified."
  type        = bool
  default     = true
}

variable "s3_bucket_force_destroy" {
  description = "Force destroy the public and private Route53 zones"
  type        = bool
  default     = false
}


################################################################################
# Container Registry
################################################################################

variable "create_container_registry" {
  description = "Create DataRobot image builder container repositories in Amazon Elastic Container Registry"
  type        = bool
  default     = true
}

variable "ecr_repositories" {
  description = "Repositories to create. Names are prefixed with `name` variable as in `name`/`repository`."
  type        = set(string)
  default = [
    "base-image",
    "custom-apps/managed-image",
    "custom-jobs/managed-image",
    "ephemeral-image",
    "managed-image",
    "services/custom-model-conversion",
    "spark-batch-image"
  ]
}

variable "ecr_repositories_scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository (`true`) or not scanned (`false`)"
  type        = bool
  default     = false
}

variable "ecr_repositories_force_destroy" {
  description = "Force destroy the ECR repositories. Ignored if create_container_registry is false."
  type        = bool
  default     = false
}


################################################################################
# Kubernetes
################################################################################

variable "existing_eks_cluster_name" {
  description = "Name of existing EKS cluster to use. When specified, all other kubernetes variables will be ignored."
  type        = string
  default     = null
}

variable "create_kubernetes_cluster" {
  description = "Create a new Amazon Elastic Kubernetes Cluster. All kubernetes and helm chart variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "existing_kubernetes_node_subnets" {
  description = "List of existing subnet IDs to be used for the EKS cluster. Required when an existing_network_id is specified. Ignored if create_network is true and no existing_network_id is specified. Subnets must adhere to VPC requirements and considerations https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
  type        = list(string)
  default     = null
}

variable "kubernetes_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.33"
}

variable "kubernetes_authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are `CONFIG_MAP`, `API` or `API_AND_CONFIG_MAP`"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "kubernetes_enable_irsa" {
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "kubernetes_cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster. To disable secret encryption, set this value to `{}`"
  type        = any
  default = {
    resources = ["secrets"]
  }
}

variable "kubernetes_enable_auto_mode_custom_tags" {
  description = "Determines whether to enable permissions for custom tags resources created by EKS Auto Mode"
  type        = bool
  default     = true
}

variable "kubernetes_iam_role_arn" {
  description = "Existing IAM role ARN for the cluster. If not specified, a new one will be created."
  type        = string
  default     = null
}

variable "kubernetes_iam_role_name" {
  description = "Name to use on IAM role created"
  type        = string
  default     = null
}

variable "kubernetes_iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name (`kubernetes_iam_role_name`) is used as a prefix"
  type        = bool
  default     = true
}

variable "kubernetes_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
  type        = string
  default     = null
}

variable "kubernetes_enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry"
  type        = bool
  default     = true
}

variable "kubernetes_cluster_access_entries" {
  description = "Map of access entries to add to the cluster"
  type        = any
  default     = {}
}

variable "kubernetes_cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "kubernetes_cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default = [
    "0.0.0.0/0"
  ]
}

variable "kubernetes_cluster_endpoint_private_access_cidrs" {
  description = "List of additional CIDR blocks allowed to access the Amazon EKS private API server endpoint. By default only the kubernetes nodes are allowed, if any other hosts such as a provisioner need to access the EKS private API endpoint they need to be added here."
  type        = list(string)
  default     = []
}

variable "kubernetes_cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `name`"
  type        = any
  default = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent          = true
      before_compute       = true
      configuration_values = "{\"enableNetworkPolicy\": \"true\", \"env\": {\"ENABLE_PREFIX_DELEGATION\": \"true\", \"WARM_PREFIX_TARGET\": \"1\"}}"
    }
  }
}

variable "kubernetes_node_security_group_additional_rules" {
  description = "List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source"
  type        = any
  default     = {}
}

variable "kubernetes_node_security_group_enable_recommended_rules" {
  description = "Determines whether to enable recommended security group rules for the node security group created. This includes node-to-node TCP ingress on ephemeral ports and allows all egress traffic"
  type        = bool
  default     = true
}

variable "kubernetes_node_groups" {
  description = "Map of EKS managed node groups. See https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/eks-managed-node-group for further configuration options."
  type        = any
  default = {
    drcpu = {
      create         = true
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["r6a.4xlarge", "r6i.4xlarge", "r5.4xlarge", "r4.4xlarge"]
      desired_size   = 2
      min_size       = 1
      max_size       = 10
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_type = "gp3"
            volume_size = 200
            encrypted   = true
          }
        }
      }
      labels = {
        "datarobot.com/node-capability" = "cpu"
      }
      taints = {}
    }
    drgpu = {
      create         = true
      ami_type       = "AL2023_x86_64_NVIDIA"
      instance_types = ["g4dn.2xlarge"]
      desired_size   = 0
      min_size       = 0
      max_size       = 10
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_type = "gp3"
            volume_size = 200
            encrypted   = true
          }
        }
      }
      labels = {
        "datarobot.com/node-capability" = "gpu"
        "datarobot.com/node-type"       = "on-demand"
        "datarobot.com/gpu-type"        = "nvidia-t4-2x"
      }
      taints = {
        nvidia_gpu = {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }
}


################################################################################
# App Identity
################################################################################

variable "existing_app_role_arn" {
  description = "ARN of existing IAM role which represents the DataRobot application"
  type        = string
  default     = null
}

variable "create_app_identity" {
  description = "Create an IAM role for the DataRobot application service accounts"
  type        = bool
  default     = true
}

variable "datarobot_namespace" {
  description = "Kubernetes namespace in which the DataRobot application will be installed"
  type        = string
  default     = "dr-app"
}


################################################################################
# PostgreSQL
################################################################################

variable "create_postgres" {
  description = "Whether to create a RDS postgres instance"
  type        = bool
  default     = false
}

variable "existing_postgres_subnets" {
  description = "List of existing subnet IDs to be used for the RDS postgres instance. Required when an existing_network_id is specified."
  type        = list(string)
  default     = null
}

variable "postgres_engine_version" {
  description = "The engine version to use"
  type        = string
  default     = "13"
}

variable "postgres_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.m6g.large"
}

variable "postgres_allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "postgres_max_allocated_storage" {
  description = "Specifies the value for Storage Autoscaling"
  type        = number
  default     = 500
}

variable "postgres_backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "postgres_deletion_protection" {
  description = "The database can't be deleted when this value is set to true"
  type        = bool
  default     = false
}


################################################################################
# Redis
################################################################################

variable "create_redis" {
  description = "Whether to create a Elasticache Redis instance"
  type        = bool
  default     = false
}

variable "existing_redis_subnets" {
  description = "List of existing subnet IDs to be used for the Elasticache Redis instance. Required when an existing_network_id is specified."
  type        = list(string)
  default     = null
}

variable "redis_engine_version" {
  description = "The Elasticache engine version to use"
  type        = string
  default     = "7.1"
}

variable "redis_node_type" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "cache.t4g.medium"
}


################################################################################
# MongoDB
################################################################################

variable "create_mongodb" {
  description = "Whether to create a MongoDB Atlas instance"
  type        = bool
  default     = false
}

variable "existing_mongodb_subnets" {
  description = "List of existing subnet IDs to be used for the MongoDB Atlas instance. Required when an existing_network_id is specified."
  type        = list(string)
  default     = null
}

variable "mongodb_version" {
  description = "MongoDB version"
  type        = string
  default     = "7.0"
}

variable "mongodb_atlas_org_id" {
  description = "Atlas organization ID"
  type        = string
  default     = null
}

variable "mongodb_atlas_public_key" {
  description = "Public API key for Mongo Atlas"
  type        = string
  default     = ""
}

variable "mongodb_atlas_private_key" {
  description = "Private API key for Mongo Atlas"
  type        = string
  default     = ""
}

variable "mongodb_termination_protection_enabled" {
  description = "Enable protection to avoid accidental production cluster termination"
  type        = bool
  default     = false
}

variable "mongodb_audit_enable" {
  type        = bool
  description = "Enable database auditing for production instances only(cost incurred 10%)"
  default     = false
}

variable "mongodb_atlas_auto_scaling_disk_gb_enabled" {
  description = "Enable Atlas disk size autoscaling"
  type        = bool
  default     = true
}

variable "mongodb_atlas_disk_size" {
  description = "Starting atlas disk size"
  type        = string
  default     = "20"
}

variable "mongodb_atlas_instance_type" {
  description = "atlas instance type"
  type        = string
  default     = "M30"
}

variable "mongodb_admin_username" {
  description = "MongoDB admin username"
  type        = string
  default     = "pcs-mongodb"
}

variable "mongodb_admin_arns" {
  description = "List of AWS IAM Principal ARNs to provide admin access to"
  type        = set(string)
  default     = []
}

variable "mongodb_enable_slack_alerts" {
  description = "Enable alert notifications to a Slack channel. When `true`, `slack_api_token` and `slack_notification_channel` must be set."
  type        = string
  default     = false
}

variable "mongodb_slack_api_token" {
  description = "Slack API token to use for alert notifications. Required when `enable_slack_alerts` is `true`."
  type        = string
  default     = null
}

variable "mongodb_slack_notification_channel" {
  description = "Slack channel to send alert notifications to. Required when `enable_slack_alerts` is `true`."
  type        = string
  default     = null
}


################################################################################
# Helm Charts
################################################################################

variable "install_helm_charts" {
  description = "Whether to install helm charts into the target EKS cluster. All other helm chart variables are ignored if this is `false`."
  type        = bool
  default     = true
}

variable "aws_ebs_csi_driver" {
  description = "Install the aws-ebs-csi-driver helm chart to enable use of EBS for Kubernetes persistent volumes. All other ebs_csi_driver variables are ignored if this variable is false"
  type        = bool
  default     = true
}

variable "aws_ebs_csi_driver_values" {
  description = "Path to templatefile containing custom values for the aws-ebs-csi-driver helm chart"
  type        = string
  default     = ""
}

variable "aws_ebs_csi_driver_variables" {
  description = "Variables passed to the ebs_csi_driver_values templatefile"
  type        = any
  default     = {}
}

variable "cluster_autoscaler" {
  description = "Install the cluster-autoscaler helm chart to enable horizontal autoscaling of the EKS cluster nodes. All other cluster_autoscaler variables are ignored if this variable is false"
  type        = bool
  default     = true
}

variable "cluster_autoscaler_values" {
  description = "Path to templatefile containing custom values for the cluster-autoscaler helm chart"
  type        = string
  default     = ""
}

variable "cluster_autoscaler_variables" {
  description = "Variables passed to the cluster_autoscaler_values templatefile"
  type        = any
  default     = {}
}

variable "descheduler" {
  description = "Install the descheduler helm chart to enable rescheduling of pods. All other descheduler variables are ignored if this variable is false"
  type        = bool
  default     = true
}

variable "descheduler_values" {
  description = "Path to templatefile containing custom values for the descheduler helm chart"
  type        = string
  default     = ""
}

variable "descheduler_variables" {
  description = "Variables passed to the descheduler templatefile"
  type        = any
  default     = {}
}

variable "aws_load_balancer_controller" {
  description = "Install the aws-load-balancer-controller helm chart to use AWS Network Load Balancers as ingress to the EKS cluster. All other aws_load_balancer_controller variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller_values" {
  description = "Path to templatefile containing custom values for the aws-load-balancer-controller helm chart"
  type        = string
  default     = ""
}

variable "aws_load_balancer_controller_variables" {
  description = "Variables passed to the aws_load_balancer_controller_values templatefile"
  type        = any
  default     = {}
}

variable "ingress_nginx" {
  description = "Install the ingress-nginx helm chart to use as the ingress controller for the EKS cluster. All other ingress_nginx variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "internet_facing_ingress_lb" {
  description = "Determines the type of NLB created for EKS ingress. If true, an internet-facing NLB will be created. If false, an internal NLB will be created. Ignored when ingress_nginx is false."
  type        = bool
  default     = true
}

variable "create_ingress_vpce_service" {
  description = "Expose the internal NLB created by the ingress-nginx controller as a VPC Endpoint Service. Only applies if internet_facing_ingress_lb is false."
  type        = bool
  default     = false
}

variable "ingress_vpce_service_allowed_principals" {
  description = "The ARNs of one or more principals allowed to discover the endpoint service. Only applies if internet_facing_ingress_lb is false."
  type        = list(string)
  default     = null
}

variable "ingress_nginx_values" {
  description = "Path to templatefile containing custom values for the ingress-nginx helm chart."
  type        = string
  default     = ""
}

variable "ingress_nginx_variables" {
  description = "Variables passed to the ingress_nginx_values templatefile"
  type        = any
  default     = {}
}

variable "cert_manager" {
  description = "Install the cert-manager helm chart. All other cert_manager variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "cert_manager_values" {
  description = "Path to templatefile containing custom values for the cert-manager helm chart"
  type        = string
  default     = ""
}

variable "cert_manager_variables" {
  description = "Variables passed to the cert_manager_values templatefile"
  type        = any
  default     = {}
}

variable "external_dns" {
  description = "Install the external_dns helm chart to create DNS records for ingress resources matching the domain_name variable. All other external_dns variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "external_dns_values" {
  description = "Path to templatefile containing custom values for the external-dns helm chart"
  type        = string
  default     = ""
}

variable "external_dns_variables" {
  description = "Variables passed to the external_dns_values templatefile"
  type        = any
  default     = {}
}

variable "nvidia_gpu_operator" {
  description = "Install the nvidia-gpu-operator helm chart to manage NVIDIA GPU resources in the EKS cluster. All other nvidia_gpu_operator variables are ignored if this variable is false."
  type        = bool
  default     = false
}

variable "nvidia_gpu_operator_values" {
  description = "Path to templatefile containing custom values for the nvidia-gpu-operator helm chart"
  type        = string
  default     = ""
}

variable "nvidia_gpu_operator_variables" {
  description = "Variables passed to the nvidia_gpu_operator_values templatefile"
  type        = any
  default     = {}
}

variable "metrics_server" {
  description = "Install the metrics-server helm chart to expose resource metrics for Kubernetes built-in autoscaling pipelines. All other metrics_server variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "metrics_server_values" {
  description = "Path to templatefile containing custom values for the metrics_server helm chart"
  type        = string
  default     = ""
}

variable "metrics_server_variables" {
  description = "Variables passed to the metrics_server_values templatefile"
  type        = any
  default     = {}
}
