# NimbusShop — OpenTofu Azure, niveaux 1 et 2

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

Review the plan before running `tofu apply`. Changes to existing resource names
can force replacements. Never apply unexpected deletions without investigating.

## Files and architecture

- `providers.tf`, `versions.tf`: Azure provider and version constraints.
- `variables.tf`: typed inputs, including group number and public SSH key path.
- `main.tf`: resource group, network, subnet NSGs, two private NICs and web VMs.
- `cloud-init.yaml`: nginx, NimbusShop page with hostname, and `/sante` health page.
- `load-balancer.tf`: public Standard LB, backend pool, HTTP probe, HTTP rule and egress.
- `jumpbox.tf`: private admin-subnet NIC, public IP and SSH-only jumpbox VM.
- `outputs.tf`: public site URL, jumpbox public IP and web private IPs.

With `numgroupe = 7`, the VNet is `10.7.0.0/16`, web subnet is
`10.7.1.0/24`, and admin subnet is `10.7.2.0/24`.

```text
Internet -> Standard public IP -> Load Balancer TCP/80
                                  -> private web VM 1:80
                                  -> private web VM 2:80
Web VMs -> explicit LB outbound rule -> Internet
```

Both VMs use `count = 2`, the same image, size and cloud-init, with SSH-key-only
authentication and no public IP. A third VM, the jumpbox, uses the admin subnet
and is the only VM with a public IP.

## Subnet security

Each subnet has its own associated NSG:

| Subnet | Allowed inbound traffic | Other inbound traffic |
| --- | --- | --- |
| Web | TCP/80 from `Internet` and `AzureLoadBalancer`; TCP/22 from admin subnet | Denied |
| Admin | TCP/22 from `allowed_ssh_cidr` only | Denied |

Rules are evaluated from lowest priority number first: HTTP at 100, health
probe at 110, web SSH from admin at 120, then deny-all at 4096. Admin SSH uses
priority 100 in its own NSG. The explicit deny overrides Azure's default
inbound VNet and load-balancer allowances. NSGs are stateful: replies to allowed
connections do not require a separate inbound allow rule.

SSH to the jumpbox is restricted to your current public IPv4 `/32`; SSH to
web VMs is restricted to the admin subnet (`10.7.2.0/24` for group 7).
NSG outbound rules are unchanged. An explicit load-balancer outbound rule
provides Internet egress for both web VMs without assigning them public IPs.

Azure networking, two web VMs, and a Standard Load Balancer are configured.
`load-balancer.tf` connects both private NICs to the backend pool, probes HTTP
`/sante` on port 80, forwards public TCP/80 to backend TCP/80, and configures
outbound SNAT through the load balancer's static public IP. VM creation waits
for the outbound rule, backend associations, and web subnet NSG association so
cloud-init can install nginx. The HTTP rule disables implicit outbound SNAT to
use only the explicit outbound rule.

## Deploy and test

If the infrastructure is already deployed, review a fresh plan and apply it to
save the new `site_url` output in state. Adding this output alone does not change
Azure resources; inspect the plan for any other pending changes first.

```sh
tofu plan
tofu apply
SITE_URL=$(tofu output -raw site_url)
curl --fail --connect-timeout 5 --max-time 10 "$SITE_URL/"
curl --fail --connect-timeout 5 --max-time 10 "$SITE_URL/sante"
```

Wait for cloud-init to finish installing nginx and for the LB probes to report
healthy backends. `/` must display NimbusShop and a VM hostname; `/sante` must
return HTTP 200 with `OK-nimbus`. The Azure HTTP probe checks the status code,
not the response body.

To demonstrate distribution, create multiple new connections:

```sh
for i in $(seq 1 20); do
  curl --fail --silent --show-error --connect-timeout 5 --max-time 10 "$SITE_URL/"
  sleep 1
done
```

Look for both VM hostnames. Azure distributes connections using a hash, not
strict round-robin; consecutive requests may reach the same VM.

For the teacher's failover demonstration, have one VM stopped in the portal as
specified in the assignment, then repeat the requests. After the health probe
detects the failure, new connections must reach the remaining VM. Connections
to the stopped VM may fail during detection. Restart that VM afterwards and
wait until its health probe succeeds again. This manual stop is only the
assignment's failure simulation; infrastructure creation remains code-only.

Deployment is reported complete by the user; live HTTP and failover tests have
not been independently verified here. Level 2 is configured but not deployed
or tested here. Level 3 is not implemented.

## Level 2: SSH through the jumpbox

Add your current public IPv4 in the ignored `terraform.tfvars`:

```hcl
allowed_ssh_cidr = "203.0.113.10/32" # Replace with YOUR public IPv4, not this example.
```

The variable accepts only a valid IPv4 `/32`, not `0.0.0.0/0` or an entire
subnet. If your Internet connection or VPN changes public IP, update the value
and apply again. The address is your Internet-facing IP, not your LAN IP.

Review and apply the plan. For an unchanged level-1 deployment, expect three
new resources (jumpbox public IP, NIC and VM), NSG rule updates and outputs;
existing web VMs should not need replacement for level 2 alone.

```sh
tofu fmt -check
tofu validate
tofu plan
tofu apply
tofu output jumpbox_public_ip
tofu output web_private_ips
```

Use the private key corresponding to `ssh_public_key_path`, locally only.
For a custom key, load it into your local SSH agent so both the proxy and target
connections can authenticate:

```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

Adjust the key path and replace the placeholders below with the outputs.
Replace `azureuser` if you configured a different `admin_username`:

```text
ssh azureuser@JUMPBOX_PUBLIC_IP
ssh -J azureuser@JUMPBOX_PUBLIC_IP azureuser@WEB_PRIVATE_IP
```

Repeat `ssh -J` for both web IPs. On each web VM, check:

```sh
hostname
cloud-init status --wait
curl --fail http://localhost/sante
```

The health page must return `OK-nimbus`. Private keys stay on your computer;
do not copy them to the jumpbox or enable agent forwarding (`ssh -A`).
ProxyJump tunnels through the jumpbox without exposing your private key there.
Verify SSH host-key fingerprints before accepting new hosts.

If SSH times out, check your current public IPv4 against `allowed_ssh_cidr`,
wait for VM provisioning to finish, and confirm you used the outputs' correct
public/private addresses. Password authentication is disabled on all VMs.

## State, secrets and cleanup

The SSH CIDR validation has a local regression test (Python 3 and OpenTofu
only, no Azure credentials or resources required):

```sh
python3 tests/test_ssh_cidr.py
```

State uses the default local backend; configure a shared backend before
collaborating on infrastructure.
Keep credentials and state out of version control. Commit `.terraform.lock.hcl`
once provider installation generates it.

`terraform.tfvars`, `.terraform/` and state files are gitignored. Authenticate
with `az login`; never commit private keys, credentials or saved plan files
(plans can contain sensitive values). Do not run simultaneous applies from
different local state copies.

After the final teacher validation, cleanup is mandatory:

```sh
tofu plan -destroy
tofu destroy
```

Review the destruction plan: this removes all resources managed by this state.
Keep state until cleanup succeeds, and remember that running Azure resources
consume student credits.
