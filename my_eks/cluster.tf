## don't forget to config kubectl after cluster is created with
## aws eks --region us-east-1 update-kubeconfig --name my-eks-cluster
## to get it from terraform output
## aws eks --region $(terraform output -raw region) update-kubeconfig \
## --name $(terraform output -raw cluster_name)

locals {
  cluster_name = "my-eks-cluster"
}

variable "region" {
  default     = "us-east-1"
  description = "AWS region"
}

module "vpc" {
  #source = "git::ssh://git@github.com/reactiveops/terraform-vpc.git?ref=3.0.0"

  source = "git::ssh://git@github.com/FairwindsOps/terraform-vpc.git" 

  aws_region = "us-east-1"
  az_count   = 3
  aws_azs    = "us-east-1a, us-east-1b, us-east-1c"

  global_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

module "eks" {
  #source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git"

  source          = "github.com/terraform-aws-modules/terraform-aws-eks"
  cluster_name    = local.cluster_name
  vpc_id          = module.vpc.aws_vpc_id
  subnets         = module.vpc.aws_subnet_private_prod_ids

  # k8s version to use for eks cluster
  cluster_version = "1.18"

  node_groups = {
    eks_nodes = {
      desired_capacity = 3
      max_capacity     = 3
      min_capaicty     = 3

      ## had to correct syntax on this to change instance type
      ## learned from node group module on terraform registry
      ## terraform replacement = creating new resources, then terminate old
      instance_types = ["t3.micro"]
    }
  }
  manage_aws_auth = false
}