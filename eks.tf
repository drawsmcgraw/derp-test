module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = "derp"
  cluster_version = "1.27"

  #vpc_id                         = module.vpc.vpc_id
  vpc_id                         = aws_vpc.workstation-vpc.id
  subnet_ids                     = [aws_subnet.private_subnet_01.id, aws_subnet.private_subnet_02.id]
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.large"]

      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }
}