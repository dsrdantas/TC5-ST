# 🚨 PagerDuty Setup — Alert Routing & Incidents

Guia para verificar e configurar PagerDuty para receber alertas críticos do Alertmanager.

---

## 🔍 Verificação de Configuração Atual

### 1. **Routing Key**

Arquivo: `gitops/monitoring/alerting/alertmanager-config.yaml` (linha 90)

```yaml
pagerduty_configs:
  - routing_key: 'f346325d728f450cc01b4f6d3345623b'
```

**Status:** ⚠️ Precisa verificar se é válida

---

## ✅ Checklist de Verificação

### Passo 1: Validar Routing Key no PagerDuty

```bash
# 1. Acesse PagerDuty
# https://subdomain.pagerduty.com/services

# 2. Selecione o serviço onde os alertas devem ir
# (ex: "SolidaryTech On-Call" ou "Platform Engineering")

# 3. Vá para: Integrations → Events API v2
# Ou: Settings → Integrations

# 4. Copie a "Integration Key" (não o "Service ID")
# Formato: dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx (32+ caracteres)
```

### Passo 2: Atualizar Routing Key (se diferente)

```bash
# Se a chave for diferente, atualizar o secret:
kubectl edit secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager

# Procure por: routing_key: 'f346325d728f450cc01b4f6d3345623b'
# Substitua pela chave correta

# SAVE (escreva :wq no vim)
```

---

## 📋 Roteamento de Alertas para PagerDuty

### Alertas que DEVEM disparar PagerDuty

| Alert | Condição | Severity | Dispara? |
|-------|----------|----------|----------|
| **DonationSLOFastBurn** | Taxa erro > 14.4% / 2min | `critical` + `slo: availability` | ✅ SIM |
| **HighErrorRate5xx** | >5% 5xx / 2min | `critical` | ✅ SIM |
| **PodCrashLooping** | >3 restarts / 15min | `critical` | ✅ SIM |
| DonationLatencyP95High | P95 > 300ms / 5min | `warning` | ❌ NÃO |
| PodNotReady | Pod ≠ ready / 10min | `warning` | ❌ NÃO |
| HighCPU | CPU > 85% / 10min | `warning` | ❌ NÃO |
| HighMemory | Memory > 85% / 10min | `warning` | ❌ NÃO |

---

## 🧪 Teste de Disparo Manual

### Teste 1: Verificar conectividade

```bash
# Acessar pod do Alertmanager
kubectl exec -n monitoring -it $(kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager -o jsonpath='{.items[0].metadata.name}') -- /bin/sh

# Testar curl para PagerDuty
curl -X POST https://events.pagerduty.com/v2/enqueue \
  -H "Content-Type: application/json" \
  -d '{
    "routing_key": "f346325d728f450cc01b4f6d3345623b",
    "event_action": "trigger",
    "dedup_key": "test-alert-solid",
    "payload": {
      "summary": "Test alert from SolidaryTech",
      "severity": "critical",
      "source": "Prometheus Alertmanager"
    }
  }'

# Esperado: HTTP 202 Accepted + ID do event
exit
```

### Teste 2: Forçar alerta crítico

```bash
# Forçar PodCrashLooping (restart múltiplo)
kubectl set env deployment/donation-service \
  -n solidarytech \
  CRASH=true

# Aguardar 2 minutos (threshold do alerta)

# Verificar Alertmanager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
# http://localhost:9093 → Alerts

# Verificar PagerDuty (deve ver incidente)
# https://subdomain.pagerduty.com/incidents
```

---

## 🔧 Configuração Detalhada

### Fluxo Completo de Roteamento

```
┌─────────────────────────────────────┐
│ Prometheus Alert                    │
│ severity: critical                  │
│ alertname: PodCrashLooping         │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│ Alertmanager Route Evaluation       │
│ match severity: critical            │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│ Receiver: solidarytech-critical     │
│ • pagerduty_configs (AQUI!)         │
│ • slack_configs                     │
│ • webhook_configs                   │
└────────────────┬────────────────────┘
                 │
        ┌────────┴────────┬────────────┐
        │                 │            │
        ▼                 ▼            ▼
   ┌─────────┐      ┌─────────┐  ┌──────────┐
   │PagerDuty│      │ Discord │  │   GitHub │
   │(Incident)      │ (#alerts)  │ (webhook)│
   └─────────┘      └─────────┘  └──────────┘
```

