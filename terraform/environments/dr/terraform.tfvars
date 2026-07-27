aws_region     = "us-west-2"
primary_region = "us-east-1"
project_name   = "solidarytech"

# AWS Academy: descobrir com `aws sts get-caller-identity`
# ARN identico em todas as regioes para a mesma conta
lab_role_arn = "arn:aws:iam::918923609441:role/LabRole"

# Kubernetes version (deve ser igual ao primary para consistencia)
# Descobrir com: aws eks describe-cluster-versions --region us-west-2
kubernetes_version = "1.31"

# Repository Git para tagging
repository = "github.com/dsrdantas/TC5-ST"

# Necessario para criar RDS read replica cross-region.
# Obter do output do primary: terraform -chdir=../primary output -raw donation_db_arn
# ou construir manualmente: arn:aws:rds:us-east-1:ACCOUNT_ID:db:solidarytech-donation-db
primary_donation_db_arn = "arn:aws:rds:us-east-1:918923609441:db:solidarytech-donation-db"

# DR posture skeleton — 1 node em standby
node_desired_size = 1
