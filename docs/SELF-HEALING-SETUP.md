# 🛠️ Self-Healing Setup — Automático via GitHub Actions

Guia para configurar auto-recovery de pods disparado por alertas do Alertmanager.

---

## 📋 Pré-requisitos

- Cluster Kubernetes rodando com Alertmanager + monitoring stack
- GitHub PAT (Personal Access Token) com permissão `repo`
- Webhook receiver rodando no cluster

---

## 🔑 Passo 1: Criar GitHub PAT

1. Acesse: https://github.com/settings/tokens/new
2. **Descrição:** `SolidaryTech Self-Healing`
3. **Escopo:** Selecione apenas `repo` (Full control of private repositories)
4. **Expiration:** 90 dias (rever antes de expirar)
5. Clique **Generate token**
6. **Copie e guarde** o token (tipo: `ghp_xxxxxxxxxxxxxxxx`)

```bash
# Salvar em lugar seguro (temporariamente)
export GITHUB_PAT="ghp_xxxxxxxxxxxx"
```

---

## 🔐 Passo 2: Criar Secret no Kubernetes

```bash
# Aplicar o secret com o GitHub PAT
kubectl create secret generic github-webhook-token \
  --namespace monitoring \
  --from-literal=token="$GITHUB_PAT" \
  --dry-run=client -o yaml | kubectl apply -f -
```

**Verificar:**
```bash
kubectl get secret -n monitoring github-webhook-token
```

---

## 🚀 Passo 3: Deploy do Webhook Receiver

```bash
# Aplicar o webhook receiver no cluster
kubectl apply -f gitops/monitoring/alerting/webhook-receiver.yaml
```

**Verificar se está rodando:**
```bash
# Checar pod
kubectl get pods -n monitoring -l app.kubernetes.io/name=webhook-receiver

# Checar logs
kubectl logs -n monitoring -l app.kubernetes.io/name=webhook-receiver -f

# Testar conectividade
kubectl port-forward -n monitoring svc/webhook-receiver 8080:8080
curl -X POST http://localhost:8080/webhook -d '{"test": "ok"}'
```

---

## ⚙️ Passo 4: Atualizar Alertmanager

O Alertmanager já está configurado para enviar webhooks para o receiver.

**Verificar:**
```bash
kubectl get secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d | grep -A5 webhook_configs
```

Deve conter:
```yaml
webhook_configs:
  - url: 'http://webhook-receiver.monitoring.svc.cluster.local:8080/webhook'
    send_resolved: false
```

---

## 🧪 Passo 5: Testar Self-Healing

### Teste 1: Webhook receiver respondendo

```bash
# Port-forward para o receiver
kubectl port-forward -n monitoring svc/webhook-receiver 8080:8080 &

# Enviar um alerta teste
curl -sS -X POST http://localhost:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [{
      "labels": {
        "alertname": "PodCrashLooping",
        "severity": "critical",
        "service": "donation-service"
      },
      "annotations": {
        "summary": "Pod crash test",
        "description": "Teste do webhook"
      }
    }]
  }'

# Esperado: HTTP 200 OK
# Log: "[...] Webhook recebido: alert=PodCrashLooping ..."
```

### Teste 2: Disparar workflow manualmente

```bash
# Verificar se o workflow está visível
gh workflow list --repo dsrdantas/TC5-ST | grep self-healing

# Disparar manualmente
gh workflow run self-healing.yaml \
  --repo dsrdantas/TC5-ST \
  -f service=donation-service \
  -f reason="Manual test"

# Acompanhar
gh run list --repo dsrdantas/TC5-ST --workflow=self-healing.yaml
```

### Teste 3: Simular alerta crítico

```bash
# 1. Forçar PodCrashLooping no donation-service
kubectl set env deployment/donation-service -n solidarytech CRASH=true

# 2. Aguardar Prometheus detectar (30s + 2m de alerta)
sleep 150

# 3. Alertmanager dispara webhook para receiver
# 4. Receiver faz curl para GitHub Actions API
# 5. Self-healing workflow dispara automaticamente

# Ver workflow sendo executado
gh run list --repo dsrdantas/TC5-ST --workflow=self-healing.yaml

# Ver logs detalhados
gh run view <run-id> --repo dsrdantas/TC5-ST --log
```

