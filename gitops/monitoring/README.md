# 📊 Monitoring Stack — SolidaryTech

Observabilidade completa com Prometheus, Grafana, Loki, OpenTelemetry e Auto-Healing.

---

## 🏗️ Arquitetura

```
Prometheus (metrics scraping)
    ↓
Grafana (visualização)
Alertmanager (alert routing)
    ↓
├── Discord webhooks (#alerts)
├── PagerDuty (critical only)
└── GitHub Actions webhook → Self-Healing
    ↓
Loki (log aggregation)
Promtail (log shipping)
    ↓
OpenTelemetry Collector
    ├── Metrics → Prometheus
    ├── Traces → New Relic (optional)
    └── Logs → Loki
```

---

## 📁 Estrutura

```
gitops/monitoring/
├── README.md (você está aqui)
├── namespace.yaml                      # Namespace + RBAC
├── newrelic-secret.yaml               # New Relic license key
│
├── alerting/
│   ├── alertmanager-config.yaml       # Alertmanager Secret (Discord/PagerDuty)
│   ├── prometheus-rules.yaml          # Alert rules (SLO, CPU, Memory, etc)
│   └── webhook-receiver.yaml          # Self-healing webhook bridge
│
├── prometheus/
│   └── values.yaml                    # kube-prometheus-stack Helm chart
│
├── grafana/
│   ├── values.yaml                    # Grafana Helm chart
│   └── dashboards/
│       └── solidarytech-overview.json # Custom dashboard
│
├── loki/
│   └── values.yaml                    # Loki Helm chart
│
├── promtail/
│   └── values.yaml                    # Promtail Helm chart
│
└── otel-collector/
    └── values.yaml                    # OpenTelemetry Collector Helm chart
```

---

## 🚀 Deployment

### Via GitHub Actions (Recomendado)

O monitoring stack é instalado automaticamente pelo workflow `setup-full-workflow.yaml`:

```bash
# Etapa 5 do workflow instala tudo
1. Prometheus + Grafana + Alertmanager
2. Loki + Promtail
3. OpenTelemetry Collector
4. Webhook Receiver (self-healing)
```

### Manual

```bash
# Executado pelo script install-monitoring.sh
cd terraform/environments/primary
terraform apply  # Cria EKS

# Depois:
cd ../../..
scripts/install-monitoring.sh
```

---

## 📊 Componentes

### 1. **Prometheus** (kube-prometheus-stack)

Coleta métricas de:
- Kubernetes (kubelet, kube-apiserver, kube-controller-manager)
- Nodes (node-exporter)
- Pods (via Prometheus Operator)
- ApplicationsMetrics (OpenTelemetry)

**Acesso:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# http://localhost:9090
```

### 2. **Grafana**

Dashboard de visualização com:
- SolidaryTech Overview (custom)
- Node Exporter Full
- Kubernetes cluster monitoring
- Loki logs integration

**Credentials:**
```bash
# User: admin
# Password: (aleatória, gerada durante install)
kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
```

**Acesso:**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:3000
# http://localhost:3000
```

### 3. **Alertmanager**

