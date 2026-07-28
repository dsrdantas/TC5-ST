# 🚀 SolidaryTech — Hackathon Fase 5

Bem-vindo ao repositório oficial da **SolidaryTech**.

Este monorepo contém os microsserviços que compõem a plataforma da ONG e a infraestrutura completa para deploy em AWS EKS com observabilidade, CI/CD, e Disaster Recovery.

## ✅ Status

- ✅ **Terraform IaC**: 5 módulos (networking, eks, databases, messaging, ecr)
- ✅ **Primary Environment** (us-east-1): EKS cluster, RDS PostgreSQL, DynamoDB, SQS
- ✅ **DR Environment** (us-west-2): EKS cluster, RDS read-replica, ECR, SQS
- ✅ **CI/CD Workflows**: Setup, Deploy, DR Drill, Destroy
- ✅ **Observability**: Prometheus, Grafana, Loki, OpenTelemetry, New Relic APM
- ✅ **GitOps**: ArgoCD, NGINX Ingress, automated deployments
- ✅ **FinOps Tags**: Project, Environment, CostCenter em todos os recursos

## 🎯 Conceitos Implementados

- **SRE**: SLOs, Error Budgets, Alertas inteligentes, DR planning
- **FinOps**: Tags estruturadas, cost tracking, FinOps compliance
- **Observability**: Traces (OTEL → New Relic), Metrics (Prometheus), Logs (Loki)
- **Resiliência**: Multi-AZ primary, cross-region DR, health checks, auto-healing
- **Kubernetes & GitOps**: ArgoCD para sync automático, NGINX para ingress
- **IaC**: Terraform 100% versionado, state remoto em S3

---

# 🚀 Deploy Automático via GitHub Actions

## Workflows Disponíveis

### 1. **Setup Full Stack** (`setup-full-workflow.yaml`)
Provisiona ambiente completo: Terraform + Kubernetes + Observability

**Triggers:**
- Manual: `workflow_dispatch` com `auto_approve` input
- Automático: push em `deploy/main` branch

**Etapas:**
1. Pre-flight checks (Terraform fmt/validate, Docker)
2. Build & push de imagens (ngo, donation, volunteer)
3. Terraform plan/apply (primary, us-east-1)
4. Gera & aplica Kubernetes secrets
5. Instala ArgoCD, NGINX, Prometheus, Grafana, Loki, OTEL
6. Deploy das aplicações via ArgoCD

**Saída:**
```
- ArgoCD: https://<load-balancer>
- Grafana: http://<load-balancer> (admin / random-password)
- Ingress: http://<load-balancer>
```

### 2. **Setup DR** (`setup-dr-workflow.yaml`)
Provisiona ambiente DR em us-west-2

**Trigger:** Manual com `primary_donation_db_arn` input

**O que faz:**
- Cria VPC + EKS (1 node skeleton)
- RDS read-replica (cross-region do primary)
- ECR repositories
- Instala monitoramento
- Standby mode (pronto para failover)

### 3. **DR Drill** (`dr-drill.yaml`)
Teste mensal de recuperação

**Modos:**
- `dry_run=true` (padrão): `terraform plan` only
- `dry_run=false`: provisionamento + cleanup
- `perform_failover=true`: failover real (DESTRUTIVO)

### 4. **Destroy Environment** (`destroy-environment.yaml`)
Limpeza completa e segura

**Opções:**
- `environment=primary|dr|both`
- Requer confirmação: digitar "DESTROY"

**Cleanup sequence:**
1. Delete Kubernetes namespaces
2. Delete LoadBalancers (ALBs/NLBs)
3. Release Elastic IPs
4. Delete ENIs
5. Delete Security Groups
6. Terraform destroy

### 5. **Self-Healing** (`self-healing.yaml`)
Auto-recovery de pods via GitHub Actions

**Dispara automaticamente quando:**
- `PodCrashLooping` — >3 restarts em 15min
- `HighErrorRate5xx` — >5% de erros em 2min
- `DonationSLOFastBurn` — Error budget queimando rápido

**Fluxo:**
```
Prometheus detecta erro crítico
    ↓
Alertmanager → Webhook Receiver (pod no cluster)
    ↓
GitHub Actions API (com GitHub PAT)
    ↓
self-healing.yaml dispara (workflow_dispatch)
    ↓
kubectl rollout restart deployment/<service>
    ↓
Discord notificado (✅ ou ❌)
```

