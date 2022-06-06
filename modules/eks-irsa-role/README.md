<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_identity_oidc_url"></a> [eks\_identity\_oidc\_url](#input\_eks\_identity\_oidc\_url) | EKS cluster OIDC provider URL | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace of service account that will assume the IAM role | `string` | n/a | yes |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | EKS cluster OIDC provider ARN | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of IAM role | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Kubernetes servicea ccount name that will assume the IAM role | `string` | n/a | yes |
| <a name="input_enable_policy"></a> [enable\_policy](#input\_enable\_policy) | Whether to manage an IAM policy and attach it to the IRSA role | `bool` | `false` | no |
| <a name="input_policy_description"></a> [policy\_description](#input\_policy\_description) | Optional description of policy to create, defaults to the role description if not supplied | `string` | `""` | no |
| <a name="input_policy_document"></a> [policy\_document](#input\_policy\_document) | IAM policy to add to the IAM role | `string` | `""` | no |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | Optional name of policy to create, defaults to the role name if not supplied | `string` | `""` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Description of the IAM role | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the IAM role | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of IAM role |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Modules

No modules.
<!-- END_TF_DOCS -->