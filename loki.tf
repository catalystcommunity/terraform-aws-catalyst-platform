# optional loki dependencies
locals {
  create_loki_bucket = var.enable_loki_dependencies && var.create_loki_bucket

  default_loki_bucket_name = "${data.aws_caller_identity.current.account_id}-${var.eks_cluster_name}-loki"
  loki_bucket_name         = coalesce(var.loki_bucket_name_override, local.default_loki_bucket_name)
}

resource "aws_s3_bucket" "loki" {
  count  = local.create_loki_bucket ? 1 : 0
  bucket = local.loki_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_acl" "loki" {
  count  = local.create_loki_bucket ? 1 : 0
  bucket = aws_s3_bucket.loki[count.index].id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki" {
  count  = local.create_loki_bucket ? 1 : 0
  bucket = aws_s3_bucket.loki[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "loki" {
  count = var.enable_loki_dependencies ? 1 : 0

  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = [
      "arn:aws:s3:::${local.loki_bucket_name}",
      "arn:aws:s3:::${local.loki_bucket_name}/*",
    ]
  }
}

module "loki_irsa_role" {
  count = var.enable_loki_dependencies ? 1 : 0

  # TODO source from registry after initial publish instead ?
  source = "./modules/eks-irsa-role"

  role_description      = "IRSA role for Loki"
  role_name             = "${var.eks_cluster_name}-loki"
  enable_policy         = true
  policy_document       = data.aws_iam_policy_document.loki[count.index].json
  eks_identity_oidc_url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  oidc_provider_arn     = aws_iam_openid_connect_provider.irsa_provider.arn
  namespace             = var.loki_namespace
  service_account       = var.loki_service_account_name
  tags                  = var.tags
}
