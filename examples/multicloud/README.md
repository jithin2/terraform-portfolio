# examples/multicloud

## What This Demonstrates

The same logical application deployed on both Azure and GCP in a single Terraform
configuration, using the `shared/naming` module to produce consistent resource names
across clouds.

Key design point: the naming module produces structurally identical names for both clouds.
Region abbreviations differ (`eus` vs `ue1`) because cloud regions have different naming
conventions — but the pattern is the same, and both come from the same module.

```
Azure: prod-eus-payments-aks    (from module.azure_naming)
GCP:   prod-ue1-payments-gke    (from module.gcp_naming)
```

## Interview Talking Points

- **Why not one naming module call for both clouds?** Region abbreviations diverge. A single
  call would require either picking one convention or adding cloud-specific logic inside the
  naming module, violating single-responsibility.
- **What does "multicloud" actually mean here?** This example shows infrastructure parity —
  the same application tier deployed on both clouds for active-active or DR scenarios. It does
  not demonstrate application-level routing between clouds; that belongs in a load balancing layer.
