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

  # allow for configuring optional extra statements for the assume role policy
  dynamic "statement" {
    for_each = var.extra_assume_role_policy_statements
    content {
      actions       = statement.value.actions
      effect        = statement.value.effect
      not_actions   = statement.value.not_actions
      not_resources = statement.value.not_resources
      resources     = statement.value.resources
      sid           = statement.value.sid

      dynamic "condition" {
        for_each = statement.value.conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }

      dynamic "principals" {
        for_each = statement.value.principals
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = statement.value.not_principals
        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }
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
