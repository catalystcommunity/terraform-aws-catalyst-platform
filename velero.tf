# optional velero dependencies
resource "aws_s3_bucket" "velero" {
  count  = var.enable_velero_dependencies ? 1 : 0
  bucket = "${data.aws_caller_identity.current.account_id}-${var.eks_cluster_name}-velero"
  tags   = var.tags
}

resource "aws_s3_bucket_acl" "velero" {
  count  = var.enable_velero_dependencies ? 1 : 0
  bucket = aws_s3_bucket.velero[count.index].id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero" {
  count  = var.enable_velero_dependencies ? 1 : 0
  bucket = aws_s3_bucket.velero[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "velero" {
  count = var.enable_velero_dependencies ? 1 : 0

  statement {
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.velero[count.index].id}/*"]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.velero[count.index].id}"]
  }
}

module "velero_irsa_role" {
  count = var.enable_velero_dependencies ? 1 : 0

  # TODO source from registry after initial publish instead ?
  source = "./modules/eks-irsa-role"

  role_description      = "IRSA role for Velero"
  role_name             = "${var.eks_cluster_name}-velero"
  enable_policy         = true
  policy_document       = data.aws_iam_policy_document.velero[count.index].json
  eks_identity_oidc_url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  oidc_provider_arn     = aws_iam_openid_connect_provider.irsa_provider.arn
  namespace             = var.velero_namespace
  service_account       = var.velero_service_account_name
  tags                  = var.tags
}

