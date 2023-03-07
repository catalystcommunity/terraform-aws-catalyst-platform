output "role_arn" {
  description = "ARN of IAM role"
  value       = aws_iam_role.role.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value = aws_iam_role.role.name
}

output "role_id" {
  description = "Id of the IAM role"
  value = aws_iam_role.role.id
}