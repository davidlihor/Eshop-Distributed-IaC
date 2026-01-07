provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.this.token
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.this.token
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}

provider "postgresql" {
  host            = locals.actual_db_host
  port            = 5432
  database        = "management"
  username        = "db_admin"
  password        = module.rds_postgres.db_instance_master_password
  sslmode         = "require"
  connect_timeout = 15
}

provider "random" {}