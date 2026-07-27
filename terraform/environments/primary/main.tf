module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  cluster_name       = "${var.project_name}-cluster"
  azs                = var.azs
  single_nat_gateway = true
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
}

module "messaging" {
  source = "../../modules/messaging"
}

module "databases" {
  source = "../../modules/databases"

  project_name          = var.project_name
  private_subnet_ids    = module.networking.private_subnet_ids
  rds_security_group_id = module.networking.rds_postgres_sg_id

  db_username      = var.db_username
  db_password      = var.db_password
  postgres_version = var.postgres_version

  # primary nao precisa Multi-AZ no MVP — DR cross-region cobre.
  multi_az = false

  # DynamoDB Global Tables: habilitar replicas apenas quando DR for ativado
  # (setando dynamodb_replica_regions = ["us-west-2"] em terraform.tfvars)
  dynamodb_replica_regions = var.dynamodb_replica_regions
}

module "eks" {
  source = "../../modules/eks"

  project_name           = var.project_name
  cluster_name           = "${var.project_name}-cluster"
  kubernetes_version     = var.kubernetes_version
  cluster_role_arn       = var.lab_role_arn
  node_role_arn          = var.lab_role_arn
  private_subnet_ids     = module.networking.private_subnet_ids
  public_subnet_ids      = module.networking.public_subnet_ids
  node_security_group_id = module.networking.eks_nodes_sg_id

  node_desired_size = var.node_desired_size

  additional_tags = {
    Project     = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "NGO-Core"
  }
}
