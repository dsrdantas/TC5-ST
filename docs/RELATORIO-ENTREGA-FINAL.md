# 🚀 POSTECH - DCLT - Hackathon Fase 5
## Relatório Final de Entrega — SolidaryTech

---

## 📋 Informações do Projeto

### Equipe

| Nome | RM | Username Discord |
|------|----|----|
| Daniel da Silva Rodrigues Dantas | [RM367539] | pl0c_ |
| Thiago Viegas | [RM367590] | oviegas_60314 |

### Links de Referência

- **Repositório de Código**: https://github.com/dsrdantas/TC5-ST
- **Vídeo de Apresentação**: https://github.com/dsrdantas/TC5-ST/blob/main/docs/tc5-st.mp4
- **Documentação Técnica**: https://github.com/dsrdantas/TC5-ST/tree/main/docs

---

## 🎯 Resumo Executivo

SolidaryTech é uma plataforma de doações para ONGs, implementada com arquitetura de microsserviços em Kubernetes com foco em **SRE**, **FinOps**, **Disaster Recovery** e **AIOps**.

**Status**: ✅ Completo e Funcional

---

# 📊 SEÇÃO SRE - Service Level Objectives

## Definição Formal de SLI, SLO e SLA

### Service Level Indicator (SLI)

**SLI #1: Disponibilidade (Availability)**
- **Definição**: Percentual de requisições HTTP que NÃO retornam 5xx
- **Métrica**: `(1 - taxa_erros_5xx) × 100%`
- **Objetivo**: ≥ 99.9%
- **Janela**: 30 dias (720 horas)

**SLI #2: Latência (Latency)**
- **Definição**: P95 da latência de resposta HTTP
- **Métrica**: `histogram_quantile(0.95, http_request_duration_seconds)`
- **Objetivo**: < 300ms
- **Janela**: Continuous

**SLI #3: Taxa de Erro 5xx**
- **Definição**: Requisições com status code 500-599
- **Métrica**: `rate(http_5xx_errors[5m])`
- **Alerta**: > 5% por 2 minutos = CRITICAL

### Service Level Objective (SLO)

```
SLO: 99.9% de disponibilidade + P95 < 300ms
Janela: 30 dias (720 horas)
```

**Cálculo de Error Budget:**
```
Error Budget = (1 - SLO) × Janela
            = (1 - 0.999) × 720h
            = 0.001 × 720h
            = 0.72 horas
            ≈ 43.2 minutos/mês
```

**Interpretação**: Podemos ter no máximo ~43 minutos de downtime por mês sem violar SLO.

### Service Level Agreement (SLA)

```
SLA com ONGs Parceiras: 99.5% de disponibilidade
Penalidade: Créditos por downtime acima de 99.5%
Diferença SLO/SLA: Margem de segurança de 0.4%
```

### Burn Rate Alerts

| Alert | Condição | Limiar |
|-------|----------|--------|
| **SLOFastBurn** | Queima 14.4x o orçamento | 2+ horas para esgotar |
| **SLOSlowBurn** | Queima 1x o orçamento | 6 horas para esgotar |

**Exemplo**: Se error rate = 14.4%, SLO queima em ~2 horas → Dispara FastBurn → Pagerduty + Self-Heal

---

# 💰 SEÇÃO FINOPS - Financial Operations

## Análise de Custos Mensais (Forecast)

### Estimativa de Custo Mensal - Primary (us-east-1)

| Recurso | Quantidade | Preço Unit | Subtotal |
|---------|-----------|------------|----------|
| **EKS Cluster** | 1 cluster | $70.00 | $70.00 |
| **EC2 Instances** | 2 nodes (t3.medium) | $35.00/mês | $70.00 |
| **RDS PostgreSQL** | 1 instância (db.t3.micro) | $80.00 | $80.00 |
| **DynamoDB** | On-demand | ~$25.00 | $25.00 |
| **NAT Gateway** | 1 gateway | $35.00 | $35.00 |
| **Data Transfer** | ~100GB/mês | $0.09/GB | $9.00 |
| **Storage (EBS)** | 100GB | $10.00 | $10.00 |
| **CloudWatch/Logging** | | | $20.00 |
| **Subtotal Primary** | | | **$319.00** |

### Estimativa de Custo Mensal - DR (us-west-2)

