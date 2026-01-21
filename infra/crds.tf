data "http" "gateway_api_manifests" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_version}/standard-install.yaml"
}

data "kubectl_file_documents" "gateway_api_docs" {
  content = data.http.gateway_api_manifests.response_body
}

resource "kubectl_manifest" "gateway_api_crds" {
  for_each  = data.kubectl_file_documents.gateway_api_docs.manifests
  yaml_body = each.value

  server_side_apply = true
  wait              = true

  depends_on = [module.eks.eks_managed_node_groups]

  lifecycle {
    ignore_changes = [
      yaml_body
    ]
  }
}
