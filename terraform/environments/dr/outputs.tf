data "aws_caller_identity" "current" {}

output "aws_account_id" {
  description = "AWS Account ID (para substituir <AWS_ACCOUNT_ID> em gitops manifests)."
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  value = var.aws_region
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "donation_db_dr_endpoint" {
  description = "Endpoint do RDS donation-db DR (read replica ate promocao)."
  value       = aws_db_instance.donation_replica.endpoint
}

output "donation_db_dr_address" {
  value = aws_db_instance.donation_replica.address
}

output "sqs_queue_url" {
  value = module.messaging_dr.queue_url
}

output "sqs_dlq_url" {
  value = module.messaging_dr.dlq_url
}

# ECR
output "ecr_repository_urls" {
  description = "URLs dos repositorios ECR em us-west-2 (DR)."
  value       = module.ecr.repository_urls
}
