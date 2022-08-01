module "argo_cd_argo_cd" {
  source                  = "../../modules/upstream-chart"
  local_base_directory    = "../../kubernetes/staging"
  chart_name              = "argo-cd"
  chart_repository        = "https://charts.bitnami.com/bitnami"
  chart_release_name      = "argo-cd"
  chart_release_namespace = "argo-cd"
  chart_values_path       = "./helm-values/argo-cd-argo-cd.yaml"
  chart_version           = "4.0.3" # auto-updated-argo-cd
}

module "sealed_secrets_kube_system" {
  source                  = "../../modules/upstream-chart"
  local_base_directory    = "../../kubernetes/staging"
  chart_name              = "sealed-secrets"
  chart_repository        = "https://bitnami-labs.github.io/sealed-secrets"
  chart_release_name      = "sealed-secrets"
  chart_release_namespace = "kube-system"
  chart_values_path       = "./helm-values/sealed-secrets-kube-system.yaml"
  chart_version           = "2.5.2" # auto-updated-sealed-secrets
}
