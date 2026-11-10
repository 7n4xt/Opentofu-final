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

Azure networking and two web VMs are configured. Load balancing and explicit
outbound access are not configured yet, so this is not ready for deployment.
State uses the default local backend; configure a shared backend before
collaborating on infrastructure.
Keep credentials and state out of version control. Commit `.terraform.lock.hcl`
once provider installation generates it.
