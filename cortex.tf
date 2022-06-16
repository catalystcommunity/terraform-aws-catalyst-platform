# optional cortex dependencies
locals {
  create_cortex_bucket = var.enable_cortex_dependencies && var.create_cortex_bucket

  default_cortex_bucket_name = "${data.aws_caller_identity.current.account_id}-${var.eks_cluster_name}-cortex"
  cortex_bucket_name         = coalesce(var.cortex_bucket_name_override, local.default_cortex_bucket_name)
}

resource "aws_s3_bucket" "cortex" {
  count  = local.create_cortex_bucket ? 1 : 0
  bucket = local.cortex_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_acl" "cortex" {
  count  = local.create_cortex_bucket ? 1 : 0
  bucket = aws_s3_bucket.cortex[count.index].id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cortex" {
  count  = local.create_cortex_bucket ? 1 : 0
  bucket = aws_s3_bucket.cortex[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "cortex" {
  count = var.enable_cortex_dependencies ? 1 : 0

  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cortex[count.index].id}",
      "arn:aws:s3:::${aws_s3_bucket.cortex[count.index].id}/*",
    ]
  }
}

module "cortex_irsa_role" {
  count = var.enable_cortex_dependencies ? 1 : 0

  # TODO source from registry after initial publish instead ?
  source = "./modules/eks-irsa-role"

  role_description      = "IRSA role for cortex"
  role_name             = "${var.eks_cluster_name}-cortex"
  enable_policy         = true
  policy_document       = data.aws_iam_policy_document.cortex[count.index].json
  eks_identity_oidc_url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  oidc_provider_arn     = aws_iam_openid_connect_provider.irsa_provider.arn
  namespace             = var.cortex_namespace
  service_account       = var.cortex_service_account_name
  tags                  = var.tags
}
