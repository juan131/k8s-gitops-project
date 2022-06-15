module "argo_cd_argo_cd" {
  source                  = "../../modules/upstream-chart"
  local_base_directory    = "../../kubernetes/production"
  chart_name              = "argo-cd"
  chart_repository        = "https://charts.bitnami.com/bitnami"
  chart_release_name      = "argo-cd"
  chart_release_namespace = "argo-cd"
  chart_values_path       = "./helm-values/argo-cd-argo-cd.yaml"
  chart_version           = "3.3.9" # auto-updated-argo-cd
}

module "sealed_secrets_kube_system" {
  source                  = "../../modules/upstream-chart"
  local_base_directory    = "../../kubernetes/production"
  chart_name              = "sealed-secrets"
  chart_repository        = "https://bitnami-labs.github.io/sealed-secrets"
  chart_release_name      = "sealed-secrets"
  chart_release_namespace = "kube-system"
  chart_values_path       = "./helm-values/sealed-secrets-kube-system.yaml"
  chart_version           = "2.2.0" # auto-updated-sealed-secrets
}
