## Example: complete
This example is not intended to represent a production-ready or typical deployment. Its purpose is to demonstrate the full breadth of customization available in this module — every major input variable is set explicitly, and several optional features are enabled together that would not normally be combined (e.g., a network firewall alongside custom helm value overrides, a private cluster with a VPC Endpoint Service, object lock on storage, and all optional helm charts enabled at once).

Use this example as a reference for what is possible, not as a starting point for a real deployment.

Notable patterns shown in this example:

- **Private cluster access**: The EKS public API endpoint is disabled. Only the provisioner host's private IP (`local.provisioner_private_ip`) is allowed to reach the private API endpoint.
- **Internal NLB with VPC Endpoint Service**: `internet_facing_ingress_lb = false` creates an internal NLB. `create_ingress_vpce_service = true` exposes it as a VPC Endpoint Service so consumers in other VPCs can reach it without traversing the public internet.
- **Network Firewall**: An AWS Network Firewall is provisioned to inspect and filter traffic at the VPC boundary.
- **Custom helm values**: Each helm chart accepts a `*_values_overrides` input. This example loads those overrides from template files in `templates/`, allowing Terraform variables (such as `lb_source_ranges`) to be interpolated into the YAML using `templatefile()`.

## Usage
```
terraform init
terraform apply
```
