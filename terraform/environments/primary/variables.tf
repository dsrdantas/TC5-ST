variable "aws_region" {
  description = "Regiao AWS do ambiente primary."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo logico para nomear recursos."
  type        = string
  default     = "solidarytech"
}

variable "azs" {
  description = "Availability zones (2 minimo)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "lab_role_arn" {
  description = "ARN do LabRole da AWS Academy (usado para cluster e nodes)."
  type        = string
}

variable "db_username" {
  description = "Master username dos RDS."
  type        = string
  default     = "solidary"
}

variable "db_password" {
  description = "Master password dos RDS (NUNCA commitar — use terraform.tfvars local)."
  type        = string
  sensitive   = true
}

variable "kubernetes_version" {
  description = "Versao do Kubernetes. Verificar: aws eks describe-cluster-versions --region us-east-1 --query 'clusterVersions[?valid].version'"
  type        = string
}

variable "postgres_version" {
  description = "Versao do PostgreSQL. Verificar: aws rds describe-db-engine-versions --engine postgres --region us-east-1"
  type        = string
}

variable "repository" {
  description = "URL do repositorio Git (para tagging). Ex: github.com/seu-usuario/seu-repo"
  type        = string
}

variable "github_user" {
  description = "Usuario GitHub (para substituir placeholder <GITHUB_USER> em manifestos GitOps e self-healing-bridge)."
  type        = string
}

variable "node_desired_size" {
  # Decisao herdada da FASE 4: 3 nodes minimo. Justificativa: t3.medium tem
  # limite de ~17 pods/node via AWS VPC CNI (n_ENIs do tipo de instancia).
  # Com monitoring stack (13 pods) + ArgoCD (7) + NGINX Ingress + microsservicos
  # (>7) + Velero, 2 nodes saturam — confirmado no Sprint 5 com "Too many pods"
  # forcando scale para 3.
  description = "Quantidade desejada de nodes. Minimo 3 para acomodar stack monitoring + GitOps + microsservicos (limite ~17 pods/node em t3.medium)."
  type        = number
  default     = 3
}

variable "dynamodb_replica_regions" {
  description = "Regioes para replicas DynamoDB Global Tables (DR). Vazio por default; setado explicitamente para [\"us-west-2\"] quando DR for ativado."
  type        = list(string)
  default     = []
}