Roteia alertas para:
- **Discord** (#alerts channel) — Todos os alertas
- **PagerDuty** — Críticos apenas
- **GitHub Actions** (webhook) — Self-healing automático

**Configuração:**
```bash
kubectl edit secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager
# Edit alertmanager.yaml dentro do secret
```

**Acesso:**
```bash
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
# http://localhost:9093 → Silences, Status, Alerts
```

### 4. **Loki** (Log Aggregation)

Coleta logs de todos os containers via Promtail.

**Queries via Grafana:**
```
{namespace="solidarytech"}
{pod="donation-service-xxx"}
{service_name="donation-service"} | json
```

### 5. **OpenTelemetry Collector**

Hub central para sinais observáveis:
- **Metrics** → Prometheus
- **Traces** → New Relic (optional)
- **Logs** → Loki

**Endpoints:**
- gRPC: `otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317`
- HTTP: `otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4318`

### 6. **Webhook Receiver** (Self-Healing)

Bridge entre Alertmanager e GitHub Actions.

**Dispara:**
- PodCrashLooping → `kubectl rollout restart`
- HighErrorRate5xx → `kubectl rollout restart`
- DonationSLOFastBurn → `kubectl rollout restart`

Ver [SELF-HEALING-SETUP.md](../../docs/SELF-HEALING-SETUP.md) para setup.

---

## 🎯 Alertas Configurados

### 🔴 **Critical** (PagerDuty + Discord + Self-Healing)

| Alert | Condição | Action |
|-------|----------|--------|
| **DonationSLOFastBurn** | Taxa erro > 14.4% / 2min | Auto-restart |
| **HighErrorRate5xx** | >5% 5xx / 2min | Auto-restart |
| **PodCrashLooping** | >3 restarts / 15min | Auto-restart |

### 🟡 **Warning** (Discord apenas)

| Alert | Condição |
|-------|----------|
| **DonationLatencyP95High** | P95 > 300ms / 5min |
| **PodNotReady** | Pod ≠ ready / 10min |
| **HighCPU** | CPU > 85% / 10min |
| **HighMemory** | Memory > 85% / 10min |

---

## 🛠️ Setup & Configuration

### 1. **Discord Webhooks**

Editar `alerting/alertmanager-config.yaml`:

```yaml
slack_configs:
  - api_url: 'https://discord.com/api/webhooks/<WEBHOOK_ID>/<WEBHOOK_TOKEN>/slack'
    channel: '#alerts'
```

### 2. **PagerDuty**

Editar `alerting/alertmanager-config.yaml`:

```yaml
pagerduty_configs:
  - routing_key: '<YOUR_PAGERDUTY_KEY>'
    severity: critical
```

### 3. **New Relic APM** (Optional)

```bash
# Criar secret
kubectl create secret generic newrelic-license-key \
  --namespace monitoring \
  --from-literal=license-key="YOUR_LICENSE_KEY"

# Redeploy OTEL Collector
kubectl rollout restart deployment/otel-collector-opentelemetry-collector -n monitoring
```

### 4. **Self-Healing via GitHub** (Optional)

```bash
# 1. Gerar GitHub PAT → https://github.com/settings/tokens/new
# 2. Criar secret
kubectl create secret generic github-webhook-token \
  --namespace monitoring \
  --from-literal=token="ghp_xxx"

# Webhook receiver já está deployado
```

---

## 📈 Monitorando o Monitoring Stack

```bash
# Status de todos os pods
kubectl get pods -n monitoring

# Logs do Prometheus
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Logs do Alertmanager
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager

# Logs do Webhook Receiver
kubectl logs -n monitoring -l app.kubernetes.io/name=webhook-receiver -f
```

---

## 🧪 Testes

### Teste 1: Prometheus rodando

```bash
curl http://localhost:9090/api/v1/query?query=up
```

### Teste 2: Grafana acessível

```bash
curl -u admin:password http://localhost:3000/api/health
```

### Teste 3: Alertmanager recebendo métricas

```bash
curl http://localhost:9093/api/v1/alerts
```

### Teste 4: Webhook receiver respondendo

```bash
curl -X POST http://localhost:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [{
      "labels": {"alertname": "TestAlert", "severity": "critical"},
      "annotations": {"description": "Test"}
    }]
  }'
```

---

## 🚨 Troubleshooting

### Pod não está rodando

```bash
kubectl describe pod -n monitoring <pod-name>
kubectl logs -n monitoring <pod-name>
```

### Prometheus não scrapeando

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Acesse http://localhost:9090/targets
# Procure por targets em "Down"
```

### Alertas não disparando

```bash
# Verificar regras
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# http://localhost:9090/alerts

# Verificar Alertmanager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
# http://localhost:9093
```

### Discord não recebendo alertas

```bash
# Verificar webhook URL
kubectl get secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d | grep discord

# Testar curl
curl -X POST <DISCORD_WEBHOOK_URL> \
  -H "Content-Type: application/json" \
  -d '{"content": "Test message"}'
```

---

## 📚 Referências

- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/grafana/)
- [Loki Docs](https://grafana.com/docs/loki/)
- [OpenTelemetry](https://opentelemetry.io/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

---

## 🔗 Relacionados

- [SELF-HEALING-SETUP.md](../../docs/SELF-HEALING-SETUP.md) — Auto-recovery setup
- [SRE-SLO.md](../../docs/SRE-SLO.md) — SLO & error budgets
- [DEPLOYMENT-GUIDE.md](../../docs/DEPLOYMENT-GUIDE.md) — Guia de deploy
