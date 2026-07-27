variable "aws_region" {
  description = "Regiao AWS de DR."
  type        = string
  default     = "us-west-2"
}

variable "primary_region" {
  description = "Regiao do ambiente primario (source da RDS replica)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo logico para nomear recursos (sufixo -dr aplicado onde apropriado)."
  type        = string
  default     = "solidarytech"
}

variable "azs" {
  description = "AZs em us-west-2."
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "lab_role_arn" {
  description = "ARN do LabRole da AWS Academy (mesma conta, ARN identico em todas as regioes)."
  type        = string
}

variable "kubernetes_version" {
  description = "Versao do Kubernetes (mesma do primary para consistencia). Verificar: aws eks describe-cluster-versions --region us-west-2 --query 'clusterVersions[?valid].version'"
  type        = string
}

variable "repository" {
  description = "URL do repositorio Git (para tagging)."
  type        = string
}

variable "primary_donation_db_arn" {
  description = "ARN completo do RDS donation-db no primary. Necessario para criar a read replica cross-region. Ex: arn:aws:rds:us-east-1:ACCOUNT_ID:db:solidarytech-donation-db"
  type        = string
}

variable "node_desired_size" {
  description = "Nodes EKS no DR: 1 em modo skeleton (custo minimo); failover escala via dr-failover.sh"
  type        = number
  default     = 1
}
