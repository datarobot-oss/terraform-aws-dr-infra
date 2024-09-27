module "nvidia_device_plugin" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "nvidia-device-plugin"
  repository = "https://nvidia.github.io/k8s-device-plugin"

  app = {
    name             = "nvidia-device-plugin"
    version          = "v0.16.2"
    chart            = "nvidia-device-plugin"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  values = [
    templatefile("${path.module}/values.yaml", {}),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

}
