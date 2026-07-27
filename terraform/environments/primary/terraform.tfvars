aws_region   = "us-east-1"
project_name = "solidarytech"

# AWS Academy: descobrir com `aws sts get-caller-identity`
# Tipico: arn:aws:iam::918923609441:role/LabRole
lab_role_arn = "arn:aws:iam::918923609441:role/LabRole"

# Kubernetes version. Descobrir com:
# aws eks describe-cluster-versions --region us-east-1 --query 'clusterVersions[?valid].version' --output text
kubernetes_version = "1.31"

# PostgreSQL version. Descobrir com:
# aws rds describe-db-engine-versions --engine postgres --region us-east-1 --query 'DBEngineVersions[?Engine==`postgres`].EngineVersion' --output text
postgres_version = "16.14"

# Repository Git para tagging. Ex: github.com/seu-usuario/seu-repo
repository = "github.com/dsrdantas/TC5-ST"

# Master password dos RDS. NUNCA commitar este arquivo (esta no .gitignore).
db_username = "solidary"
db_password = "1234abc"

# Nodes do EKS. Minimo 3 (decisao herdada FASE 4): t3.medium tem limite
# de ~17 pods/node via AWS VPC CNI; com monitoring+ArgoCD+microsservicos,
# 2 nodes saturam.
node_desired_size = 3

# DynamoDB Global Tables (DR — ativar apenas quando o ambiente DR for provisionado)
# Deixar vazio [] por default; setado para ["us-west-2"] quando DR for ativado.
# dynamodb_replica_regions = []