---

## 📊 Fluxo Completo

```
┌─────────────────────────┐
│  Prometheus observa     │
│  PodCrashLooping        │
└────────────┬────────────┘
             │ (após 2m de trigger)
             ▼
┌─────────────────────────┐
│   Alertmanager          │
│   (gera alerta)         │
└────────────┬────────────┘
             │ (imediato)
             ▼
┌─────────────────────────┐
│  Webhook Receiver       │
│  (pod no cluster)       │
└────────────┬────────────┘
             │ (curl com GitHub PAT)
             ▼
┌─────────────────────────┐
│  GitHub Actions API     │
│  (workflow_dispatch)    │
└────────────┬────────────┘
             │ (segundos)
             ▼
┌─────────────────────────┐
│  self-healing.yaml      │
│  (rollout restart)      │
└────────────┬────────────┘
             │ (90 segundos)
             ▼
┌─────────────────────────┐
│  ✅ Pods recuperados    │
│  📢 Discord notificado  │
└─────────────────────────┘
```

**Tempo total:** ~3 min (Prom: 30s + alerta: 2m + workflow: 30s)

---

## 🚨 Troubleshooting

### ❌ Webhook receiver não consegue conectar ao GitHub

```bash
# Verificar se o secret foi criado
kubectl get secret -n monitoring github-webhook-token -o yaml

# Verificar logs do receiver
kubectl logs -n monitoring -l app.kubernetes.io/name=webhook-receiver

# Teste de conectividade (dentro do pod)
kubectl exec -n monitoring <webhook-receiver-pod> -- \
  curl -sS -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user
```

### ❌ Self-healing dispara mas falha

```bash
# Ver logs do workflow
gh run view <run-id> --repo dsrdantas/TC5-ST --log

# Causas comuns:
# - AWS credentials expiradas (4h de Academy)
# - Kubectl não consegue conectar ao cluster
# - Service account sem permissões
```

### ❌ GitHub PAT expirou

```bash
# Gerar novo PAT
# → https://github.com/settings/tokens/new (escopo: repo)

# Atualizar secret
kubectl delete secret -n monitoring github-webhook-token
kubectl create secret generic github-webhook-token \
  --namespace monitoring \
  --from-literal=token="ghp_novo_token"

# Receiver pega automaticamente na próxima requisição
```

---

## 📈 Monitorar Self-Healing

### Via GitHub

```bash
# Últimas 10 execuções
gh run list --repo dsrdantas/TC5-ST --workflow=self-healing.yaml --limit=10

# Status de uma execução específica
gh run view <run-id> --repo dsrdantas/TC5-ST
```

### Via Alertmanager (dentro do cluster)

```bash
# Port-forward Alertmanager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093

# Acessar: http://localhost:9093
# → Silences, Status, Alerts
```

### Via Discord

Canal `#alerts` receberá:
- 🔴 **CRITICAL**: Alerta disparou
- ✅ **Self-Healing CONCLUÍDO**: Pod restart bem-sucedido
- ❌ **Self-Healing FALHOU**: Precisa intervenção humana

---

## 🔄 Reintentar Self-Healing Manualmente

Se o auto-heal falhar:

```bash
# Disparar manualmente com mais detalhes
gh workflow run self-healing.yaml \
  --repo dsrdantas/TC5-ST \
  -f service=donation-service \
  -f reason="Manual retry - auto-heal failed"

# Ver resultado
gh run list --repo dsrdantas/TC5-ST --workflow=self-healing.yaml --limit=5
```

---

## 🎯 Próximos Passos

- [ ] Testar webhook com alerta PodCrashLooping
- [ ] Testar workflow disparando com sucesso
- [ ] Documentar em runbook de incidents
- [ ] Adicionar dashboard Grafana para histórico de self-heals
- [ ] Integrar com Slack/Discord para escalação se falhar 2x seguidas

---

## 📞 Suporte

Se tiver problemas:

1. **Webhook não disparando:** Checar logs do receiver + Alertmanager
2. **Workflow não rodando:** Verificar GitHub PAT válido + permissões
3. **Self-heal falha:** Ver logs no `gh run view` + AWS credentials

Boa sorte! 🚀
