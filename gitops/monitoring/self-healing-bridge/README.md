# Self-Healing Bridge

Serviço que traduz webhooks do Alertmanager em eventos de `repository_dispatch` do GitHub, acionando o workflow de auto-remediation (`.github/workflows/self-healing.yaml`).

## Fluxo

```
Alert dispara (Prometheus) 
  ↓
Alertmanager captura
  ↓
Webhook → Self-Healing Bridge (porta 9095)
  ↓
Extrai service + alertname
  ↓
GitHub API: repository_dispatch event_type=manual-heal
  ↓
self-healing.yaml workflow executa
  ↓
kubectl rollout restart deployment/{service}
  ↓
Discord notification
```

## Pré-requisitos

### GitHub Token (Fine-Grained PAT)

**Recomendado: CI/CD via GitHub Actions** (automático)

Se deployando via GitHub Actions (`setup-full-workflow.yaml`):
1. Configure o GitHub Secret `PAT_TOKEN_SELF_HEALING` em:
   - Repository → Settings → Secrets and variables → Actions
   - Nome: `PAT_TOKEN_SELF_HEALING` (⚠️ não pode começar com `GITHUB_`)
   - Valor: seu fine-grained PAT (`ghp_...` com Actions: write)
2. O workflow cria o Kubernetes secret automaticamente

**Alternativa: Deploy Manual Local**

Se deployando localmente:
```bash
# Executar script interativo (oferece 3 opções de input)
./scripts/setup-self-healing-secret.sh

# Ou manual direto
kubectl create secret generic self-healing-bridge-secret \
  --from-literal=GITHUB_TOKEN='ghp_seu_token_aqui' \
  -n monitoring
```

**Criar o Fine-Grained PAT:**
1. Vá para https://github.com/settings/tokens?type=beta
2. Crie um novo token:
   - **Repository access**: TC5-ST
   - **Permissions**: Actions → write
3. Copie o token (formato: `ghp_xxx...`)

## Deploy

```bash
# Aplicar deployment + service + configmap
kubectl apply -f gitops/monitoring/self-healing-bridge/deployment.yaml

# Verificar status
kubectl get pods -n monitoring -l app=self-healing-bridge
kubectl logs -n monitoring -l app=self-healing-bridge -f
```

## Configuração do Alertmanager

No `gitops/monitoring/alerting/alertmanager-config.yaml`, adicione um webhook para o self-healing-bridge:

```yaml
receivers:
  - name: 'self-healing'
    webhook_configs:
      - url: 'http://self-healing-bridge:9095/'
        send_resolved: false
```

E configure uma rota que envie alertas críticos para o webhook:

```yaml
routes:
  - match:
      severity: critical
    receiver: 'self-healing'
```

## Serviços suportados

- `donation-service`
- `ngo-service`
- `volunteer-service`

## Teste manual

```bash
# Port-forward para testar
kubectl port-forward -n monitoring svc/self-healing-bridge 9095:9095 &

# Simular webhook do Alertmanager
curl -X POST http://localhost:9095/ \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [{
      "status": "firing",
      "labels": {
        "alertname": "HighErrorRate",
        "service": "donation-service"
      }
    }]
  }'

# Resposta esperada:
# {"triggered": [{"service": "donation-service", "alert": "HighErrorRate", "dispatched": true}]}
```

## Troubleshooting

### GITHUB_TOKEN não está configurado

```
[WARN] GITHUB_TOKEN not set, skipping donation-service
```

→ Verifique se o secret `self-healing-bridge-secret` existe e tem a chave `GITHUB_TOKEN`

### GitHub 401 Unauthorized

```
[ERR] GitHub 401 for donation-service: ...
```

→ Token inválido ou expirado. Gere um novo token e atualize o secret:
```bash
kubectl patch secret self-healing-bridge-secret -n monitoring \
  -p='{"stringData":{"GITHUB_TOKEN":"ghp_novo_token"}}'
```

### GitHub 403 Forbidden

```
[ERR] GitHub 403 for donation-service: ...
```

→ Token não tem permissão "Actions: write". Verifique permissões do token no GitHub.

### Nenhum serviço encontrado no alert

```
[WARN] no service for HighErrorRate labels={...}
```

→ O webhook do Alertmanager não está enviando o label `service`, `service_name`, ou `pod` com o nome do serviço.

## Ver logs

```bash
# Stream de logs em tempo real
kubectl logs -n monitoring -l app=self-healing-bridge -f

# Últimos 100 linhas
kubectl logs -n monitoring -l app=self-healing-bridge --tail=100

# Log de um pod específico
kubectl logs -n monitoring <pod-name> -f
```

## Limpeza

```bash
kubectl delete -f gitops/monitoring/self-healing-bridge/deployment.yaml
kubectl delete secret self-healing-bridge-secret -n monitoring
```
