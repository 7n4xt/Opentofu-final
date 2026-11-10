# OpenTofu

Requires OpenTofu >= 1.6.0 and < 2.0.0.

## Getting started

Authenticate with `az login`. Copy `terraform.tfvars.example` to
`terraform.tfvars` only if you do not already have one, then set your own values.
Use the region and VM size agreed during the Azure TP.

`binome` names resources; `numgroupe` sets the network's second octet
(`10.numgroupe.0.0/16`). Resources supporting tags receive `projet`, `owner`, and
`env`; Azure subnets and association resources do not support tags.

If upgrading the earlier configuration, replace `admin_ssh_public_key` in your
local `terraform.tfvars` with `ssh_public_key_path` pointing to your existing
public key file, and add `numgroupe`. Never use the private key file.

```sh
tofu init
tofu fmt -check
tofu validate
tofu plan
```

Add provider requirements to `versions.tf`, infrastructure to `main.tf`, inputs
to `variables.tf`, and outputs to `outputs.tf`.

## Subnet security (level 1)

Each subnet has its own associated NSG:

| Subnet | Allowed inbound traffic | Other inbound traffic |
| --- | --- | --- |
| Web | TCP/80 from `Internet` and `AzureLoadBalancer` | Denied |
| Admin | None yet | Denied |

Rules are evaluated from lowest priority number first: HTTP at 100, health
probe at 110, then deny-all at 4096. The explicit deny overrides Azure's default
inbound VNet and load-balancer allowances. NSGs are stateful: replies to allowed
connections do not require a separate inbound allow rule.

SSH is disabled at the network level for now. Level 2 will allow SSH to the
jumpbox only from your public IP, and to web VMs only from the admin subnet.
NSG outbound rules are unchanged. An explicit load-balancer outbound rule
provides Internet egress for both web VMs without assigning them public IPs.

Azure networking, two web VMs, and a Standard Load Balancer are configured.
`load-balancer.tf` connects both private NICs to the backend pool, probes HTTP
`/sante` on port 80, forwards public TCP/80 to backend TCP/80, and configures
outbound SNAT through the load balancer's static public IP. VM creation waits
for the outbound rule, backend associations, and web subnet NSG association so
cloud-init can install nginx. The HTTP rule disables implicit outbound SNAT to
use only the explicit outbound rule.

Deployment and live failover have not been tested yet.
State uses the default local backend; configure a shared backend before
collaborating on infrastructure.
Keep credentials and state out of version control. Commit `.terraform.lock.hcl`
once provider installation generates it.
