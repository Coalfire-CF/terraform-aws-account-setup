resource "aws_iam_service_linked_role" "autoscale" {
  aws_service_name = "autoscaling.amazonaws.com"
}

resource "aws_iam_role" "eks_node_role" {
  count      = var.create_eks_service_role ? 1 : 0
  name = "EKSNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy" "eks_worker_policy" {
  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "ecr_pull_policy" {
  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

data "aws_iam_policy" "eks_cni_policy" {
  arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_attach" {
  count      = var.create_eks_service_role ? 1 : 0
  policy_arn = data.aws_iam_policy.eks_worker_policy.arn
  role       = aws_iam_role.eks_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "ecr_pull_attach" {
  count      = var.create_eks_service_role ? 1 : 0
  policy_arn = data.aws_iam_policy.ecr_pull_policy.arn
  role       = aws_iam_role.eks_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count      = var.create_eks_service_role ? 1 : 0
  policy_arn = data.aws_iam_policy.eks_cni_policy.arn
  role       = aws_iam_role.eks_node_role[0].name
}
