# examples/gcp-complete

## What This Demonstrates

End-to-end GCP stack: VPC + GKE (private cluster) + Secret Manager.

Key wiring points:
- VPC secondary range names flow directly into the GKE cluster module
- Workload Identity pool output from GKE used in IAM member strings
- Secret Manager IAM bindings attached to the GKE node service account

## Usage

```bash
gcloud auth application-default login
terraform init
terraform plan -var="project_id=YOUR_PROJECT"
terraform apply -var="project_id=YOUR_PROJECT"
```

## Not Production-Ready

This example uses a local backend. For production use a GCS backend:

```hcl
terraform {
  backend "gcs" {
    bucket = "your-tfstate-bucket"
    prefix = "gcp-complete"
  }
}
```
