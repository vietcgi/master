provider "aws" {
  region = local.region
  assume_role {
    role_arn     = "arn:aws:iam::${var.account_id}:role/AWSControlTowerExecution"
    session_name = var.environment_name
  }
}

provider "kubernetes" {
  host                   = module.eks_cluster.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.eks_cluster_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.eks_cluster_id]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = module.eks_cluster.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.eks_cluster_id]
  }
}

locals {
  name   = var.environment_name
  region = var.aws_region

  vpc_cidr       = var.vpc_cidr
  num_of_subnets = min(length(data.aws_availability_zones.available.names), 3)
  azs            = slice(data.aws_availability_zones.available.names, 0, local.num_of_subnets)

  argocd_secret_manager_name = var.argocd_secret_manager_name_suffix

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k + 10)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

module "eks_cluster" {
  source = "./modules/eks_cluster"

  aws_region      = var.aws_region
  service_name    = "green"
  cluster_version = "1.27" # Here, we deploy the cluster with the N+1 Kubernetes Version

  argocd_route53_weight      = "100" # We control with theses parameters how we send traffic to the workloads in the new cluster
  route53_weight             = "100"
  ecsfrontend_route53_weight = "100"

  environment_name       = var.environment_name
  hosted_zone_name       = var.hosted_zone_name
  eks_admin_role_name    = var.eks_admin_role_name
  workload_repo_url      = var.workload_repo_url
  workload_repo_secret   = var.workload_repo_secret
  workload_repo_revision = var.workload_repo_revision
  workload_repo_path     = var.workload_repo_path

  addons_repo_url = var.addons_repo_url

  iam_platform_user                 = var.iam_platform_user
  argocd_secret_manager_name_suffix = var.argocd_secret_manager_name_suffix
}