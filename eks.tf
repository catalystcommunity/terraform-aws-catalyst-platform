# eks service role
# https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html
data "aws_iam_policy_document" "cluster_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster_role" {
  name               = "${var.eks_cluster_name}-eks-cluster-role"
  description        = "EKS cluster service role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# nodegroup iam role
data "aws_iam_policy_document" "node_group_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "default_node_group_role" {
  name               = "${var.eks_cluster_name}-default-eks-node-group-role"
  description        = "EKS node group role"
  assume_role_policy = data.aws_iam_policy_document.node_group_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  policy_arn = each.value
  role       = aws_iam_role.default_node_group_role.name
}

# eks cluster
resource "aws_eks_cluster" "cluster" {
  name                      = var.eks_cluster_name
  role_arn                  = aws_iam_role.cluster_role.arn
  version                   = var.eks_cluster_version
  enabled_cluster_log_types = var.eks_cluster_enabled_log_types

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = var.eks_cluster_endpoint_private_access
    endpoint_public_access  = var.eks_cluster_endpoint_public_access
    public_access_cidrs     = var.eks_cluster_endpoint_public_access_cidrs
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_role_policy
  ]
}

# node groups, one per availability zone
locals {
  default_node_group_version = coalesce(var.eks_default_node_groups_version, var.eks_cluster_version)
}

resource "aws_eks_node_group" "default" {
  count = length(var.availability_zones)

  node_group_name_prefix = "default-${var.availability_zones[count.index].az_name}"
  cluster_name           = aws_eks_cluster.cluster.name
  instance_types         = var.eks_default_node_groups_instance_types
  node_role_arn          = aws_iam_role.default_node_group_role.arn
  subnet_ids             = aws_subnet.private[*].id
  version                = local.default_node_group_version
  tags                   = var.tags

  scaling_config {
    desired_size = var.eks_default_node_groups_initial_desired_size
    max_size     = var.eks_default_node_groups_max_size
    min_size     = var.eks_default_node_groups_min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_policy
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}


# oidc provider for IRSA
# https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
data "tls_certificate" "irsa" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "irsa_provider" {
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.irsa.certificates[0].sha1_fingerprint]
  tags = merge(
    { "Name" = "${var.eks_cluster_name}-eks-cluster-irsa-provider" },
    var.tags
  )
}

# cluster autoscaler irsa role and policy
data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeInstanceTypes",
    ]
    resources = ["*"]
  }

  # allow autoscaling for only this specific eks cluster
  statement {
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${var.eks_cluster_name}"
      values   = ["owned"]
    }
  }
}

module "cluster_autoscaler_irsa_role" {
  # TODO source from registry after initial publish instead ?
  source = "./modules/eks-irsa-role"

  role_description      = "IRSA role for the cluster autoscaler"
  role_name             = "${var.eks_cluster_name}-cluster-autoscaler"
  enable_policy         = true
  policy_document       = data.aws_iam_policy_document.cluster_autoscaler.json
  eks_identity_oidc_url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  oidc_provider_arn     = aws_iam_openid_connect_provider.irsa_provider.arn
  namespace             = var.cluster_autoscaler_namespace
  service_account       = var.cluster_autoscaler_service_account_name
  tags                  = var.tags
}

# aws auth configmap
data "aws_iam_roles" "sso_auto_discover" {
  count       = var.manage_aws_auth_configmap ? length(var.aws_auth_sso_roles) : 0
  name_regex  = "AWSReservedSSO_${var.aws_auth_sso_roles[count.index].sso_role_name}_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

locals {
  auto_discovered_sso_roles = [for index, sso_role in var.aws_auth_sso_roles : {
    # remove arn path with replace, as paths are not supported in the aws-auth configmap
    rolearn  = replace(tolist(data.aws_iam_roles.sso_auto_discover[index].arns)[0], "//.*//", "/")
    username = sso_role.username
    groups   = sso_role.groups
  }]

  aws_auth_configmap_data = {
    mapRoles = yamlencode(concat(
      [{
        rolearn  = aws_iam_role.default_node_group_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      }],
      var.aws_auth_roles,
      local.auto_discovered_sso_roles,
    ))
    mapUsers = yamlencode(var.aws_auth_users)
  }
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  count = var.manage_aws_auth_configmap ? 1 : 0

  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data

  depends_on = [
    # wait for the node groups to exist so that the configmap exists
    aws_eks_node_group.default
  ]
}
