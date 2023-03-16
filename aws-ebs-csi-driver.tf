module "aws_ebs_csi_irsa_role" {
  count = var.enable_aws_ebs_csi_driver_irsa ? 1 : 0

  source = "./modules/eks-irsa-role"

  role_description      = "IRSA role for aws-ebs-csi-driver"
  role_name             = "${var.eks_cluster_name}-aws-ebs-csi-driver"
  eks_identity_oidc_url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  oidc_provider_arn     = aws_iam_openid_connect_provider.irsa_provider.arn
  namespace             = var.aws_ebs_csi_driver_namespace
  service_account       = var.aws_ebs_csi_driver_service_account_name
  tags                  = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_ebs_csi_driver" {
  count      = var.enable_aws_ebs_csi_driver_irsa ? 1 : 0
  role       = module.aws_ebs_csi_irsa_role[count.index].role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy"
}
