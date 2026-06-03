## Example: public
Demonstrates the minimal set of input variables required to create all infrastructure needed to install the DataRobot application in a standard publicly accessible configuration.

In this example:

- A new VPC is created. VPC endpoints are omitted (`network_endpoints = []`) as a cost-saving measure — traffic to AWS services flows over the public internet rather than through private endpoints.
- The EKS API endpoint is publicly accessible (the default).
- The ingress load balancer is internet-facing (the default), so the DataRobot application is reachable from the public internet.
- TLS is handled by cert-manager using Let's Encrypt. Provide a valid `email_address` for certificate expiry notifications.
- `storage_force_destroy`, `dns_zone_force_destroy`, and `container_registry_repos_force_destroy` are set to `false` in production (`var.environment == "prod"`) to prevent accidental data loss.

## Required variables
| Variable | Description |
|---|---|
| `name` | Name prefix applied to all created resources |
| `environment` | One of `dev`, `staging`, or `prod` |
| `account_id` | AWS account ID to deploy into |
| `region` | AWS region to deploy into |
| `domain_name` | Domain name for the application (e.g. `datarobot.yourdomain.com`) |
| `email_address` | Email address for Let's Encrypt certificate notifications |

## Usage
1. Copy the example tfvars file and fill in your values:
```bash
cp terraform.tfvars.example terraform.tfvars
```
2. Edit `terraform.tfvars` with your account ID, region, domain name, and other required values.
3. Run Terraform:
```bash
terraform init
terraform apply
```