| Recurso | Quantidade | Preço Unit | Subtotal |
|---------|-----------|------------|----------|
| **EKS Cluster** | 1 cluster (skeleton) | $70.00 | $70.00 |
| **EC2 Instances** | 1 node (t3.micro) | $10.00/mês | $10.00 |
| **RDS Read-Replica** | 1 instância (db.t3.micro) | $30.00 | $30.00 |
| **Subtotal DR** | | | **$110.00** |

### Custo Total Mensal

```
Primary (us-east-1):    $319.00
DR (us-west-2):         $110.00
─────────────────────────────────
TOTAL MENSAL:           $429.00
TOTAL ANUAL:           $5,148.00
```

### Tags de FinOps Aplicadas

Todas as tags são aplicadas via Terraform em todos os recursos:

```yaml
Project:       "SolidaryTech"
Environment:   "Production" (primary) | "DR" (us-west-2)
CostCenter:    "NGO-Core"
CreatedBy:     "Terraform"
ManagedBy:     "Terraform"
```

**Exemplo em EC2:**
```bash
$ aws ec2 describe-instances \
  --query 'Reservations[0].Instances[0].Tags'
[
  {"Key": "Project", "Value": "SolidaryTech"},
  {"Key": "Environment", "Value": "Production"},
  {"Key": "CostCenter", "Value": "NGO-Core"}
]
```

### Estratégia de Otimização de Custos

1. **Usar Reserved Instances** para workload previsível (RDS, NAT) → Economizar 40-60%
2. **Auto-scaling de nodes** baseado em demand → Reduzir EC2 em off-peak
3. **DynamoDB On-Demand** para picos ocasionais (vs. Provisioned)
4. **Deletar recursos não usados** (snapshots, elastic IPs) → Economizar ~$20-30/mês
5. **Cost anomaly detection** via AWS Budgets

**Economia Potencial**: -15% = $64/mês (~$768/ano)

---

# 🛡️ SEÇÃO SEGURANÇA E DISASTER RECOVERY

## PCN - Performance Characteristics & Non-Functional Requirements

### RPO (Recovery Point Objective)

| Componente | RPO | Método |
|-----------|-----|--------|
| **RDS PostgreSQL** | 5 minutos | Read-replica com binlogs |
| **DynamoDB** | < 1 segundo | Global Tables |
| **SQS Messages** | N/A | Perdidas em failover |
| **EBS Volumes** | 15 minutos | Snapshots AWS Backup |
| **Application Code** | < 1 segundo | ECR replicated |

**Interpretação**: Podemos perder até 5 minutos de transações de banco de dados.

### RTO (Recovery Time Objective)

| Passo | Tempo | Ação |
|------|-------|------|
| 1. Detectar failover | 2 min | Health check falha |
| 2. Promover RDS replica | 3 min | AWS RDS API call |
| 3. Scale EKS DR | 5 min | Aumentar node group |
| 4. Update DNS/ALB | 1 min | Route53 change |
| 5. Verificar saúde | 2 min | Health checks pass |
| **TOTAL RTO** | **~15 min** | Manual + 5 min tolerância |

**Interpretação**: Failover completo em 15-30 minutos.

### Padrão de DR: Warm Standby (Skeleton)

```
PRIMARY (us-east-1)              DR (us-west-2)
─────────────────────────────────────────────────
EKS: 2-3 nodes (prod)            EKS: 1 node (skeleton)
RDS: Primary DB                  RDS: Read-replica (standby)
DynamoDB: Active                 DynamoDB: Replica (sync)
SQS: Active queue                SQS: Separate queue
ECR: Active repos                ECR: Replicated repos
NAT: Active                       NAT: Standby
```

**Vantagens:**
- Reduz custo (nodes mínimos em DR)
- Rápido scale-up (infraestrutura pré-provisionada)
- Dados sincronizados em tempo real

**Desvantagens:**
- Perda de mensagens SQS em voo
- Latência cross-region (~50ms)
- Requer failover manual

### Estratégia de Failover

**Fase 1: Detecção (Automática)**
- CloudWatch detects primary region outage
- SNS notifica on-call engineer
- Alertmanager dispara CRITICAL

**Fase 2: Decisão (Manual)**
- On-call verifica scope da falha
- Contata stakeholders (ONGs)
- Aprova failover

