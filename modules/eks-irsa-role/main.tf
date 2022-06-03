data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(var.eks_identity_oidc_url, "https://")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account}"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = var.role_name
  description        = var.role_description
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = var.tags
}

# create optional policy with role attachment if a policy is specified
resource "aws_iam_policy" "policy" {
  count       = var.enable_policy ? 1 : 0
  name        = coalesce(var.policy_name, "${var.role_name}-policy")
  description = coalesce(var.policy_description, var.role_description)
  policy      = var.policy_document
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "attachment" {
  count      = var.enable_policy ? 1 : 0
  policy_arn = aws_iam_policy.policy[count.index].arn
  role       = aws_iam_role.role.name
}
