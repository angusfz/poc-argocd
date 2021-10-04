variable "gitops_repository" {
  type = string
}

variable "gitops_repository_revision" {
  type    = string
  default = "main"
}

variable "k3s_image" {
  type    = string
  default = "rancher/k3s:v1.21.5-k3s1"
}

variable "host_ip" {
  type = string
}

variable "argocd_password" {
  type    = string
  default = "password"
}

variable "github_password" {
  type = string
}
