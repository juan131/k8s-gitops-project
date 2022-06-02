data "helm_template" "chart" {
  name         = var.chart_release_name
  namespace    = var.chart_release_namespace
  repository   = var.chart_repository
  chart        = var.chart_name
  version      = var.chart_version
  include_crds = true

  values = [
    file(var.chart_values_path)
  ]
}

resource "local_file" "chart_manifests" {
  for_each = data.helm_template.chart.manifests
  filename = replace("${var.local_base_directory}/${var.chart_release_namespace}/${var.chart_release_name}/${each.key}", "templates/", "")
  content  = each.value
}
