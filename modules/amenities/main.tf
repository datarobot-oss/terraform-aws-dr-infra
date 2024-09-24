################################################################################
# cluster-autoscaler
################################################################################

data "aws_region" "current" {}

module "cluster_autoscaler_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"
  count   = var.install_cluster_autoscaler ? 1 : 0

  name = "cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [var.eks_cluster_name]

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = "cluster-autoscaler"
      service_account = "cluster-autoscaler-aws-cluster-autoscaler"
    }
  }

  tags = var.tags
}

module "cluster_autoscaler" {
  source     = "terraform-module/release/helm"
  version    = "~> 2.0"
  count      = var.install_cluster_autoscaler ? 1 : 0
  depends_on = [module.cluster_autoscaler_pod_identity]

  namespace  = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"

  app = {
    name             = "cluster-autoscaler"
    version          = "9.37.0"
    chart            = "cluster-autoscaler"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = var.eks_cluster_name
    },
    {
      name  = "awsRegion"
      value = data.aws_region.current.name
    }
  ]

  values = [
    var.cluster_autoscaler_values != "" ? templatefile(var.cluster_autoscaler_values, var.cluster_autoscaler_variables) : ""
  ]
}


################################################################################
# aws-ebs-csi-driver
################################################################################

module "ebs_csi_driver_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"
  count   = var.install_ebs_csi_driver ? 1 : 0

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = [var.ebs_csi_driver_kms_arn]

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = var.tags
}


module "ebs_csi_driver" {
  source     = "terraform-module/release/helm"
  version    = "2.8.1"
  count      = var.install_ebs_csi_driver ? 1 : 0
  depends_on = [module.ebs_csi_driver_pod_identity]

  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"

  app = {
    name             = "aws-ebs-csi-driver"
    version          = "2.33.0"
    chart            = "aws-ebs-csi-driver"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  values = [
    templatefile("${path.module}/templates/ebs_csi_driver.tftpl", {
      kms_key_arn = var.ebs_csi_driver_kms_arn
    }),
    var.ebs_csi_driver_values != "" ? templatefile(var.ebs_csi_driver_values, var.ebs_csi_driver_variables) : ""
  ]
}


################################################################################
# aws-load-balancer-controller
################################################################################

module "aws_load_balancer_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"
  count   = var.install_aws_load_balancer_controller ? 1 : 0

  name = "aws-lbc"

  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = "aws-load-balancer-controller"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = var.tags
}

module "aws_load_balancer_controller" {
  source     = "terraform-module/release/helm"
  version    = "~> 2.0"
  count      = var.install_aws_load_balancer_controller ? 1 : 0
  depends_on = [module.aws_load_balancer_controller_pod_identity]

  namespace  = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"

  app = {
    name             = "aws-load-balancer-controller"
    version          = "1.8.2"
    chart            = "aws-load-balancer-controller"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  set = [
    {
      name  = "clusterName"
      value = var.eks_cluster_name
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    }
  ]

  values = [
    var.aws_load_balancer_controller_values != "" ? templatefile(var.aws_load_balancer_controller_values, var.aws_load_balancer_controller_variables) : ""
  ]
}


################################################################################
# ingress-nginx
################################################################################

module "ingress_nginx" {
  source     = "terraform-module/release/helm"
  version    = "~> 2.0"
  count      = var.install_ingress_nginx ? 1 : 0
  depends_on = [module.aws_load_balancer_controller]

  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"

  app = {
    name             = "ingress-nginx"
    version          = "4.11.1"
    chart            = "ingress-nginx"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  values = [
    templatefile("${path.module}/templates/ingress_nginx_common.yaml", {}),
    templatefile(var.ingress_nginx_internet_facing ? "${path.module}/templates/ingress_nginx_internet_facing.tftpl" : "${path.module}/templates/ingress_nginx_internal.tftpl", {
      acm_certificate_arn = var.ingress_nginx_acm_certificate_arn,
      tags                = join(",", [for k, v in var.tags : "${k}=${v}"])
    }),
    var.ingress_nginx_values != "" ? templatefile(var.ingress_nginx_values, var.ingress_nginx_variables) : ""
  ]
}


################################################################################
# cert-manager
################################################################################

module "cert_manager_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"
  count   = var.install_cert_manager ? 1 : 0

  name = "cert-manager"

  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = var.cert_manager_hosted_zone_arns

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = "cert-manager"
      service_account = "cert-manager"
    }
  }

  tags = var.tags
}

module "cert_manager" {
  source     = "terraform-module/release/helm"
  version    = "~> 2.0"
  count      = var.install_cert_manager ? 1 : 0
  depends_on = [module.cert_manager_pod_identity, module.ingress_nginx]

  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"

  app = {
    name             = "cert-manager"
    version          = "1.15.2"
    chart            = "cert-manager"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  set = [
    {
      name  = "crds.enabled"
      value = "true"
    }
  ]

  values = [
    var.cert_manager_values != "" ? templatefile(var.cert_manager_values, var.cert_manager_variables) : ""
  ]
}


################################################################################
# external-dns
################################################################################

module "external_dns_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"
  count   = var.install_external_dns ? 1 : 0

  name = "external-dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [var.external_dns_hosted_zone_arn]

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = "external-dns"
      service_account = "external-dns"
    }
  }

  tags = var.tags
}

module "external_dns" {
  source     = "terraform-module/release/helm"
  version    = "~> 2.0"
  count      = var.install_external_dns ? 1 : 0
  depends_on = [module.external_dns_pod_identity, module.ingress_nginx]

  namespace  = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"

  app = {
    name             = "external-dns"
    version          = "8.3.5"
    chart            = "external-dns"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  set = [
    {
      name  = "txtOwnerId"
      value = var.eks_cluster_name
    },
    {
      name  = "domainFilters[0]"
      value = var.external_dns_hosted_zone_name
    },
    {
      name  = "zoneIdFilters[0]"
      value = var.external_dns_hosted_zone_id
    },
    {
      name  = "policy"
      value = "sync"
    }
  ]

  values = [
    var.external_dns_values != "" ? templatefile(var.external_dns_values, var.external_dns_variables) : ""
  ]
}
