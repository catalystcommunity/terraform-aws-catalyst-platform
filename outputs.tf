output "eks_cluster_id" {
  value = aws_eks_cluster.cluster.id
}

output "eks_cluster_arn" {
  value = aws_eks_cluster.cluster.arn
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "eks_cluster_certificate_authority_data" {
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "eks_identity_oidc_url" {
  value = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

output "eks_irsa_provider_arn" {
  value = aws_iam_openid_connect_provider.irsa_provider.arn
}

output "cluster_autoscaler_irsa_role_arn" {
  value = module.cluster_autoscaler_irsa_role.role_arn
}

output "velero_s3_bucket_id" {
  value = try(aws_s3_bucket.velero[0].id, "")
}

output "velero_irsa_role_arn" {
  value = try(module.velero_irsa_role[0].role_arn, "")
}

output "loki_s3_bucket_id" {
  value = try(aws_s3_bucket.loki[0].id, "")
}

output "loki_irsa_role_arn" {
  value = try(module.loki_irsa_role[0].role_arn, "")
}

output "cortex_s3_bucket_id" {
  value = try(aws_s3_bucket.cortex[0].id, "")
}

output "cortex_irsa_role_arn" {
  value = try(module.cortex_irsa_role[0].role_arn, "")
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}
