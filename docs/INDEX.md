# 📚 SolidaryTech — Documentação Completa

Bem-vindo à documentação técnica do projeto SolidaryTech. Abaixo está o mapa completo de recursos.

---

## 🏗️ Arquitetura & Infraestrutura

### [DR-STRATEGY.md](DR-STRATEGY.md)
**Estratégia de Disaster Recovery (Warm Standby cross-region)**
- Padrão de DR escolhido: Warm Standby (us-east-1 → us-west-2)
- RTO: 15-30 min | RPO: 5 min (RDS), <1s (DynamoDB)
- Componentes: RDS read-replica, DynamoDB Global Tables, Velero, ECR replication
- Procedimento de failover passo-a-passo
- Limitações conhecidas (SQS messages, latência cross-region)
- Drills mensais via GitHub Actions

### [PCN.md](PCN.md)
**Performance Characteristics & Non-Functional Requirements**
- Requisitos de latência, throughput, escalabilidade
- Testes de carga e profiling do donation-service
- Limites de throughput (SQS, DynamoDB, RDS)
- Plano de escalabilidade horizontal

---

## 📊 SRE & Observabilidade

### [SRE-SLO.md](SRE-SLO.md)
**SRE Strategy — SLI, SLO, SLA para donation-service**
- SLI #1: Availability (% sem 5xx)
- SLI #2: Latência P95 (<300ms)
- SLO: 99.9% availability, <300ms latency
- SLA com ONGs: 99.5% availability
- Error budget: 43 min/mês para downtime
- Burn rate alerts (fast, slow)
- MTTR reduction via self-healing
- Dashboard Grafana pronto

### [SELF-HEALING-SETUP.md](SELF-HEALING-SETUP.md)
**Auto-Recovery Setup — Automático via GitHub Actions + Webhook**
- GitHub PAT (Personal Access Token) setup
- Webhook receiver (pod no cluster)
- Alertmanager → GitHub Actions API integration
- Auto-healing para PodCrashLooping, HighErrorRate5xx, SLOFastBurn
- Testing & troubleshooting
- Reduz MTTR de 10min → 3min

### [ITSM-LIFECYCLE.md](ITSM-LIFECYCLE.md)
**Incident Management & Operações**
- Runbooks para cenários comuns
- Severity levels e escalation path
- Change management process
- Post-incident reviews (PIRs)
- Communication templates

---

## 💰 FinOps & Custos

### [FINOPS-REPORT.md](FINOPS-REPORT.md)
**Financial Operations & Cost Tracking**
- Tags estruturadas (Project, Environment, CostCenter)
- Custo mensal estimado:
  - Primary: ~$330/mês (EKS + RDS + NAT + storage)
  - DR: ~$100/mês (skeleton + replica)
  - **Total: ~$430/mês**
- Cost optimization recommendations
- Budget alerts + spending forecasts
- FinOps best practices aplicadas

---

## 🎥 Referência Rápida

### [ROTEIRO-COMPLETO.md](ROTEIRO-COMPLETO.md)
**Guia step-by-step do deployment**
- Pré-requisitos
- Variáveis de ambiente
- Como executar workflows
- Troubleshooting comum

### [VIDEO-ROTEIRO.md](VIDEO-ROTEIRO.md)
**Timestamps & resumo dos videos de apresentação**
- Min 0-5: Visão geral da arquitetura
- Min 5-10: Terraform IaC e módulos
- Min 10-15: Workflows CI/CD
- Min 15-20: Observabilidade + SRE
- Min 20-25: DR strategy
- Min 25-30: FinOps + cost tracking

---

## 📋 Relatórios & Evidências

### [RELATORIO-ENTREGA.md](RELATORIO-ENTREGA.md)
**Relatório executivo de entrega**
- Status geral do projeto
- Requisitos atendidos (POSTECH)
- Artefatos entregues
- Screenshots e evidências
- Próximos passos

---

## 🔍 Como Usar Esta Documentação

**Se você quer:**

| Objetivo | Arquivo |
|----------|---------|
| Entender a arquitetura geral | [README.md](../README.md) no raiz |
| Provisionar o ambiente | [ROTEIRO-COMPLETO.md](ROTEIRO-COMPLETO.md) |
| Configurar observabilidade | [SRE-SLO.md](SRE-SLO.md) |
| Preparar para desastre | [DR-STRATEGY.md](DR-STRATEGY.md) |
| Responder a incident | [ITSM-LIFECYCLE.md](ITSM-LIFECYCLE.md) |
| Entender custos | [FINOPS-REPORT.md](FINOPS-REPORT.md) |
| Validar performance | [PCN.md](PCN.md) |
| Acompanhar entrega | [RELATORIO-ENTREGA.md](RELATORIO-ENTREGA.md) |

---

## 📁 Estrutura da Pasta `docs/`

```
docs/
├── INDEX.md                    ← Você está aqui
├── README.md
├── ROTEIRO-COMPLETO.md         # Step-by-step deployment
├── DR-STRATEGY.md              # Disaster Recovery
├── SRE-SLO.md                  # Service Level Objectives
├── ITSM-LIFECYCLE.md           # Incident Management
├── PCN.md                      # Performance & Characteristics
├── FINOPS-REPORT.md            # Cost Tracking
├── VIDEO-ROTEIRO.md            # Video timestamps
├── RELATORIO-ENTREGA.md        # Delivery Report
└── drills/                     # DR Drill reports (auto-generated)
    └── 2026-07-27-drill-report.md
```

---

## 🚀 TL;DR (Too Long; Didn't Read)

**1 minuto:**
```bash
# Deploy via GitHub Actions
git push origin deploy/main
# Outputs: ArgoCD, Grafana, Ingress URLs
```

**5 minutos:**
- ArgoCD syncs gitops/ → Kubernetes
- Observe em Grafana (http://...)
- Check donation-service latency

**1 hora:**
- Setup complete
- SRE dashboard showing metrics
- Alertmanager monitoring
- New Relic APM (if configured)

**Disaster?**
- Primary down? Failover to DR (15-30 min)
- Follow [DR-STRATEGY.md](DR-STRATEGY.md) Phase 1-7

---

## 📞 Suporte

Para dúvidas:
- **Infraestrutura**: Ver [terraform/](../terraform/)
- **Workflows**: Ver [.github/workflows/](../.github/workflows/)
- **Apps**: Ver [microservices/](../microservices/)
- **Observability**: Ver [gitops/monitoring/](../gitops/monitoring/)

Boa sorte! 🚀
