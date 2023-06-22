# You should update the below variables
#cluster_name = "master"
account_id       = "894642160939"
vpc_cidr         = "10.0.0.0/16"
aws_region       = "us-east-1"
environment_name = "master"
hosted_zone_name = "qualityspace.com" # your Existing Hosted Zone
#eks_admin_role_name = "Admin" # Additional role admin in the cluster (usually the role I use in the AWS console)

# EKS Blueprint AddOns ArgoCD App of App repository
#addons_repo_url = "git@github.com:aws-samples/eks-blueprints-add-ons.git"

# EKS Blueprint Workloads ArgoCD App of App repository
#workload_repo_url      = "git@github.com:aws-samples/eks-blueprints-workloads.git"
#workload_repo_revision = "main"
#workload_repo_path     = "envs/dev"
#workload_repo_secret   = "github-blueprint-ssh-key"
