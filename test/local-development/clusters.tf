terraform {
  required_providers {
    k3d = {
      source  = "3rein/k3d"
      version = "0.0.4"
    }
  }
}

resource "k3d_cluster" "hub" {
  name = "hub"

  kube_api {
    host      = "hub.k3d.testing"
    host_port = 6500
  }

  image = var.k3s_image

  port {
    host_port      = 443
    container_port = 443
    node_filters   = [
      "loadbalancer",
    ]
  }

  kubeconfig {
    update_default_kubeconfig = true
    switch_current_context    = true
  }

  provisioner "local-exec" {
    command     = <<-EOT
      function check_cluster_ready() {
        n=0
        until [ "$n" -ge 10 ]
        do
          if kubectl get po -A -o=custom-columns="NAME:.metadata.name,STATUS:.status.phase" | grep coredns | grep Running; then
            break
          else
            echo "Waiting for cluster ready..."
          fi

          n=$((n+1))
          sleep 10
        done
      }
      check_cluster_ready

      # ref: https://github.com/rancher/k3d/issues/209#issuecomment-839633316
      NAMESERVERS=`grep nameserver /etc/resolv.conf | awk '{print $2}' | xargs`
      cmpatch=$(kubectl get cm coredns -n kube-system --template='{{.data.Corefile}}' | sed "s/forward.*/forward . $NAMESERVERS/g" | tr '\n' '^' | xargs -0 printf '{"data": {"Corefile":"%s"}}' | sed -E 's%\^%\\n%g') && kubectl patch cm coredns -n kube-system -p="$cmpatch"
      echo "add nameservers to coredns forward"

      kustomize build "${var.gitops_repository}/apps/argocd/overlays/management-env/hub-cluster?ref=${var.gitops_repository_revision}" | kubectl apply -f -
      kubectl wait --for=condition=available --timeout=600s deployment/argocd-redis -n argocd
      kubectl wait --for=condition=available --timeout=600s deployment/argocd-dex-server -n argocd
      kubectl wait --for=condition=available deployment/argocd-repo-server -n argocd
      kubectl wait --for=condition=available deployment/argocd-server -n argocd

      sleep 10

      HOSTS="${var.host_ip} non-production.k3d.testing
${var.host_ip} production.k3d.testing
${var.host_ip} staging.k3d.testing" \
        && kubectl get cm/coredns -n kube-system -o yaml | yq eval '.data.NodeHosts += "'"$HOSTS"'"' - | kubectl apply -f -

      argocd login argocd.k3d.testing --username admin --grpc-web --insecure --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
      argocd account update-password --new-password ${var.argocd_password} --current-password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

      argocd repo add https://${var.gitops_repository} --username gitops --password ${var.github_password}

      argocd app create bootstrap \
        --repo https://${var.gitops_repository} \
        --revision ${var.gitops_repository_revision} \
        --path management-env/hub-cluster/bootstrap \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace argocd \
        --sync-policy automated

      sleep 10

      function add_cluster_when_dns_record_found() {
        n=0
        until [ "$n" -ge 10 ]
        do
          if kubectl run -it --rm --restart=Never busybox --image=busybox:1.28 -- nslookup "$1.k3d.testing" | grep -q "$2"; then
            argocd cluster add "k3d-$1"
            break
          else
            echo "hostname: $1.k3d.testing not found"
          fi

          n=$((n+1))
          sleep 10
        done
      }

      add_cluster_when_dns_record_found non-production ${var.host_ip}
      add_cluster_when_dns_record_found production ${var.host_ip}
      add_cluster_when_dns_record_found staging ${var.host_ip}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "k3d_cluster" "non-production" {
  name = "non-production"

  kube_api {
    host      = "non-production.k3d.testing"
    host_port = 6501
  }

  image = var.k3s_image

  port {
    host_port      = 444
    container_port = 443
    node_filters   = [
      "loadbalancer",
    ]
  }

  kubeconfig {
    update_default_kubeconfig = true
  }
}

resource "k3d_cluster" "production" {
  name = "production"

  kube_api {
    host      = "production.k3d.testing"
    host_port = 6502
  }

  image = var.k3s_image

  port {
    host_port      = 445
    container_port = 443
    node_filters   = [
      "loadbalancer",
    ]
  }

  kubeconfig {
    update_default_kubeconfig = true
  }
}

resource "k3d_cluster" "staging" {
  name = "staging"

  kube_api {
    host      = "staging.k3d.testing"
    host_port = 6503
  }

  image = var.k3s_image

  port {
    host_port      = 446
    container_port = 443
    node_filters   = [
      "loadbalancer",
    ]
  }

  kubeconfig {
    update_default_kubeconfig = true
  }
}