### Configuração do PagerDuty

```yaml
# Alertmanager config (linha 89-96)
pagerduty_configs:
  - routing_key: 'YOUR_INTEGRATION_KEY'  # ← Integration Key (não Service ID!)
    severity: critical                    # ← Severity do event
    description: '[CRITICAL] {{ .CommonLabels.alertname }} — {{ .CommonLabels.service }}'
    details:
      description: '{{ .CommonAnnotations.description }}'
      service: '{{ .CommonLabels.service }}'
      cluster: 'solidarytech-cluster'
```

---

## 🛠️ Troubleshooting

### ❌ "PagerDuty não recebe alertas"

**Verificação 1: Routing Key**

```bash
# Confirmar chave no PagerDuty
# https://subdomain.pagerduty.com/services/<SERVICE_ID>/integrations

# Copiar "Integration Key" (formato: dxxxxxxxx...)
# Comparar com o arquivo

# Se diferente, atualizar:
kubectl patch secret alertmanager-prometheus-kube-prometheus-alertmanager \
  -n monitoring \
  -p '{"stringData":{"alertmanager.yaml":"...routing_key: '\''NEW_KEY'\''..."}}'
```

**Verificação 2: Alertmanager consegue conectar?**

```bash
# Verificar logs
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager -f

# Procurar por:
# - "pagerduty" (confirmação)
# - "error" ou "failed" (problema)
# - "unauthorized" (chave inválida)
```

**Verificação 3: Alerta tem label `severity: critical`?**

```bash
# Verificar regras de alerta
kubectl get prometheusrule -n monitoring

# Ver regras
kubectl describe prometheusrule solidarytech-alerts -n monitoring

# Procurar por: labels: severity: critical
```

**Verificação 4: Serviço PagerDuty está ativo?**

```bash
# Acessar PagerDuty
# https://subdomain.pagerduty.com/services

# Confirmar que o serviço:
# ✅ Está "Active" (não "Disabled")
# ✅ Tem escalation policy configurada
# ✅ Tem integration key válida
```

### ❌ "PagerDuty recebe mas não cria incident"

**Causa 1: Dedup key duplicada**
- PagerDuty deduplicates eventos com mesmo `dedup_key`
- Se alert for recorrente, pode não criar novo incident

**Causa 2: Service sem escalation policy**
- Serviço PagerDuty precisa ter uma escalation policy
- Sem isso, evento é "ignorado"

**Solução:**
```bash
# No PagerDuty:
# 1. Vá para o serviço
# 2. Settings → Escalation Policy
# 3. Selecione uma (ou crie nova)
# 4. Save
```

### ❌ "Routing key 'f346325d728f450cc01b4f6d3345623b' parece fake"

**Verdade:** Essa chave pode ser de teste.

**Solução:**
1. Gerar nova chave real no PagerDuty
2. Usar formato correto: `dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` (starts with 'd')

```bash
# Obter nova chave
# https://subdomain.pagerduty.com/services/<SERVICE_ID>/integrations
# → Events API v2
# → Copy "Integration Key"

# Atualizar secret
kubectl delete secret alertmanager-prometheus-kube-prometheus-alertmanager -n monitoring
kubectl apply -f gitops/monitoring/alerting/alertmanager-config.yaml
```

---

## ✅ Validação Final

```bash
# 1. Secret atualizado
kubectl get secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager -o yaml | grep routing_key

# 2. Alertmanager rodando
kubectl get pods -n monitoring | grep alertmanager

# 3. PagerDuty conectável
kubectl exec -n monitoring <alertmanager-pod> -- nc -zv events.pagerduty.com 443

# 4. Próximo alert crítico
#    → Deve criar incident no PagerDuty em <1 minuto
```

---

## 📚 Referências

- [PagerDuty Events API v2](https://developer.pagerduty.com/docs/events-api-v2/overview/)
- [Integration Keys](https://support.pagerduty.com/docs/services-and-integrations)
- [Alertmanager PagerDuty](https://prometheus.io/docs/alerting/latest/configuration/#pagerduty_config)

---

## 🔗 Relacionados

- [alertmanager-config.yaml](../gitops/monitoring/alerting/alertmanager-config.yaml)
- [prometheus-rules.yaml](../gitops/monitoring/alerting/prometheus-rules.yaml)
- [SRE-SLO.md](SRE-SLO.md) — Definição de alertas
