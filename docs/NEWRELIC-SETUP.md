# 📊 New Relic APM Setup — Distributed Tracing & APM

Guia para configurar e verificar integração de New Relic com OpenTelemetry Collector.

---

## ✅ Mudanças Aplicadas

Na versão anterior, o New Relic exporter estava **definido mas não era usado** nas pipelines de OTEL Collector.

**Corrigido em:** `gitops/monitoring/otel-collector/values.yaml`

```yaml
# ANTES (não funcionava):
pipelines:
  traces:
    exporters: [debug]
  metrics:
    exporters: [prometheusremotewrite, debug]

# AGORA (funciona):
pipelines:
  traces:
    exporters: [otlphttp/newrelic, debug]
  metrics:
    exporters: [otlphttp/newrelic, prometheusremotewrite, debug]
```

---

## 🔐 Passo 1: Verificar Secret do New Relic

```bash
# Verificar se o secret existe
kubectl get secret -n monitoring newrelic-license-key

# Se NÃO existir, criar:
kubectl create secret generic newrelic-license-key \
  --namespace monitoring \
  --from-literal=license-key="YOUR_NEW_RELIC_LICENSE_KEY"

# Verificar conteúdo (sem revelar a chave)
kubectl get secret -n monitoring newrelic-license-key -o jsonpath='{.data.license-key}' | base64 -d | wc -c
# Deve retornar 64 (64 caracteres hexadecimais = chave válida)
```

---

## 🚀 Passo 2: Redeployar OTEL Collector

Após atualizar o values.yaml, o OTEL Collector precisa ser redeployado:

### Opção A: Via GitHub Actions (Recomendado)

```bash
# 1. Commit das mudanças
git add gitops/monitoring/otel-collector/values.yaml
git commit -m "fix: enable New Relic exporter in OTEL pipelines"
git push origin main

# 2. Rodar workflow
gh workflow run setup-full-workflow.yaml -f auto_approve=true

# 3. ArgoCD sincroniza automaticamente (~2 min)
```

### Opção B: Manual

```bash
# Redeployar via Helm
helm upgrade otel-collector open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --values gitops/monitoring/otel-collector/values.yaml

# Verificar rollout
kubectl rollout status deployment/otel-collector-opentelemetry-collector -n monitoring
```

---

## 🔍 Passo 3: Verificar Conectividade

### 1. Verificar se pod está rodando

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=opentelemetry-collector
# Status: Running
```

### 2. Checar logs para erros de conexão

```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector -f

# Procurar por:
# - "newrelic" (confirmação de envio)
# - "error" ou "failed" (problemas)
# - "unauthorized" (chave inválida)

# Exemplo de sucesso:
# "otlphttp/newrelic exporting traces"
# "otlphttp/newrelic exporting metrics"
```

### 3. Verificar saúde do collector

```bash
kubectl port-forward -n monitoring svc/otel-collector-opentelemetry-collector 13133:13133
curl http://localhost:13133
# Esperado: 200 OK
```

### 4. Enviar trace de teste

```bash
# Forçar requisição em um serviço
kubectl exec -n solidarytech deployment/donation-service -- \
  curl -X POST http://localhost:8080/donations \
  -H "Content-Type: application/json" \
  -d '{"amount": 50, "donor_id": "test"}'

# Aguardar 10-30 segundos (batch timeout)
# New Relic deve receber o trace
```

---

## 📱 Passo 4: Verificar em New Relic

### 1. Acessar New Relic

```
https://one.newrelic.com
```

### 2. Navegar até APM

```
Menu → APM & Services
```

### 3. Procurar pelos serviços

Deve aparecer:
- `donation-service`
- `ngo-service`
- `volunteer-service`

### 4. Ver Distributed Traces

```
Acesse um serviço
→ Distributed Tracing
→ Deve ver spans das requisições
```

---

## ✅ Verificação de Funcionamento

| Item | Check |
|------|-------|
| Secret criado | `kubectl get secret newrelic-license-key -n monitoring` |
| Chave válida | 64 caracteres hexadecimais |
| Exporter configurado | `otlphttp/newrelic` em traces + metrics pipelines |
| Pod rodando | `kubectl get pods -n monitoring` |
| Logs sem erro | `kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector` |
| New Relic recebendo | Dashboard APM mostra serviços |

---

## 🧪 Teste Completo (Passo-a-Passo)

```bash
# 1. Verificar secret
kubectl get secret -n monitoring newrelic-license-key

# 2. Verificar OTEL Collector rodando
kubectl get pods -n monitoring | grep otel

# 3. Verificar logs (sem erros)
kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector --tail=50

# 4. Fazer requisição de teste
kubectl exec -n solidarytech deployment/donation-service -- \
  curl -X GET http://localhost:8080/donations/health

# 5. Aguardar 30 segundos (batch processing)

# 6. Acessar New Relic
# https://one.newrelic.com → APM & Services → donation-service

# 7. Deve aparecer:
#    - Service name: donation-service
#    - Throughput, latency, error rate
#    - Distributed traces
```

---

## 🚨 Troubleshooting

### ❌ "No data from New Relic"

**Causa 1: Secret não criado**
```bash
kubectl create secret generic newrelic-license-key \
  --namespace monitoring \
  --from-literal=license-key="YOUR_LICENSE_KEY"
```

**Causa 2: Chave inválida**
- Verifique em: https://one.newrelic.com/admin-portal/api-keys/ingest-browser-keys
- Copie a "License key" (não "API key" ou "User API key")
- Formato correto: 64 caracteres hexadecimais (type: `INGEST - LICENSE`)

**Causa 3: Exporter desativado**
```bash
# Verificar values.yaml
kubectl get deployment otel-collector-opentelemetry-collector -n monitoring -o yaml | grep -A3 "otlphttp/newrelic"
# Deve aparecer nas pipelines de traces e metrics
```

### ❌ "Connection refused"

```bash
# Verificar conectividade do pod
kubectl exec -n monitoring <otel-collector-pod> -- \
  curl -sS https://otlp.nr-data.net -I

# Deve retornar HTTP 200
```

### ❌ "401 Unauthorized"

```bash
# Chave inválida
# Gerar nova chave em: https://one.newrelic.com/admin-portal/api-keys/ingest-browser-keys
# Atualizar secret
kubectl delete secret newrelic-license-key -n monitoring
kubectl create secret generic newrelic-license-key \
  --namespace monitoring \
  --from-literal=license-key="NOVA_CHAVE"

# Reiniciar OTEL Collector
kubectl rollout restart deployment/otel-collector-opentelemetry-collector -n monitoring
```

### ❌ "Traces não aparecem em New Relic"

```bash
# Verificar se microsserviços estão instrumentados
# Procurar por "traceparent" nos logs da aplicação

# Verificar se OTEL está recebendo spans
kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector | grep -i "span\|trace"

# Se vir "NewRelic exporting" = está enviando
# Se ver "error" = problema na conexão
```

---

## 📚 Referências

- [New Relic OTLP Endpoint](https://docs.newrelic.com/docs/opentelemetry/setup-opentelemetry/)
- [License Keys](https://one.newrelic.com/admin-portal/api-keys/ingest-browser-keys)
- [OTEL Collector Config](https://opentelemetry.io/docs/collector/configuration/)

---

## 🔗 Relacionados

- [gitops/monitoring/otel-collector/values.yaml](../gitops/monitoring/otel-collector/values.yaml)
- [README.md](../README.md) — Setup geral
- [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) — Guia de deploy