**Fase 3: Execução (10-15 min)**
```bash
# 1. Promover RDS read-replica
aws rds promote-read-replica \
  --db-instance-identifier solidarytech-donation-db-dr

# 2. Scale EKS nodes
aws eks update-nodegroup-config \
  --cluster-name solidarytech-cluster-dr \
  --nodegroup-name solidarytech-nodegroup-dr \
  --scaling-config desiredSize=3

# 3. Update Route53 DNS
aws route53 change-resource-record-sets \
  --hosted-zone-id Z... \
  --change-batch file://dns-failover.json

# 4. Sync ArgoCD
argocd app sync solidarytech-shared --force

# 5. Validate
curl https://solidarytech-dr.example.com/health
```

**Fase 4: Validação (2-5 min)**
- Health checks pass
- Smoke tests executados
- Stakeholders confirmam acesso

**Fase 5: Retorno (Quando primary recupera)**
```bash
# Reverter dados para primary
# Reconstruir read-replica
# Update DNS de volta
```

---

# 🔧 SEÇÃO ITSM/AOPS - Incident Management Lifecycle

## Ciclo de Vida de Incidentes

```
┌─────────────────────────────────────────────────────────────────┐
│                    INCIDENT LIFECYCLE                           │
└─────────────────────────────────────────────────────────────────┘

DETECÇÃO (Detection)
    │
    └─→ [2 min] Prometheus alert
        └─→ [1 min] Alertmanager
            └─→ [1 min] Discord + PagerDuty notificação
                │
                ▼
TRIAGEM (Triage)
    │
    ├─→ [5 min] On-call recebe alerta
    ├─→ [2 min] Abre PagerDuty incident
    ├─→ [3 min] Investiga logs/métricas
    └─→ Classifica severity (P1/P2/P3)
                │
                ▼
RESPOSTA AUTOMÁTICA (Auto-Remediation)
    │
    ├─→ [1 min] PodCrashLooping detectado
    ├─→ [1 min] Webhook-receiver dispara GitHub Actions
    ├─→ [2 min] self-healing.yaml executa
    └─→ [3 min] kubectl rollout restart deployment
                │
                ├─ SIM (pod recupera) ──→ [Resolução Automática]
                └─ NÃO (falha) ──→ Escala para on-call
                │
                ▼
INVESTIGAÇÃO (Investigation)
    │
    ├─→ [5-10 min] Verificar logs em Loki
    ├─→ [5 min] Analisar traces em New Relic
    ├─→ [3 min] Rodar queries em Prometheus
    └─→ [2 min] Revisar git history recente
                │
                ▼
MITIGAÇÃO (Mitigation)
    │
    ├─→ [5-15 min] Aplicar hotfix ou rollback
    ├─→ [2 min] Redeploy via ArgoCD
    ├─→ [3 min] Validar saúde
    └─→ Comunicar progresso ao PagerDuty
                │
                ▼
RESOLUÇÃO (Resolution)
    │
    ├─→ [1 min] Marcar como resolved em PagerDuty
    ├─→ Atualizar status no Slack/Discord
    └─→ Agendar Post-Incident Review
                │
                ▼
POST-MORTEM (Post-Incident Review)
    │
    ├─→ [24h] Reunião do time
    ├─→ Timeline da falha + root cause
    ├─→ Items de ação (correções)
    ├─→ Atualizar runbooks
    └─→ Melhorar alertas/SLOs se necessário

```

## Matrizes de Severidade

### Definição de Severidade

| Severidade | Impacto | Usuários Afetados | RTO | Escalation |
|-----------|---------|-------------------|-----|-----------|
| **P1** | Total | Todos (0% availability) | 30 min | VP + On-Call |
| **P2** | Alta | Parcial (Donation service down) | 1-2 horas | On-Call + Team |
| **P3** | Média | Funcionalidade degradada | 4 horas | On-Call |
| **P4** | Baixa | Cosmético/UI | Próximo sprint | Ticket |

### Exemplo de Incidente Real

```
[Timestamp: 2026-07-28 09:15]
ALERT: DonationSLOFastBurn (P1 - CRITICAL)
├─ Prometheus detecta: 15% 5xx errors (limiar: 14.4%)
├─ Timestamp: 09:15 UTC
├─ Duration: 5 minutos (até detecção)
├─ Root cause: Memory leak em donation-service
├─ Auto-remediation: 
│  └─ [09:16] Webhook-receiver → GitHub Actions
│  └─ [09:17] self-healing.yaml executa
│  └─ [09:19] Pod reinicia
│  └─ [09:20] Error rate cai para 0.1%
├─ On-call verifica logs → Valida recuperação
├─ Abre Issue no GitHub para memory leak fix
└─ Resolved: 09:25 (total MTTR: 10 minutos)
```

