## Example: complete
Demonstrates the complete set of input variables which can be used to create all infrastructure required to install the DataRobot application helm charts.

This example also shows how the user can bring their own public TLS certificate for ingress rather than using ACM. In order to accomplish that, `create_acm_certificate` is disabled and the `ingress_nginx_values` file overrides the default `controller.service.targetPorts.https` from `http` (which would terminate HTTPS at the actual NLB) to `https` which will pass HTTPS traffic through to the `ingress-nginx-controller` Kubernetes service.

It also shows how internet access to the ingress load balancer and the Kubernetes API endpoint can be restricted to one or more IP addresses (`local.provisioner_public_ip` in this case).

## Usage
```
terraform init
terraform plan
terraform apply
```
