# OpenTofu

Requires OpenTofu >= 1.6.0 and < 2.0.0.

## Getting started

```sh
tofu init
tofu fmt -check
tofu validate
tofu plan
```

Add provider requirements to `versions.tf`, infrastructure to `main.tf`, inputs
to `variables.tf`, and outputs to `outputs.tf`.

No providers or resources are configured yet. State uses the default local
backend; configure a shared backend before collaborating on infrastructure.
Keep credentials and state out of version control. Commit `.terraform.lock.hcl`
once provider installation generates it.