**Setup necessário:**
- [Gerar GitHub PAT](https://github.com/settings/tokens/new) (escopo: `repo`)
- Criar secret: `kubectl create secret generic github-webhook-token --namespace monitoring --from-literal=token="ghp_xxx"`
- Ver [SELF-HEALING-SETUP.md](docs/SELF-HEALING-SETUP.md) para detalhes completos

---

## 📋 Pré-requisitos para Deploy

### GitHub Secrets Obrigatórios

Configure em: **Settings** → **Secrets and variables** → **Actions**

```
AWS_ACCESS_KEY_ID              # AWS Academy IAM user
AWS_SECRET_ACCESS_KEY          # AWS Academy IAM secret
AWS_SESSION_TOKEN              # AWS Academy session token (4h)
```

### Variáveis de Ambiente Terraform

Arquivo: `terraform/environments/primary/terraform.tfvars`

```hcl
# Criado manualmente ou via descoberta
project_name        = "solidarytech"
aws_region          = "us-east-1"
kubernetes_version  = "1.31"         # aws eks describe-cluster-versions
postgres_version    = "16.4"         # aws rds describe-db-engine-versions
repository          = "dsrdantas/TC5-ST"
db_username         = "solidary"
db_password         = "SecurePass123!"  # NÃO commitar!
lab_role_arn        = "arn:aws:iam::ACCOUNT:role/LabRole"
node_desired_size   = 2
azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
```

### New Relic APM (Opcional)

```bash
# Criar secret com sua license key
kubectl create secret generic newrelic-license-key \
  --namespace monitoring \
  --from-literal=license-key="YOUR_NEW_RELIC_LICENSE_KEY"
```

---

# 🏗️ Arquitetura dos Microsserviços

O ecossistema é composto por **3 microsserviços independentes**, desenvolvidos com tecnologias diferentes para simular um ambiente corporativo distribuído.

---

## 1️⃣ NGO Service — Cadastro de ONGs

| Item | Valor |
|---|---|
| Linguagem | Python 3.9+ |
| Framework | Flask |
| Banco de Dados | PostgreSQL |
| Porta Local | `8081` |

### 📌 Descrição
Responsável pelo gerenciamento e cadastro das ONGs parceiras da plataforma.

---

## 2️⃣ Donation Service — Processamento de Doações

| Item | Valor |
|---|---|
| Linguagem | Go 1.21+ |
| Banco de Dados | PostgreSQL |
| Mensageria | AWS SQS |
| Porta Local | `8082` |

### 📌 Descrição
Este é o **Hot Path** da aplicação.

Responsável pelo processamento das doações e publicação de eventos assíncronos em filas para processamento posterior.

---

## 3️⃣ Volunteer Service — Gestão de Voluntários

| Item | Valor |
|---|---|
| Linguagem | Python 3.9+ |
| Framework | Flask |
| Banco de Dados | AWS DynamoDB |
| Porta Local | `8083` |

### 📌 Descrição
Gerencia o cadastro e inscrição de voluntários interessados em apoiar as ONGs parceiras.

Utiliza armazenamento NoSQL nativo da AWS com foco em escalabilidade.

---

# 📁 Estrutura do Repositório

```text
.
├── ngo-service/          # Código Python e scripts SQL do serviço de ONGs
├── donation-service/     # Código Go e scripts SQL do serviço de doações
└── volunteer-service/    # Código Python do serviço de voluntários
```

---

# 🚀 Executando Localmente

Antes de realizar deploy em Kubernetes e automatizações CI/CD, recomenda-se validar todo o ambiente localmente.

---

# ✅ Pré-requisitos

Certifique-se de possuir os seguintes itens instalados:

- Python 3.9+
- Go 1.21+
- Docker (opcional, mas recomendado)
- PostgreSQL
- AWS CLI configurado
- Credenciais AWS válidas

---

# 🛠️ Passo 1 — Preparação da Infraestrutura

## PostgreSQL

Crie dois bancos de dados independentes:

### Banco `ngo_db`

Execute:

```sql
ngo-service/db/init.sql
```

### Banco `donation_db`

Execute:

```sql
donation-service/db/init.sql
```

---

## AWS DynamoDB

Crie a tabela:

| Configuração | Valor |
|---|---|
| Nome da Tabela | `SolidaryTechVolunteers` |
| Partition Key | `volunteer_id` |
| Tipo | `String` |

---

## AWS SQS

Crie uma fila do tipo **Standard Queue**.

Exemplo:

```text
https://sqs.us-east-1.amazonaws.com/1234567890/solidary-donations
```

Guarde a URL da fila para utilizar nas variáveis de ambiente.

---

# ⚙️ Passo 2 — Variáveis de Ambiente

Crie um arquivo `.env` dentro de cada microsserviço.

---

## 📄 ngo-service/.env

```env
PORT=8081
DATABASE_URL="postgres://SEU_USUARIO:SUA_SENHA@localhost:5432/ngo_db"
```

---

## 📄 donation-service/.env

```env
PORT=8082
DATABASE_URL="postgres://SEU_USUARIO:SUA_SENHA@localhost:5432/donation_db"

AWS_REGION="us-east-1"
AWS_SQS_URL="SUA_URL_DA_FILA_SQS"
```

---

## 📄 volunteer-service/.env

```env
PORT=8083

AWS_REGION="us-east-1"
AWS_DYNAMODB_TABLE="SolidaryTechVolunteers"
```

---

# ▶️ Passo 3 — Inicializando os Serviços

Abra **3 terminais separados**.

---

## 🟣 Terminal 1 — NGO Service

```bash
cd ngo-service

pip install -r requirements.txt

gunicorn --bind 0.0.0.0:8081 app:app
```

---

## 🟠 Terminal 2 — Donation Service

```bash
cd donation-service

go mod tidy

go run .
```

---

## 🔵 Terminal 3 — Volunteer Service

```bash
cd volunteer-service

pip install -r requirements.txt

gunicorn --bind 0.0.0.0:8083 app:app
```

---

# 🌐 Portas Locais

| Serviço | URL |
|---|---|
| NGO Service | http://localhost:8081 |
| Donation Service | http://localhost:8082 |
| Volunteer Service | http://localhost:8083 |

---

# 🎯 Objetivos do Hackathon

O código fornecido representa apenas a base do software.

O verdadeiro desafio está na engenharia, operação e resiliência da plataforma.

---

# 📦 Conteinerização

- Criar Dockerfiles
- Otimizar imagens
- Implementar estratégias multi-stage build
- Reduzir vulnerabilidades

---

# ☁️ Infraestrutura como Código — Terraform

## Estrutura Modular (5 Módulos)

```
terraform/
├── modules/
│   ├── networking/      # VPC, Subnets, Security Groups, NAT Gateway
│   ├── eks/             # EKS cluster, node groups, OIDC provider
│   ├── databases/       # RDS PostgreSQL, DynamoDB, KMS keys
│   ├── messaging/       # SQS queues, DLQ
│   └── ecr/             # ECR repositories
│
└── environments/
    ├── primary/         # us-east-1 production
    │   ├── main.tf      # Module calls + outputs
    │   ├── variables.tf # Input variables + discovery commands
    │   └── terraform.tfvars
    │
    └── dr/              # us-west-2 disaster recovery
        ├── main.tf      # Skeleton cluster + read-replica
        ├── variables.tf
        └── terraform.tfvars
```

## Recursos Provisionados

**Primary (us-east-1):**
- ✅ VPC (10.0.0.0/16) + 3 subnets privadas + 1 pública
- ✅ EKS cluster 1.31 (2-3 nodes, gp3 volumes, IMDSv2)
- ✅ RDS PostgreSQL 16.4 (Multi-AZ, encrypted, backups)
- ✅ DynamoDB Global Tables (cross-region replica)
- ✅ SQS + DLQ para processamento async
- ✅ ECR repositories (ngo, donation, volunteer)
- ✅ NAT Gateway (HA, 1 per AZ)
- ✅ Security Groups (EKS, RDS, VPC flow logs)

**DR (us-west-2):**
- ✅ VPC (10.1.0.0/16) + 3 subnets privadas + 1 pública
- ✅ EKS skeleton (1 node, pronto para scale)
- ✅ RDS read-replica cross-region (criptografia)
- ✅ DynamoDB replicas
- ✅ SQS separada
- ✅ ECR repositórios locais

## Variáveis Obrigatórias

**Necessário descobrir via AWS CLI:**

```bash
# Kubernetes version disponível
aws eks describe-cluster-versions --region us-east-1 \
  --query 'clusterVersions[].version'

# PostgreSQL versions disponível
aws rds describe-db-engine-versions --engine postgres \
  --region us-east-1 \
  --query 'DBEngineVersions[].EngineVersion' | head -5
```

**FinOps Tags (automático):**
- Project: SolidaryTech
- Environment: Production/DR
- CostCenter: NGO-Core
- Aplicadas a: instances, volumes, RDS, DynamoDB, SQS

## 💰 FinOps — Tags e Cost Control

**Todos os recursos recebem tags obrigatórias:**

```
Project     = "SolidaryTech"
Environment = "Production" | "DR"
CostCenter  = "NGO-Core"
```

**Recursos taggados:**
- ✅ EC2 instances (EKS nodes)
- ✅ EBS volumes
- ✅ RDS databases
- ✅ DynamoDB tables
- ✅ VPC, Subnets, Gateways
- ✅ SQS queues
- ✅ ECR repositories

**Rastreamento de custos:**

```bash
# AWS Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=2026-07-01,End=2026-07-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Project
```

**Estimado (AWS us-east-1 + us-west-2):**
- Primary: EKS (~$200/mês) + RDS (~$100) + NAT (~$30)
- DR: EKS skeleton (~$50) + RDS replica (~$50)
- **Total**: ~$430/mês

---

# 🔄 CI/CD & GitOps

Automatizar:

- Testes
- Security Scans
- Build de imagens
- Deploy em Kubernetes

Ferramentas sugeridas:

- GitHub Actions
- ArgoCD
- FluxCD

---

# 📊 Observabilidade — Stack Completo

## Componentes Instalados

| Componente | Tipo | URL/Acesso |
|---|---|---|
| **Prometheus** | Métricas | `http://prometheus-kube-prometheus-prometheus.monitoring:9090` |
| **Grafana** | Dashboards | `http://<load-balancer>` (admin) |
| **Loki** | Logs | `http://loki.monitoring:3100` |
| **Promtail** | Log Shipper | DaemonSet em cada node |
| **OpenTelemetry Collector** | OTEL Hub | gRPC:4317 / HTTP:4318 |
| **New Relic** | APM | `https://one.newrelic.com` (optional) |
| **ArgoCD** | GitOps | `https://<load-balancer>` |

## Métricas Golden Signals

Dashboard: `Solidarytech Overview`

- **Latency**: HTTP Latency P95 by Service
- **Traffic**: HTTP Request Rate by Service
- **Errors**: HTTP Error Rate (5xx) by Service
- **Saturation**: CPU/Memory usage by Namespace

## Alerting

**Alertmanager** com integração:
- Discord webhooks
- PagerDuty (SLO burn)
- Auto-healing via GitHub Actions (opcional)

## Traces & APM

**New Relic Integration:**
1. Forneça license key (ou deixe desativado)
2. OpenTelemetry exporta traces automaticamente
3. Dashboard APM: performance, dependencies, errors

**Local (sem New Relic):**
- Traces são logadas no OTEL Collector
- Veja em: `kubectl logs -n monitoring deployment/otel-collector-opentelemetry-collector`

---

# 🛡️ SRE & Resiliência

## 📊 SLOs & Error Budgets

**Donation Service (Hot Path):**
- **SLO**: 99.5% availability
- **Window**: Monthly (720h)
- **Error budget**: 3.6h downtime/month
- **Alert threshold**: SLO burn-rate 10x (5% in 1h)

**Alertas automáticos:**
```yaml
- SLOFastBurn: 90% budget used in 5% of window
- SLOSlowBurn: 100% budget used in full window
- HighErrorRate5xx: >1% errors
- DonationLatencyP95High: P95 > 500ms
```

## 🤖 Auto-Healing (MTTR Reduction)

**Self-Healing automático** dispara para alertas críticos:

| Alert | Condição | Ação |
|-------|----------|------|
| PodCrashLooping | >3 restarts/15min | `kubectl rollout restart` |
| HighErrorRate5xx | >5% erros/2min | Restart pod |
| DonationSLOFastBurn | Error budget < 2h | Restart pod |

**Fluxo:**
1. Prometheus detecta (30s scrape)
2. Alertmanager avalia (30s group_wait)
3. Webhook Receiver → GitHub Actions API
4. `self-healing.yaml` executa (workflow_dispatch)
5. Pod reinicia, logs em Discord
6. Tempo total: ~3 minutos

**Setup:**
- Gerar [GitHub PAT](https://github.com/settings/tokens/new) (escopo: `repo`)
- `kubectl create secret generic github-webhook-token --namespace monitoring --from-literal=token="ghp_xxx"`
- Ver [SELF-HEALING-SETUP.md](docs/SELF-HEALING-SETUP.md)

**Resultados esperados:**
- ✅ Reduz MTTR (Mean Time To Recovery) de 10min → 3min
- ✅ Logs em Discord para visibilidade
- ✅ Falha após 2 tentativas → escala para on-call

## 🌍 Disaster Recovery Strategy

**Architecture: Warm Standby (Skeleton)**

| Aspecto | Primary (us-east-1) | DR (us-west-2) |
|---|---|---|
| **EKS Nodes** | 2-3 (production) | 1 (skeleton) |
| **RDS** | Primary database | Read-replica |
| **DynamoDB** | Global Tables (replica) | Global Tables (replica) |
| **SQS** | Active queue | Separate (messages lost) |
| **RPO** | Near-zero | 5 min (RDS) / variable (DynamoDB) |
| **RTO** | N/A | 15-30 min (manual failover + scale) |

**Failover Manual:**
```bash
# 1. Promote RDS read-replica
aws rds promote-read-replica --db-instance-identifier solidarytech-donation-db-dr

# 2. Scale EKS to 3 nodes
aws eks update-nodegroup-config --cluster-name solidarytech-cluster-dr \
  --nodegroup-name solidarytech-nodegroup-dr \
  --scaling-config desiredSize=3

# 3. Switch DNS (route53)
# 4. Verify data sync
```

**DR Drill (mensal):**
```bash
# Teste ponta-a-ponta sem afetar production
gh workflow run dr-drill.yaml -f dry_run=false
```

**Foco Principal:** `donation-service` → Hot Path → RTO < 30min, RPO < 5min

---

# 📚 Tecnologias Envolvidas

- Python
- Flask
- Go
- PostgreSQL
- DynamoDB
- AWS SQS
- Docker
- Kubernetes
- Terraform
- GitOps
- OpenTelemetry

---

# 🔧 Troubleshooting

## Workflows falhando

**Erro: Module not installed**
```bash
# Solução: terraform init antes de validate
terraform init -backend=false
terraform validate
```

**Erro: ECR não existe**
- Workflow deve rodar `terraform apply` ANTES de `build-images`
- Verifique `needs: [terraform-apply]` no build-images job

**Erro: Kubernetes secrets faltando**
```bash
# Regenerar
./scripts/generate-secrets.sh
./scripts/apply-secrets.sh
```

## Cleanup de recursos órfãos

**LoadBalancers / ALBs**
```bash
aws elbv2 describe-load-balancers --region us-east-1
aws elbv2 delete-load-balancer --load-balancer-arn <arn>
```

**Elastic IPs não associados**
```bash
aws ec2 describe-addresses --filters "Name=domain,Values=vpc" \
  --query 'Addresses[?AssociationId==null]'
aws ec2 release-address --allocation-id <id>
```

**Security Groups órfãos**
```bash
aws ec2 delete-security-group --group-id <id>
```

---

# 📚 Referências

## Documentação por Módulo

- [terraform/modules/networking/README.md](terraform/modules/networking/README.md)
- [terraform/modules/eks/README.md](terraform/modules/eks/README.md)
- [terraform/modules/databases/README.md](terraform/modules/databases/README.md)
- [terraform/modules/messaging/README.md](terraform/modules/messaging/README.md)
- [terraform/modules/ecr/README.md](terraform/modules/ecr/README.md)
- [terraform/environments/primary/README.md](terraform/environments/primary/README.md)
- [terraform/environments/dr/README.md](terraform/environments/dr/README.md)

## Arquivos de Configuração

- [.github/workflows/](github/workflows/) — CI/CD pipelines
- [gitops/](gitops/) — ArgoCD applications
- [scripts/](scripts/) — Helper scripts
- [docs/](docs/) — Documentation & diagrams

## Ferramentas Recomendadas

```bash
# CLI tools
brew install awscli kubectl helm terraform

# Verify versions
aws --version
kubectl version --client
helm version
terraform version
```

---

# 🚀 Quick Start

**1. Setup local:**
```bash
# Clone
git clone https://github.com/dsrdantas/TC5-ST.git
cd TC5-ST

# Configure credentials
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...

# Check Terraform
cd terraform/environments/primary
terraform init -backend=false
terraform validate
```

**2. Deploy via GitHub:**
- Push para `deploy/main`
- OU: Manual trigger: Actions → Setup Full Stack → Run workflow

**3. Monitor:**
```bash
# Get load balancer URLs
kubectl get svc -A

# Check pods
kubectl get pods -n solidarytech

# View logs
kubectl logs -n solidarytech deployment/donation-service
```

**4. Access UIs:**
- ArgoCD: `https://<load-balancer>`
- Grafana: `http://<load-balancer>`
- Apps: `http://<ingress-load-balancer>`

---

# 🤝 Contribuição

Este projeto foi criado exclusivamente para fins educacionais e execução do Hackathon Fase 5.

Sinta-se livre para evoluir a arquitetura, melhorar a observabilidade e implementar boas práticas de engenharia de plataforma.

---

# 🏁 Boa sorte!

Bom Hackathon 🚀

Faça a diferença com a **SolidaryTech** 💙