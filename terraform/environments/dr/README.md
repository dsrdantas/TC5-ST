# Environment: DR (Disaster Recovery)

**Status:** Implementado (Warm Standby skeleton).

## Estrategia

**Warm Standby cross-region (us-west-2)** focado no `donation-service` (Hot Path):

### Criado
- **VPC + EKS**: cluster skeleton com 1 node (escalavel a 3 via `scripts/dr-failover.sh`)
- **RDS `donation-db`**: read replica cross-region criptografada, promovida em failover
- **ECR**: repositorios dos 3 servicos em us-west-2 (suportam failover)
- **SQS**: fila `solidary-donations` recriada em us-west-2 (mensagens em voo se perdem — trade-off aceitavel)

### Não criado
- **RDS `ngo_db`**: nao-critico (backup via Velero, RPO 24h aceitavel)
- **DynamoDB**: replica via Global Tables habilitada no **primary** quando `dynamodb_replica_regions = ["us-west-2"]`

## Como ativar (primeira vez)

1. Assumir que `terraform/environments/primary` ja foi provisionado
2. Obter o `donation_db_arn` do primary:
   ```bash
   cd terraform/environments/primary
   terraform output donation_db_arn  # ou donation_db_endpoint se ARN nao for output
   ```
3. Preencher `terraform/environments/dr/terraform.tfvars`:
   ```bash
   cd terraform/environments/dr
   cp terraform.tfvars.example terraform.tfvars
   # editar: kubernetes_version (compativel com primary), repository, primary_donation_db_arn
   ```
4. Provisionar:
   ```bash
   cd terraform/environments/dr
   terraform init -backend-config="bucket=tc5-solidarytech-tfstate-{ACCOUNT_ID}" \
                  -backend-config="dynamodb_table=tc5-solidarytech-tflock-{ACCOUNT_ID}"
   terraform apply
   ```
   (~15-20 min)

## Tags FinOps (DR)

| Tag | Valor |
|-----|-------|
| `Project` | `SolidaryTech` |
| `Environment` | `DR` |
| `CostCenter` | `NGO-Core` |
| `ManagedBy` | `Terraform` |
| `Repository` | `<seu-repositorio-git>` (configurável via `repository` variable) |

`Environment=DR` (em vez de Production) permite alertas separados de FinOps e filtros de billing.
