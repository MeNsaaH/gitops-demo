locals {
  cluster_name = "eks-demo-mukuru"
  argocd_repositories = [
    {
      url = "https://github.com/mensaah/gitops-demo.git"
    },
  ]
  common_tags = {
    Managed-by  = "Terraform"
    Environment = "demo"
  }
}

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  name            = "vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  #  enable_nat_gateway = true
  #  enable_vpn_gateway = true

  tags = local.common_tags
}


module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.19"
  subnets         = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  worker_groups = [
    {
      instance_type        = "t3.small"
      asg_desired_capacity = "1"
      asg_max_size         = "2"
      asg_min_size         = "1"
    }
  ]
  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  map_users = [{
    userarn  = "arn:aws:iam::800997504826:user/mmadu@deimos.co.za"
    username = "manasseh"
    groups   = ["system:masters"]
  }]

  tags = local.common_tags

  depends_on = [module.vpc]
}


module "argocd" {
  source       = "DeimosCloud/argocd/kubernetes"
  version      = "1.0.0"
  repositories = local.argocd_repositories
  depends_on   = [module.eks]
}
