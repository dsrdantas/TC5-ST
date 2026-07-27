# DR environment (us-west-2) — Warm Standby skinny.
# Apenas o necessario para o donation-service (Hot Path) sobreviver a failover regional:
#   - VPC propria + EKS (1 node skeleton)
#   - RDS donation-db como Cross-Region Read Replica do primary
#   - ECR em us-west-2 (mesmo modulo do primary)
#   - SQS recriada (mensagens em voo se perdem, conforme PCN.md)
#
# NAO criado aqui (cobertos por outros mecanismos):
#   - ngo-db (Velero backup cobre — RPO 24h aceitavel)
#   - DynamoDB volunteers (Global Tables ja replica nativamente — config no primary)

module "networking" {
  source = "../../modules/networking"

  project_name       = "${var.project_name}-dr"
  cluster_name       = "${var.project_name}-cluster-dr"
  azs                = var.azs
  single_nat_gateway = true # FinOps: 1 NAT em DR e suficiente
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = "${var.project_name}-dr"
}

module "eks" {
  source = "../../modules/eks"

  project_name           = "${var.project_name}-dr"
  cluster_name           = "${var.project_name}-cluster-dr"
  kubernetes_version     = var.kubernetes_version
  cluster_role_arn       = var.lab_role_arn
  node_role_arn          = var.lab_role_arn
  private_subnet_ids     = module.networking.private_subnet_ids
  public_subnet_ids      = module.networking.public_subnet_ids
  node_security_group_id = module.networking.eks_nodes_sg_id

  # Skeleton: 1 node em DR posture. scripts/dr-failover.sh escala para 3.
  node_desired_size = var.node_desired_size
  node_min_size     = 1
  node_max_size     = 4

  additional_tags = {
    Project     = "SolidaryTech"
    Environment = "DR"
    CostCenter  = "NGO-Core"
  }
}

# -----------------------------------------------------------------------------
# RDS donation-db — Cross-Region Read Replica do primary
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "donation_dr" {
  name       = "${var.project_name}-dr-rds-subnet-group"
  subnet_ids = module.networking.private_subnet_ids

  tags = {
    Name = "${var.project_name}-dr-rds-subnet-group"
  }
}

# KMS key para encriptacao da replica cross-region (AWS requer key explícita no destino)
data "aws_kms_key" "rds_default" {
  key_id = "alias/aws/rds"
}

resource "aws_db_instance" "donation_replica" {
  identifier             = "${var.project_name}-donation-db-dr"
  instance_class         = "db.t3.micro"
  replicate_source_db    = var.primary_donation_db_arn # ARN cross-region completo
  db_subnet_group_name   = aws_db_subnet_group.donation_dr.name
  vpc_security_group_ids = [module.networking.rds_postgres_sg_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  storage_encrypted      = true
  kms_key_id             = data.aws_kms_key.rds_default.arn # requerido para replica cross-region criptografada
  apply_immediately      = true

  # Performance Insights tambem em DR (necessario para SRE/SLO mesmo no failover)
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  tags = {
    Name      = "${var.project_name}-donation-db-dr"
    Component = "database"
    Service   = "donation"
    Role      = "cross-region-read-replica"
  }
}

# -----------------------------------------------------------------------------
# SQS — recriada em DR (mensagens em voo se perdem no failover, ver PCN.md)
# -----------------------------------------------------------------------------
module "messaging_dr" {
  source = "../../modules/messaging"
}
