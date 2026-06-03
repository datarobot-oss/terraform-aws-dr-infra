## Example: private
Demonstrates the minimal set of input variables required to create all infrastructure needed to install the DataRobot application in a private, internet-restricted configuration.

In this example:

- Rather than creating a VPC, the ID of an existing VPC is passed instead via `existing_vpc_id`. The module will deploy all resources into that VPC rather than creating a new one.
- The EKS public API endpoint is disabled. Only the host at `provisioner_ip` is granted access to the private API endpoint, so `terraform apply` must be run from a host within the VPC (or reachable via VPN/peering).
- The ingress load balancer is internal (`internet_facing_ingress_lb = false`). Access is restricted to the CIDR specified in `ingress_allowed_cidr`.
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
| `existing_vpc_id` | ID of an existing VPC to deploy resources into |
| `provisioner_ip` | IP of the host running `terraform apply` — granted access to the private EKS API endpoint |
| `ingress_allowed_cidr` | CIDR block allowed to reach the internal ingress load balancer |

## Usage
1. Copy the example tfvars file and fill in your values:
```bash
cp terraform.tfvars.example terraform.tfvars
```
2. Edit `terraform.tfvars` with your account ID, region, domain name, existing VPC ID, provisioner IP, and other required values.
3. Run Terraform:
```bash
terraform init
terraform apply
```
