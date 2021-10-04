# 建立本機開發環境

## 必要條件

- Argo CD CLI
- Docker
- K3d
- Kubectl
- Kustomize
- Ports 443-446
- Terraform
- yq

## 安裝

安裝必要工具：

```shell
brew tap hashicorp/tap && brew install argocd docker k3d kubectl kustomize hashicorp/tap/terraform yq
```

> 若您已使用其它方式安裝以上工具，請自行調整指令避免重複安裝。

在 `/etc/hosts` 添加 Hostname：

```shell
echo "127.0.0.1 hub.k3d.testing non-production.k3d.testing production.k3d.testing staging.k3d.testing" | sudo tee -a /etc/hosts
echo "127.0.0.1 argocd.k3d.testing" | sudo tee -a /etc/hosts
```

切換到 `test/local-development` 資料夾：

```shell
cd test/local-development
```

編輯 `teraform.tfvars` 設定檔：

```terraform
# 請設定你的本機 IP 位址
host_ip = "192.168.2.122"
# 請設定 GitOps Repository 的 Personal Access Token
github_password = "your_personal_access_token"

# 可選，設定 Argo CD admin 帳號密碼
argocd_password = "your_password"
# 可選，GitOps Repository 目標版本
gitops_repository_revision = "main"
# 可選，K3s 版本
k3s_image = "rancher/k3s:v1.21.5-k3s1"
```

> 設定檔包含 GitHub 密碼，請勿 commit 進版本庫（預設被 `.gitignore` 忽略）。

初始化專案：

```shell
terraform init
```

執行建立開發環境：

```shell
$ terraform apply
Omit...
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

> 請輸入 `yes`。

```shell
Omit...

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

argocd_login_cli = "argocd login argocd.k3d.testing --username admin --grpc-web --insecure --password your_password"
argocd_url = "https://argocd.k3d.testing"
clusters = [
  "k3d-hub",
  "k3d-non-production",
  "k3d-production",
  "k3d-staging",
]
k3d_hub_cluster_loadbalancer_url = "https://hub.k3d.testing"
k3d_non_production_cluster_loadbalancer_url = "https://non-production.k3d.testing:444"
k3d_production_cluster_loadbalancer_url = "https://production.k3d.testing:445"
k3d_staging_cluster_loadbalancer_url = "https://staging.k3d.testing:446"
```

> 完成後會在畫面上印出常用指令與叢集資訊，也可以執行 `terraform outputs` 來查看。

移除開發環境：

```shell
$ terraform destroy
Omit...
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

> 請輸入 `yes`。

## 使用

請參考[這裡的文件說明](https://hackmd.io/9Wof3rRwRs2PZ5eVcolBDQ)。
