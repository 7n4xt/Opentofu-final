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
Outbound rules are unchanged; explicit Internet egress is still required.

Azure networking and two web VMs are configured. Load balancing and explicit
outbound access are not configured yet, so this is not ready for deployment.
State uses the default local backend; configure a shared backend before
collaborating on infrastructure.
Keep credentials and state out of version control. Commit `.terraform.lock.hcl`
once provider installation generates it.
