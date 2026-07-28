# 📊 Evidências Técnicas — SolidaryTech FASE 5

Documentação completa das implementações técnicas exigidas pelo Tech Challenge FASE 5.

## 📄 Arquivos Gerados

### PDF Principal
- **EVIDENCIAS-TECNICAS.pdf** (7 páginas)
  - Documento profissional compilado com todas as evidências visuais
  - Inclui: SRE, FinOps, DR, ITSM/AIOps
  - Gera automáticamente com ReportLab

### HTML Alternativo
- **EVIDENCIAS-TECNICAS.html** (27 KB)
  - Versão web interativa
  - Pode ser convertida para PDF via navegador (Cmd+P)
  - Contém toda a documentação formatada

## 📌 Seções do PDF

### 1. **CAPA** — Informações Principais
- Links do repositório: https://github.com/dsrdantas/TC5-ST
- Link do vídeo: https://github.com/dsrdantas/TC5-ST/blob/main/docs/tc5-st.mp4
- Informações da equipe: Daniel e Thiago

### 2. **SRE — Service Level Objectives**
- **SLI (Service Level Indicators)**
  - Availability: ≥ 99.9%
  - Latência P95: < 300ms
  - Taxa de Erro 5xx: < 0.1%

- **SLO (Service Level Objectives)**
  - Availability: 99.9% (43 min error budget/mês)
  - Latência P95: < 300ms (5% das requisições podem exceder)

- **SLA (Service Level Agreements)**
  - Compromisso com ONGs: 99.5% disponibilidade
  - Margem de segurança: 0.4%

- **Burn Rate Alerts**
  - SLOFastBurn: 14.4x o orçamento em 2+ horas
  - SLOSlowBurn: 1x o orçamento em 6 horas

### 3. **FinOps — Financial Operations**
- **Política de Tags (TODO recurso AWS)**
  - Project: SolidaryTech
  - Environment: Production / DR
  - CostCenter: NGO-Core
  - ManagedBy: Terraform

- **Cobertura de Recursos Taggueados**
  - EC2, RDS, DynamoDB, SQS, ECR, VPC ✅

- **Forecast de Custos Mensais**
  - EKS: $73.00 (33%)
  - EC2 nodes: $89.86 (41%)
  - RDS: $24.48 (11%)
  - NAT: $32.40 (15%)
  - Outros: $12.39 (5%)
  - **TOTAL: ~$250-300/mês**

- **Anualizado: $3,000-3,600**

- **Recomendações de Otimização**
  - Reserved Instances: 40-60% economizar
  - Auto-scaling: scale down em off-peak
  - DynamoDB On-Demand: picos ocasionais
  - Economia potencial: -15% (~$450/ano)

### 4. **Segurança e Disaster Recovery**
- **RPO (Recovery Point Objective)**
  - RDS: 5 minutos
  - DynamoDB: < 1 segundo
  - EBS: 15 minutos
  - Application Code: < 1 segundo

- **RTO (Recovery Time Objective)**
  - Detectar failover: 2 min
  - Promover RDS: 3 min
  - Scale EKS: 5 min
  - Update DNS: 1 min
  - Verificar saúde: 2 min
  - **TOTAL: ~15 minutos**

- **Padrão DR: Warm Standby**
  - Primary (us-east-1): 2-3 nodes, RDS primary, $235/mês
  - DR (us-west-2): 1 node skeleton, RDS replica, $65/mês

### 5. **ITSM/AIOps — Incident Management Lifecycle**
- **Ciclo de Vida**
  1. [1] DETECÇÃO (0-2 min)
  2. [2] TRIAGEM (2-5 min)
  3. [3] MITIGAÇÃO (5-15 min)
  4. [4] COMUNICAÇÃO (contínuo)
  5. [5] RESOLUÇÃO (N/A)
  6. [6] POST-MORTEM (24h)

- **Fontes de Detecção (Multi-Camada)**
  - Prometheus PrometheusRules (Métricas)
  - New Relic Applied Intelligence (AIOps)
  - AWS Health Dashboard (Infra)
  - Velero Backup (DR)

- **Roteamento de Alertas**
  - Critical → PagerDuty + Discord + GitHub Actions
  - Warning → Discord apenas
  - SLO burn → PagerDuty imediato + Discord + SRE

- **Matriz de Severidade**
  - P1 (Total): 30 min RTO
  - P2 (Alta): 1-2 horas RTO
  - P3 (Média): 4 horas RTO
  - P4 (Baixa): Próximo sprint

- **Auto-Remediation**
  - Webhook-receiver → GitHub Actions → self-healing.yaml
  - Tempo total: ~3 minutos
  - Reduz MTTR de 10min → 3min (80%+)

## 🔧 Como Gerar o PDF

### Opção 1: ReportLab (Recomendado)
```bash
cd /Users/danieldantas/Documents/FIAP/TC5-ST
python3 generate-pdf-reportlab.py
```

### Opção 2: HTML → PDF via Navegador
```bash
# Abra o arquivo HTML no navegador
open docs/EVIDENCIAS-TECNICAS.html

# Pressione Cmd+P (Mac) ou Ctrl+P (Windows/Linux)
# Selecione "Salvar como PDF"
```

### Opção 3: Atualizar o PDF
```bash
# Se fizer alterações no arquivo .md, regenere:
python3 generate-pdf-reportlab.py
```

## 📚 Documentação Completa

Todos estes arquivos suportam o PDF:

| Arquivo | Conteúdo |
|---------|----------|
| **docs/SRE-SLO.md** | Definição formal de SLI, SLO e SLA |
| **docs/FINOPS-REPORT.md** | Análise de custos e forecast |
| **docs/DR-STRATEGY.md** | Estratégia de Disaster Recovery |
| **docs/PCN.md** | Performance Characteristics & NFRs |
| **docs/ITSM-LIFECYCLE.md** | Ciclo de vida de incidentes |
| **docs/DEPLOYMENT-GUIDE.md** | Guia de deployment passo-a-passo |
| **docs/RELATORIO-ENTREGA-FINAL.md** | Relatório técnico completo |

## 🎯 Comprovação de Implementação

✅ **SRE**: SLI, SLO e SLA definidos formalmente no PDF  
✅ **FinOps**: Tags aplicadas em TODO recurso AWS + Forecast de custos  
✅ **DR**: RPO, RTO e estratégia Warm Standby documentados  
✅ **ITSM/AIOps**: Ciclo de vida completo de incidentes + Auto-remediation  

## 🔗 Links Principais

- **Repositório**: https://github.com/dsrdantas/TC5-ST
- **Vídeo de Apresentação**: https://github.com/dsrdantas/TC5-ST/blob/main/docs/tc5-st.mp4
- **Documentação**: https://github.com/dsrdantas/TC5-ST/tree/main/docs

---

**Data de Geração**: 28 de Julho de 2026  
**Status**: ✅ COMPLETO