## Runbooks (Exemplo: High Error Rate)

```markdown
# Runbook: HighErrorRate5xx

## Sintomas
- Alertmanager: HighErrorRate5xx CRITICAL
- Error rate > 5% por 2+ minutos
- Discord notificação enviada

## Triage (1-2 min)
1. Check Grafana dashboard
2. Identify which service is failing
3. Get recent deployment info: `kubectl rollout history deployment/<svc> -n solidarytech`

## Investigation (3-5 min)
1. Check pod logs: `kubectl logs -n solidarytech deployment/<svc> -f`
2. Check events: `kubectl describe pod -n solidarytech -l app=<svc>`
3. Query New Relic: Trace → Errors

## Mitigation (5-15 min)
**Option A: Auto-remediation (if pod restart helps)**
- Already triggered by webhook-receiver
- Wait 2 min for pod to stabilize

**Option B: Manual rollback**
```bash
kubectl rollout undo deployment/<svc> -n solidarytech
kubectl rollout status deployment/<svc> -n solidarytech
```

**Option C: Hotfix deploy**
```bash
git checkout <commit-before-error>
make build push deploy
```

## Resolution
- Mark PagerDuty incident as resolved
- Post-mortem scheduled for next day
- Issue opened for root cause fix
```

---

# 🏆 Evidências de Implementação

## ✅ Arquivos de Implementação Completa

### SRE
- ✅ `docs/SRE-SLO.md` — Definição formal de SLI/SLO/SLA
- ✅ `gitops/monitoring/alerting/prometheus-rules.yaml` — Alert rules (burn rate)
- ✅ `gitops/monitoring/grafana/dashboards/` — SRE dashboards

### FinOps
- ✅ `docs/FINOPS-REPORT.md` — Análise de custos e forecast
- ✅ `terraform/*/main.tf` — Tags em todos os recursos
- ✅ AWS Cost Explorer — Tags aplicadas na conta

### Disaster Recovery
- ✅ `docs/DR-STRATEGY.md` — Estratégia completa
- ✅ `terraform/environments/dr/` — Infraestrutura do DR
- ✅ `.github/workflows/setup-dr-workflow.yaml` — Provisionamento automático
- ✅ `.github/workflows/dr-drill.yaml` — Testes mensais

### ITSM/AIOps
- ✅ `docs/ITSM-LIFECYCLE.md` — Ciclo de vida de incidentes
- ✅ `gitops/monitoring/alerting/alertmanager-config.yaml` — Alert routing
- ✅ `.github/workflows/self-healing.yaml` — Auto-remediation
- ✅ `gitops/monitoring/alerting/webhook-receiver.yaml` — Webhook bridge

---

# 📚 Referências Técnicas

## Repositório
```
https://github.com/dsrdantas/TC5-ST
├── terraform/          # IaC (5 módulos, 2 ambientes)
├── microservices/      # 3 serviços (Python, Go, Python)
├── gitops/             # ArgoCD + Monitoring stack
├── .github/workflows/  # CI/CD completo
└── docs/               # Documentação técnica completa
```

## Stack Tecnológico

- **IaC**: Terraform 1.5.7
- **Container**: Docker (multi-stage builds)
- **Orquestração**: Kubernetes 1.31 (EKS)
- **GitOps**: ArgoCD
- **CI/CD**: GitHub Actions
- **Observabilidade**: Prometheus, Grafana, Loki, OTEL
- **APM**: New Relic
- **Banco**: PostgreSQL, DynamoDB, SQS
- **Backup**: Velero
- **Logging**: CloudWatch, Loki
- **Alertas**: Alertmanager, PagerDuty, Discord

---

## 📝 Conclusão

SolidaryTech implementa **engenharia moderna de plataforma** com foco em:

✅ **Confiabilidade**: SRE + SLOs + Auto-healing  
✅ **Custos**: FinOps com tags estruturadas  
✅ **Resiliência**: DR em 15-30 minutos  
✅ **Operações**: ITSM + AIOps automático  

**Pronto para produção** com observabilidade completa e recuperação automática de falhas.

---

**Data de Entrega**: 28 de Julho de 2026  
**Status**: ✅ COMPLETO

