output "clusters" {
  value = [
    "k3d-hub",
    "k3d-non-production",
    "k3d-production",
    "k3d-staging"
  ]
}

output "argocd_login_cli" {
  value = "argocd login argocd.k3d.testing --username admin --grpc-web --insecure --password ${var.argocd_password}"
}

output "argocd_url" {
  value = "https://argocd.k3d.testing"
}

output "k3d_hub_cluster_loadbalancer_url" {
  value = "https://hub.k3d.testing"
}

output "k3d_non_production_cluster_loadbalancer_url" {
  value = "https://non-production.k3d.testing:444"
}

output "k3d_production_cluster_loadbalancer_url" {
  value = "https://production.k3d.testing:445"
}

output "k3d_staging_cluster_loadbalancer_url" {
  value = "https://staging.k3d.testing:446"
}
