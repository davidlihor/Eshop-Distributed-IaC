resource "aws_eks_access_entry" "local_user" {
  count         = var.admin_arn != "" ? 1 : 0
  cluster_name  = module.eks.cluster_name
  principal_arn = var.admin_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "local_user_admin" {
  count         = var.admin_arn != "" ? 1 : 0
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.admin_arn

  access_scope {
    type = "cluster"
  }
}
